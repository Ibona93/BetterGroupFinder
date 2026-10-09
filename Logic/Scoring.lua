local _, ns = ...

--[[
Rating logic. Pure Lua, no WoW API calls, so it can be tested outside the game.

Two sides are compared:
  host  = the group that is being filled (the listing's group when you are solo,
          your own group when you are in one; for two groups the larger one)
  guest = whoever would join (you, a player, or a second group)

A member is { class = "MAGE", level = 22, role = "DAMAGER"|"TANK"|"HEALER"|nil,
              lfgRoles = { tank = bool, healer = bool, dps = bool } | nil, isSelf = bool }

Result: { score, excluded, soft, reasons = { {kind, key, args...} }, verdict }
  kind: "plus", "minus", "note", "info", "exclude"
  key:  locale key (R_...), formatted by the UI.
]]

local S = {}
ns.Scoring = S

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
local ROLE_PRIORITY = { HEALER = 3, TANK = 2, DAMAGER = 1 }

S.POINTS = {
	-- Tanks and healers are scarce: filling their slot counts double.
	roleGap = { TANK = 40, HEALER = 40, DAMAGER = 20 },
	complete = 10,
	merge = 5,
	dupClass = 10,
	noNew = 5,
	roleOver = 8,
	levelRange = 8,
	otherBase = 10,
	verdictGood = 40,
	verdictOk = 15,
}

