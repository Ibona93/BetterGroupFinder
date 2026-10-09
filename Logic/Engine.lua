local _, ns = ...

--[[
Engine: reads the Group Finder data through the WoW API and feeds the pure rating logic.
Every API access is guarded: missing functions or locked (secret) values never raise.
]]

local E = {}
ns.Engine = E

-- C_LFGList is looked up on every call (never cached), so a missing API cannot break loading.

E.locked = false

-------------------------------------------------------------------------------
-- Own character and group
-------------------------------------------------------------------------------

function E.GetMyRoles()
	local roles = C_LFGListRoles and ns.TryCall(C_LFGListRoles.GetRoles)
	if type(roles) == "table" and (roles.tank or roles.healer or roles.dps) then
		return { tank = roles.tank, healer = roles.healer, dps = roles.dps }
	end
	return { dps = true }
end

local function unitRole(unit)
	local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
	if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
	return nil
end

local function unitMember(unit)
	if not UnitExists(unit) then return nil end
	local _, class = UnitClass(unit)
	local level = UnitLevel(unit)
	if level and level <= 0 then level = nil end
	return { class = class, level = level, role = unitRole(unit), name = UnitName(unit) }
end

function E.GetMySide()
	local me = unitMember("player") or {}
	me.isSelf = true
	me.lfgRoles = E.GetMyRoles()
	if not IsInGroup() then
		me.role = nil
	end
	local members = { me }
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local unit = "raid" .. i
			if not UnitIsUnit(unit, "player") then
				members[#members + 1] = unitMember(unit)
			end
		end
	elseif IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do
			members[#members + 1] = unitMember("party" .. i)
		end
	end
	return members
end

-------------------------------------------------------------------------------
-- Own spellbook check (only for your own character)
-------------------------------------------------------------------------------

local spellCheckReliable = nil

local function isKnown(spellID)
	if C_SpellBook and C_SpellBook.IsSpellKnown then
		local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
		if ok and known then return true end
	end
	if IsPlayerSpell then
		local ok, known = pcall(IsPlayerSpell, spellID)
		if ok and known then return true end
	end
	return false
end

-- The spell IDs come from WoW Classic. Only trust the spellbook check if at least one
-- baseline spell of your class that you should already have is reported as known.
local function checkReliable()
	if spellCheckReliable ~= nil then return spellCheckReliable end
	local _, class = UnitClass("player")
	local level = UnitLevel("player") or 0
	local list = ns.CLASS_ABILITIES[class] or {}
	local expected, found = 0, 0
	for _, entry in ipairs(list) do
		if entry.spells and not entry.possible and entry.level <= level then
			expected = expected + 1
			for _, id in ipairs(entry.spells) do
				if isKnown(id) then found = found + 1 break end
			end
		end
	end
	spellCheckReliable = expected > 0 and found > 0
	ns.Debug(("spellbook check: %d/%d known -> %s"):format(found, expected, tostring(spellCheckReliable)))
	return spellCheckReliable
end

function E.InvalidateSpellCheck()
	spellCheckReliable = nil
end

function E.SelfKnown(entry)
	if not entry.spells or not checkReliable() then return nil end
	for _, id in ipairs(entry.spells) do
		if isKnown(id) then return true end
	end
	return false
end

-------------------------------------------------------------------------------
-- Listings
-------------------------------------------------------------------------------

function E.IsLockedDown()
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
		local ok, locked = pcall(C_ChatInfo.InChatMessagingLockdown)
		if ok and locked then return true end
	end
	return false
end

-- Members of a listing, or nil plus "locked" when the data is secret.
function E.GetListingMembers(resultID, numMembers)
	if not C_LFGList or not C_LFGList.GetSearchResultPlayerInfo then return nil, "error" end
	local members = {}
	for i = 1, numMembers or 0 do
		local ok, info = pcall(C_LFGList.GetSearchResultPlayerInfo, resultID, i)
		if not ok then return nil, "error" end
		if info then
			if ns.IsSecret(info.classFilename) or ns.IsSecret(info.level) then
				return nil, "locked"
			end
			local member = {
				class = info.classFilename,
				level = info.level,
				name = info.name,
				isLeader = info.isLeader,
			}
			if numMembers == 1 then
				member.lfgRoles = info.lfgRoles
			else
				local role = info.assignedRole
				if role == "TANK" or role == "HEALER" or role == "DAMAGER" then member.role = role end
			end
			members[#members + 1] = member
		else
			members[#members + 1] = {}
		end
	end
	return members
end

local function selectedActivityFilter()
	local dropdown = LFGBrowseFrame and LFGBrowseFrame.ActivityDropdown
	if dropdown and dropdown.selectedValues and #dropdown.selectedValues > 0 then
		return dropdown
	end
	return nil
end

-- Picks the activity to rate a listing against.
function E.ChooseActivity(info)
	local ids = info.activityIDs or {}
	local active = C_LFGList and ns.TryCall(C_LFGList.GetActiveEntryInfo)
	if active and active.activityIDs then
		for _, id in ipairs(ids) do
			if tContains(active.activityIDs, id) then return id end
		end
	end
	local dropdown = selectedActivityFilter()
	if dropdown then
		for _, id in ipairs(ids) do
			local ok, selected = pcall(dropdown.ValueIsSelected, dropdown, id)
			if ok and selected then return id end
		end
	end
	return ids[1]
end

function E.GetActivityInfo(activityID)
	if not activityID or not C_LFGList then return nil end
	return ns.TryCall(C_LFGList.GetActivityInfoTable, activityID)
end

function E.ActivityName(activityInfo)
	if not activityInfo then return "" end
	if activityInfo.shortName and activityInfo.shortName ~= "" then return activityInfo.shortName end
	return activityInfo.fullName or ""
end

local DUNGEON_CATEGORY, RAID_CATEGORY = 2, 114

function E.ProfileFor(activityInfo)
	if not activityInfo then return "other", 5 end
	local maxPlayers = activityInfo.maxNumPlayers
	if not maxPlayers or maxPlayers <= 0 then maxPlayers = 40 end
	if activityInfo.categoryID == DUNGEON_CATEGORY or activityInfo.categoryID == RAID_CATEGORY then
		return (maxPlayers <= 5) and "dungeon" or "raid", maxPlayers
	end
	return "other", maxPlayers
end

local function matchesActivityFilter(info)
	local dropdown = selectedActivityFilter()
	if not dropdown then return true end
	for _, id in ipairs(info.activityIDs or {}) do
		local ok, selected = pcall(dropdown.ValueIsSelected, dropdown, id)
		if ok and selected then return true end
	end
	return false
end

-- Roles the filter chips allow for the joining side (nil = automatic).
function E.AllowedRoles()
	local chips = ns.db and ns.db.roleChips
	if not chips or next(chips) == nil then return nil end
	local allowed, any = {}, false
	for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
		if chips[role] then allowed[role] = true any = true end
	end
	return any and allowed or { NONE = true }
end

--[[
Evaluates one search result. Returns an entry table for the list:
{ resultID, info, members, isSolo, activityID, activityInfo, activityName,
  profileKey, maxPlayers, result (rating), own (own listing) }
]]
function E.EvaluateResult(resultID, mySide, noRating)
	if not C_LFGList or not C_LFGList.GetSearchResultInfo then return nil end
	local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
	if not ok or not info then return nil end

	local entry = {
		resultID = resultID,
		info = info,
		isSolo = (info.numMembers or 0) <= 1,
	}
	entry.activityID = E.ChooseActivity(info)
	entry.activityInfo = E.GetActivityInfo(entry.activityID)
	if #(info.activityIDs or {}) > 1 and not entry.activityInfo then
		entry.activityName = ""
	else
		entry.activityName = E.ActivityName(entry.activityInfo)
	end
	entry.numActivities = #(info.activityIDs or {})
	entry.profileKey, entry.maxPlayers = E.ProfileFor(entry.activityInfo)

	if info.hasSelf then
		entry.own = true
		return entry
	end

	local members, state = E.GetListingMembers(resultID, info.numMembers)
	entry.members = members
	if not members and state == "locked" then entry.locked = true end

	-- "BGF filter active" switched off: show everything, no rating
	if noRating then return entry end

	local result
	if info.isDelisted then
		result = { score = -100, excluded = true, reasons = {}, excludeReason = { "exclude", "R_DELISTED" } }
	elseif not matchesActivityFilter(info) then
		result = { score = -50, excluded = true, reasons = {}, excludeReason = { "exclude", "R_ACTIVITY_FILTER" } }
	elseif not members then
		entry.locked = (state == "locked")
		result = { score = 0, excluded = false, reasons = { { "note", "R_DATA_MISSING" } } }
	else
		local host, guest, swapped = ns.Scoring.ChooseSides(mySide, members)
		local targets, strict = ns.GetRoleTargets(entry.profileKey, entry.maxPlayers)
		local act = entry.activityInfo
		result = ns.Scoring.Evaluate({
			host = host,
			guest = guest,
			selfIsGuest = swapped,
			guestIsGroup = #mySide > 1 and #members > 1,
			maxPlayers = entry.maxPlayers,
			profileKey = entry.profileKey,
			roleTargets = targets,
			strictRoles = strict,
			states = ns.db.abilityStates[entry.profileKey],
			hints = act and ns.INSTANCE_HINTS[act.mapID],
			allowedGuestRoles = E.AllowedRoles(),
			activity = act and {
				minLevel = act.minLevel,
				minSuggest = act.minLevelSuggestion,
				maxSuggest = act.maxLevelSuggestion,
			},
			selfKnown = E.SelfKnown,
		})
		result.selfIsGuest = swapped
		if not entry.isSolo then
			entry.groupValue = ns.Scoring.GroupValue(members, {
				roleTargets = targets,
				states = ns.db.abilityStates[entry.profileKey],
				hints = act and ns.INSTANCE_HINTS[act.mapID],
			})
		end
		if swapped then
			entry.myRole = result.guestRoles and result.guestRoles[1]
		end
	end
	entry.result = result
	return entry
end

-- Builds the sections shown in the BGF list from Blizzard's (already sorted) results.
-- Without rating (filter switched off) nothing is sorted out and Blizzard's order is kept.
function E.BuildSections(resultIDs, rate)
	if rate == nil then rate = true end
	E.locked = E.IsLockedDown()
	local mySide = E.GetMySide()
	local sections = { own = {}, groups = {}, players = {}, excluded = {} }
	for _, id in ipairs(resultIDs or {}) do
		local entry = E.EvaluateResult(id, mySide, not rate)
		if entry then
			if entry.locked then E.locked = true end
			if entry.own then
				table.insert(sections.own, entry)
			elseif entry.result and entry.result.excluded then
				table.insert(sections.excluded, entry)
			elseif entry.isSolo then
				table.insert(sections.players, entry)
			else
				table.insert(sections.groups, entry)
			end
		end
	end
	local function byScore(a, b)
		local sa, sb = a.result and a.result.score or 0, b.result and b.result.score or 0
		if sa ~= sb then return sa > sb end
		return a.resultID < b.resultID
	end
	if rate then
		table.sort(sections.groups, byScore)
		table.sort(sections.players, byScore)
		table.sort(sections.excluded, byScore)
	end
	sections.rated = rate
	sections.total = #(resultIDs or {})
	sections.mySide = mySide
	return sections
end

-- Prints raw data of a result (for /bgf debug).
function E.DumpResult(resultID)
	if not C_LFGList then return end
	local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
	if not ok or not info then ns.Print("result " .. tostring(resultID) .. ": no info") return end
	local activityInfo = E.GetActivityInfo(E.ChooseActivity(info))
	ns.Print(("result %d: leader=%s members=%d activity=%s mapID=%s max=%s cat=%s"):format(
		resultID, tostring(info.leaderName), info.numMembers or -1,
		activityInfo and activityInfo.fullName or "?", activityInfo and tostring(activityInfo.mapID) or "?",
		activityInfo and tostring(activityInfo.maxNumPlayers) or "?", activityInfo and tostring(activityInfo.categoryID) or "?"))
	for i = 1, info.numMembers or 0 do
		local okP, p = pcall(C_LFGList.GetSearchResultPlayerInfo, resultID, i)
		if okP and p then
			ns.Print(("  %d: %s %s lvl %s role %s spec %s"):format(i, tostring(p.name), tostring(p.classFilename),
				tostring(p.level), tostring(p.assignedRole), tostring(p.specName)))
		end
	end
end