local function addReason(result, kind, key, ...)
	result.reasons[#result.reasons + 1] = { kind, key, ... }
end

local function exclude(result, key, ...)
	if not result.excluded then
		result.excluded = true
		result.excludeReason = { "exclude", key, ... }
	end
	addReason(result, "exclude", key, ...)
end

-- Ability coverage of one member: { [abilityId] = "sure" | "possible" }
function S.MemberAbilities(member, selfKnown)
	local out = {}
	local list = member and member.class and ns.CLASS_ABILITIES[member.class]
	if not list then return out end
	for _, entry in ipairs(list) do
		local state
		local known = nil
		if member.isSelf and selfKnown then known = selfKnown(entry) end
		if known == true then
			state = "sure"
		elseif known == false then
			state = nil
		elseif member.level == nil then
			state = "possible"
		elseif member.level >= entry.level then
			state = entry.possible and "possible" or "sure"
		end
		if state and out[entry.a] ~= "sure" then
			out[entry.a] = state
		end
	end
	return out
end

function S.Coverage(members, selfKnown)
	local cov, classes = {}, {}
	for _, m in ipairs(members) do
		for id, state in pairs(S.MemberAbilities(m, selfKnown)) do
			if cov[id] ~= "sure" then cov[id] = state end
		end
		if m.class then classes[m.class] = (classes[m.class] or 0) + 1 end
	end
	return cov, classes
end

local function roleOptions(member)
	if member.role == "TANK" or member.role == "HEALER" or member.role == "DAMAGER" then
		return { member.role }, false
	end
	local r = member.lfgRoles
	if r and (r.tank or r.healer or r.dps) then
		local opts = {}
		if r.tank then opts[#opts + 1] = "TANK" end
		if r.healer then opts[#opts + 1] = "HEALER" end
		if r.dps then opts[#opts + 1] = "DAMAGER" end
		return opts, false
	end
	return { "DAMAGER" }, true -- unknown role, counted as damage
end

local function gap(counts, targets, role)
	if not targets then return 0 end
	return (targets[role] or 0) - (counts[role] or 0)
end

-- Picks the role from `opts`: an open healer/tank slot first (scarce roles), then an open
-- damage slot; without any open slot the role with the smallest overflow.
local function pickRole(opts, counts, targets)
	local best, bestGap, bestPrio
	for _, role in ipairs(opts) do
		local g = gap(counts, targets, role)
		local prio = ROLE_PRIORITY[role]
		local better
		if not best then
			better = true
		elseif (g > 0) ~= (bestGap > 0) then
			better = g > 0
		elseif g > 0 then
			better = prio > bestPrio or (prio == bestPrio and g > bestGap)
		else
			better = g > bestGap or (g == bestGap and prio > bestPrio)
		end
		if better then best, bestGap, bestPrio = role, g, prio end
	end
	return best, bestGap
end

-- Assigns roles to a list of members (fixed roles first), updating `counts`.
local function assignRoles(members, counts, targets, allowed, result)
	local fixed, flexible = {}, {}
	local assigned = {}
	for i, m in ipairs(members) do
		local opts, unknown = roleOptions(m)
		if unknown and result then
			result.unknownRole = true
		end
		if allowed then
			local filtered = {}
			for _, role in ipairs(opts) do
				if allowed[role] then filtered[#filtered + 1] = role end
			end
			if #filtered == 0 then
				return nil, opts[1]
			end
			opts = filtered
		end
		if #opts == 1 then fixed[#fixed + 1] = { i, opts } else flexible[#flexible + 1] = { i, opts } end
	end
	local gains = {}
	local function place(entry)
		local role, g = pickRole(entry[2], counts, targets)
		assigned[entry[1]] = role
		if g > 0 then gains[#gains + 1] = role end
		counts[role] = (counts[role] or 0) + 1
	end
	for _, e in ipairs(fixed) do place(e) end
	for _, e in ipairs(flexible) do place(e) end
	return assigned, nil, gains
end

local function missingRoles(counts, targets)
	local out = {}
	if not targets then return out end
	for _, role in ipairs(ROLE_ORDER) do
		if gap(counts, targets, role) > 0 then out[#out + 1] = role end
	end
	return out
end

--[[
ctx = {
  host, guest            -- member lists
  selfIsGuest            -- wording: "slot free" vs "fills the missing"
  guestIsGroup           -- merging two groups
  maxPlayers             -- activity size
  profileKey             -- "dungeon" | "raid" | "other"
  roleTargets, strictRoles
  states                 -- { [abilityId] = "need"|"pref"|"ignore" }
  hints                  -- { abilityId, ... } from the instance, or nil
  allowedGuestRoles      -- { TANK = true, ... } or nil (filter chips)
  activity               -- { minLevel, minSuggest, maxSuggest } or nil
  selfKnown              -- function(entry) -> true/false/nil (own spellbook)
}
]]
function S.Evaluate(ctx)
	local result = { score = 0, excluded = false, soft = false, reasons = {}, guestRoles = {} }
	local host, guest = ctx.host or {}, ctx.guest or {}
	local P = S.POINTS
	local isRaid = ctx.profileKey == "raid"
	local maxPlayers = ctx.maxPlayers or 5
	local total = #host + #guest

	-- 1. Size
	if total > maxPlayers then
		exclude(result, "R_TOO_BIG", total, maxPlayers)
	end

	-- 2. Data completeness
	for _, m in ipairs(host) do
		if not m.class then addReason(result, "note", "R_DATA_MISSING") break end
	end
	for _, m in ipairs(guest) do
		if not m.class then addReason(result, "note", "R_DATA_MISSING") break end
	end

	-- 3. Roles
	local targets = ctx.roleTargets
	local counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
	assignRoles(host, counts, targets, nil, result)
	local hostMissingBefore = missingRoles(counts, targets)
	local assigned, notWanted, gains = assignRoles(guest, counts, targets, ctx.allowedGuestRoles, result)
	if not assigned then
		exclude(result, "R_ROLE_NOT_WANTED", notWanted)
		gains = {}
	else
		result.guestRoles = assigned
	end

	if targets and assigned then
		for _, role in ipairs(gains) do
			result.score = result.score + (P.roleGap[role] or 20)
			addReason(result, "plus", ctx.selfIsGuest and "R_SLOT_FREE" or "R_FILLS_ROLE", role)
		end
		for _, role in ipairs(ROLE_ORDER) do
			if gap(counts, targets, role) < 0 then
				if ctx.strictRoles then
					local stillNeeded = missingRoles(counts, targets)
					if #stillNeeded > 0 then
						exclude(result, "R_ROLE_FULL_NEED", role, stillNeeded[1])
					else
						exclude(result, "R_ROLE_FULL", role)
					end
				else
					result.score = result.score - P.roleOver
					addReason(result, "minus", "R_ROLE_OVER", role)
				end
			end
		end
	end
	if result.unknownRole then addReason(result, "note", "R_ROLE_UNKNOWN") end

	-- 4. Abilities
	local hostCov, hostClasses = S.Coverage(host, ctx.selfKnown)
	local guestCov = S.Coverage(guest, ctx.selfKnown)
	local hinted = {}
	if ctx.hints then
		for _, id in ipairs(ctx.hints) do hinted[id] = true end
	end
	local abilityGain = 0
	for _, ability in ipairs(ns.ABILITIES) do
		local id = ability.id
		local state = ctx.states and ctx.states[id] or "ignore"
		if state == "ignore" and hinted[id] then state = "pref" end
		if state ~= "ignore" then
			local w = ability.weight * (state == "need" and 1.5 or 1) * (hinted[id] and 1.5 or 1)
			local h, g = hostCov[id], guestCov[id]
			if h ~= "sure" and g then
				local gain
				if g == "sure" then
					gain = (h == "possible") and w / 2 or w
					addReason(result, "plus", "R_BRINGS", id)
				elseif not h then
					gain = w / 2
					addReason(result, "plus", "R_BRINGS_MAYBE", id)
				end
				if gain then
					abilityGain = abilityGain + gain
					result.score = result.score + gain
				end
			end
			local combined = (h == "sure" or g == "sure") and "sure" or (h or g)
			if not combined then
				if state == "need" then
					if total < maxPlayers then
						result.score = result.score - w / 2
						addReason(result, "note", "R_STILL_MISSING", id)
					else
						exclude(result, "R_REQUIRED_MISSING", id)
					end
				else
					addReason(result, "note", "R_STILL_MISSING", id)
				end
			end
		end
	end

	-- 5. Duplicates without new value
	local filledRole = gains and #gains > 0
	if #guest == 1 and not filledRole and abilityGain <= 0 then
		local cls = guest[1].class
		if cls and hostClasses[cls] then
			result.score = result.score - (isRaid and P.dupClass / 2 or P.dupClass)
			addReason(result, "minus", "R_DUP_CLASS", cls)
		else
			result.score = result.score - (isRaid and P.noNew / 2 or P.noNew)
			addReason(result, "minus", "R_NO_NEW")
		end
	end

	-- 6. Completion and merging
	if not result.excluded then
		if ctx.guestIsGroup then
			result.score = result.score + P.merge
			addReason(result, "info", "R_MERGE", total, maxPlayers)
		end
		if targets and total == maxPlayers and #missingRoles(counts, targets) == 0 then
			result.score = result.score + P.complete
			addReason(result, "plus", "R_COMPLETE")
		end
	end

	-- 7. Levels of the joining side
	local act = ctx.activity
	if act then
		for _, m in ipairs(guest) do
			if m.level then
				if act.minLevel and act.minLevel > 0 and m.level < act.minLevel then
					exclude(result, "R_LEVEL_LOW", m.level, act.minLevel)
				elseif act.minSuggest and act.maxSuggest and act.maxSuggest > 0
					and (m.level < act.minSuggest or m.level > act.maxSuggest) then
					result.score = result.score - P.levelRange
					addReason(result, "minus", "R_LEVEL_RANGE", m.level, act.minSuggest, act.maxSuggest)
				end
			end
		end
	end

	-- 8. Profiles without role targets (quests, custom): free space is enough
	if not targets and not result.excluded then
		result.score = result.score + P.otherBase
	end

	-- 9. No benefit -> sorted out, with reason
	if not result.excluded and result.score <= 0 then
		result.excluded = true
		result.soft = true
		result.excludeReason = { "exclude", "R_NO_VALUE" }
		table.insert(result.reasons, 1, { "exclude", "R_NO_VALUE" })
	end

	result.score = math.floor(result.score + 0.5)
	if result.score >= P.verdictGood then
		result.verdict = "VERDICT_GOOD"
	elseif result.score >= P.verdictOk then
		result.verdict = "VERDICT_OK"
	else
		result.verdict = "VERDICT_LOW"
	end
	result.hostMissingBefore = hostMissingBefore
	return result
end

--[[
Group value: how well a group is set up right now, 0-100 %.
  60 % roles: occupied planned slots, tanks and healers count double
  40 % abilities: preferred/required abilities already covered, weighted like the points
       (x1.5 required, x1.5 instance hint, "possible" counts half)
Without role targets (quests, custom) there is no group value.
ctx = { roleTargets, states, hints, selfKnown }
Returns { percent, rolesFilled, rolesTotal, abilitiesCovered, abilitiesTotal } or nil.
]]
local ROLE_VALUE = { TANK = 2, HEALER = 2, DAMAGER = 1 }

function S.GroupValue(members, ctx)
	local targets = ctx.roleTargets
	if not targets or not members or #members == 0 then return nil end

	local counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
	assignRoles(members, counts, targets, nil, nil)
	local have, want, filled, total = 0, 0, 0, 0
	for _, role in ipairs(ROLE_ORDER) do
		local t = targets[role] or 0
		local c = math.min(counts[role] or 0, t)
		have = have + c * ROLE_VALUE[role]
		want = want + t * ROLE_VALUE[role]
		filled = filled + c
		total = total + t
	end
	local roleShare = want > 0 and have / want or 1

	local hinted = {}
	for _, id in ipairs(ctx.hints or {}) do hinted[id] = true end
	local cov = S.Coverage(members, ctx.selfKnown)
	local got, need, covered, considered = 0, 0, 0, 0
	for _, ability in ipairs(ns.ABILITIES) do
		local state = ctx.states and ctx.states[ability.id] or "ignore"
		if state == "ignore" and hinted[ability.id] then state = "pref" end
		if state ~= "ignore" then
			local w = ability.weight * (state == "need" and 1.5 or 1) * (hinted[ability.id] and 1.5 or 1)
			need = need + w
			considered = considered + 1
			local c = cov[ability.id]
			if c == "sure" then
				got = got + w
				covered = covered + 1
			elseif c == "possible" then
				got = got + w / 2
				covered = covered + 1
			end
		end
	end
	local percent
	if need > 0 then
		percent = 0.6 * roleShare + 0.4 * (got / need)
	else
		percent = roleShare
	end
	return {
		percent = math.floor(percent * 100 + 0.5),
		rolesFilled = filled, rolesTotal = total,
		abilitiesCovered = covered, abilitiesTotal = considered,
	}
end

-- Chooses host/guest for two sides. The larger side is the host; on a tie your side is.
function S.ChooseSides(mine, theirs)
	if #theirs > #mine then
		return theirs, mine, true
	end
	return mine, theirs, false
end
