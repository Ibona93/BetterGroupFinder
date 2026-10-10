--[[
Offline tests for Better Group Finder (Lua 5.1). Run from the addon folder:
    lua tests/run.lua
Loads the data, locale and logic files with a private namespace exactly like the game does
(`local ADDON, ns = ...`) and mocks only the WoW API that the tested code touches.
]]

local ns = {}
local function load(path)
	local chunk = assert(loadfile(path))
	chunk("BetterGroupFinder", ns)
end

-- Minimal WoW stubs needed while loading.
_G.unpack = _G.unpack or table.unpack
_G.GetLocale = function() return "deDE" end
_G.C_Timer = { After = function(_, fn) fn() end }
_G.CreateFrame = function()
	return { SetScript = function() end, RegisterEvent = function() end }
end
_G.SlashCmdList = {}
_G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end

load("Init.lua")
for _, lang in ipairs({ "enUS", "deDE", "frFR", "esES", "ptBR", "itIT", "ruRU", "koKR", "zhCN", "zhTW" }) do
	load("Locales/" .. lang .. ".lua")
end
load("Data/Abilities.lua")
load("Data/Profiles.lua")
load("Data/Abbreviations.lua")
load("Data/Instances.lua")
load("Logic/Scoring.lua")
load("Logic/Engine.lua")
load("Core.lua")
ns.db = ns.MergeDefaults({}, ns.DEFAULTS)

local S = ns.Scoring
local passed, failed = 0, 0

local function check(name, cond, detail)
	if cond then
		passed = passed + 1
		print("  ok   " .. name)
	else
		failed = failed + 1
		print("  FAIL " .. name .. (detail and ("  -> " .. detail) or ""))
	end
end

local function hasReason(result, key, arg)
	for _, r in ipairs(result.reasons) do
		if r[2] == key and (arg == nil or r[3] == arg) then return true end
	end
	return false
end

local function reasonsText(result)
	local t = {}
	for _, r in ipairs(result.reasons) do t[#t + 1] = r[2] .. (r[3] and ("(" .. tostring(r[3]) .. ")") or "") end
	return ("score=%s excluded=%s [%s]"):format(result.score, tostring(result.excluded), table.concat(t, ", "))
end

local function M(class, level, role, lfg)
	return { class = class, level = level, role = role, lfgRoles = lfg }
end

local function dungeonCtx(host, guest, extra)
	local targets, strict = ns.GetRoleTargets("dungeon", 5)
	local ctx = {
		host = host, guest = guest, selfIsGuest = true, maxPlayers = 5, profileKey = "dungeon",
		roleTargets = targets, strictRoles = strict, states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.dungeon),
		activity = { minLevel = 15, minSuggest = 15, maxSuggest = 24 },
	}
	for k, v in pairs(extra or {}) do ctx[k] = v end
	return ctx
end

print("Scenario tests (Bewertungslogik)")

-- 1. Group needs a tank; a tank candidate is rated high, a DPS is sorted out.
do
	local host = { M("PRIEST", 20, "HEALER"), M("MAGE", 20, "DAMAGER"), M("ROGUE", 20, "DAMAGER"), M("HUNTER", 20, "DAMAGER") }
	local tank = S.Evaluate(dungeonCtx(host, { M("WARRIOR", 21, nil, { tank = true }) }))
	local dps = S.Evaluate(dungeonCtx(host, { M("WARLOCK", 21, nil, { dps = true }) }))
	check("1a tank fills missing tank", not tank.excluded and hasReason(tank, "R_SLOT_FREE", "TANK") and tank.score >= 30, reasonsText(tank))
	check("1b dps is sorted out (no slot, still needs tank)", dps.excluded and hasReason(dps, "R_ROLE_FULL_NEED", "DAMAGER"), reasonsText(dps))
end

-- 2. Group needs a healer; a healer outranks another DPS.
do
	local host = { M("WARRIOR", 22, "TANK"), M("MAGE", 22, "DAMAGER") }
	local healer = S.Evaluate(dungeonCtx(host, { M("PRIEST", 22, nil, { healer = true }) }))
	local dps = S.Evaluate(dungeonCtx(host, { M("ROGUE", 22, nil, { dps = true }) }))
	check("2a healer fills the healer slot", hasReason(healer, "R_SLOT_FREE", "HEALER"), reasonsText(healer))
	check("2b healer ranks above a DPS", healer.score > dps.score, ("%d vs %d"):format(healer.score, dps.score))
end

-- 3. Group already has an ability: a second provider gets no points for it.
do
	local host = { M("WARRIOR", 22, "TANK"), M("PRIEST", 22, "HEALER"), M("MAGE", 22, "DAMAGER") }
	local states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.dungeon)
	states.curse = "pref"
	local r = S.Evaluate(dungeonCtx(host, { M("MAGE", 22, nil, { dps = true }) }, { states = states }))
	check("3 existing curse removal is not counted again", not hasReason(r, "R_BRINGS", "curse"), reasonsText(r))
end

-- 4. Group profits from a missing ability (interrupt): a rogue gets points for it.
do
	local host = { M("WARRIOR", 10, "TANK"), M("PRIEST", 10, "HEALER") }
	local states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.dungeon)
	local rogue = S.Evaluate(dungeonCtx(host, { M("ROGUE", 22, nil, { dps = true }) }, { states = states }))
	local hunter = S.Evaluate(dungeonCtx(host, { M("HUNTER", 22, nil, { dps = true }) }, { states = states }))
	check("4a rogue brings interrupt and crowd control", hasReason(rogue, "R_BRINGS", "interrupt") and hasReason(rogue, "R_BRINGS", "cc"), reasonsText(rogue))
	check("4b rogue rated higher than a hunter here", rogue.score > hunter.score, ("%d vs %d"):format(rogue.score, hunter.score))
end

-- 5. Same class without added value: second mage in a full-DPS-utility group.
do
	local host = { M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER"), M("MAGE", 30, "DAMAGER"), M("ROGUE", 30, "DAMAGER") }
	-- host as guest perspective: the host (your group) evaluates a mage applicant; DPS slot open
	local ctx = dungeonCtx(host, { M("MAGE", 30, nil, { dps = true }) }, { selfIsGuest = false })
	local mage = S.Evaluate(ctx)
	local hunter = S.Evaluate(dungeonCtx(host, { M("HUNTER", 30, nil, { dps = true }) }, { selfIsGuest = false }))
	check("5a second mage still fills the last DPS slot (not useless)", not mage.excluded, reasonsText(mage))
	-- raid-sized check without free role: no gap, no ability -> marked as duplicate
	local full = { M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER"), M("MAGE", 30, "DAMAGER"), M("ROGUE", 30, "DAMAGER"), M("HUNTER", 30, "DAMAGER") }
	local targets = ns.GetRoleTargets("raid", 10)
	local rctx = {
		host = full, guest = { M("MAGE", 30, nil, { dps = true }) }, maxPlayers = 10, profileKey = "raid",
		roleTargets = { TANK = 1, HEALER = 1, DAMAGER = 3 }, strictRoles = false,
		states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.raid),
	}
	local dup = S.Evaluate(rctx)
	check("5b mage without new utility is marked as duplicate", hasReason(dup, "R_DUP_CLASS", "MAGE"), reasonsText(dup))
	check("5c ... and sorted out as no real benefit", dup.excluded and dup.soft, reasonsText(dup))
	check("5d hunter in the dungeon case gets a comparable rating", mage.score > 0 and hunter.score > 0, ("%d / %d"):format(mage.score, hunter.score))
	check("5e raid targets exist for size 10", targets and targets.TANK == 2 and targets.HEALER == 3, "")
end

-- 6. Same class but a different role adds value: druid tank where a druid DPS is present.
do
	local host = { M("DRUID", 25, "DAMAGER"), M("PRIEST", 25, "HEALER") }
	local druidTank = S.Evaluate(dungeonCtx(host, { M("DRUID", 25, nil, { tank = true, dps = true }) }))
	check("6 druid as tank is valued although a druid is present", not druidTank.excluded and hasReason(druidTank, "R_SLOT_FREE", "TANK") and not hasReason(druidTank, "R_DUP_CLASS"), reasonsText(druidTank))
end

-- 7. Two groups complement each other (merge).
do
	local mine = { M("WARRIOR", 22, "TANK"), M("MAGE", 22, "DAMAGER") }
	local theirs = { M("PRIEST", 22, "HEALER"), M("ROGUE", 22, "DAMAGER") }
	local host, guest, swapped = S.ChooseSides(mine, theirs)
	local r = S.Evaluate(dungeonCtx(host, guest, { guestIsGroup = true, selfIsGuest = swapped }))
	check("7a merge of 2+2 is possible", not r.excluded and hasReason(r, "R_MERGE"), reasonsText(r))
	local big = { M("WARRIOR", 22, "TANK"), M("MAGE", 22, "DAMAGER"), M("ROGUE", 22, "DAMAGER") }
	local r2 = S.Evaluate(dungeonCtx(big, theirs, { guestIsGroup = true }))
	check("7b merge of 3+2 completes the group", not r2.excluded and hasReason(r2, "R_COMPLETE"), reasonsText(r2))
	local r3 = S.Evaluate(dungeonCtx(big, { M("PRIEST", 22, "HEALER"), M("ROGUE", 22, "DAMAGER"), M("MAGE", 22, "DAMAGER") }, { guestIsGroup = true }))
	check("7c merge of 3+3 is too big", r3.excluded and hasReason(r3, "R_TOO_BIG"), reasonsText(r3))
end

-- Required abilities and level checks
do
	local host = { M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER"), M("ROGUE", 30, "DAMAGER"), M("HUNTER", 30, "DAMAGER") }
	local states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.dungeon)
	states.curse = "need"
	local warrior = S.Evaluate(dungeonCtx(host, { M("WARRIOR", 30, nil, { dps = true }) }, { states = states }))
	local mage = S.Evaluate(dungeonCtx(host, { M("MAGE", 30, nil, { dps = true }) }, { states = states }))
	check("R1 required ability missing in the last slot -> sorted out", warrior.excluded and hasReason(warrior, "R_REQUIRED_MISSING", "curse"), reasonsText(warrior))
	check("R2 mage brings the required ability", not mage.excluded and hasReason(mage, "R_BRINGS", "curse"), reasonsText(mage))
	local low = S.Evaluate(dungeonCtx({ M("WARRIOR", 20, "TANK") }, { M("MAGE", 12, nil, { dps = true }) }))
	check("R3 below minimum level -> sorted out", low.excluded and hasReason(low, "R_LEVEL_LOW"), reasonsText(low))
	local notWanted = S.Evaluate(dungeonCtx({ M("WARRIOR", 20, "TANK") }, { M("MAGE", 20, nil, { dps = true }) }, { allowedGuestRoles = { HEALER = true } }))
	check("R4 role not looked for -> sorted out", notWanted.excluded and hasReason(notWanted, "R_ROLE_NOT_WANTED"), reasonsText(notWanted))
	local hint = S.Evaluate(dungeonCtx({ M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER") }, { M("MAGE", 30, nil, { dps = true }) }, { hints = { "curse" } }))
	check("R5 instance hint promotes an ignored ability", hasReason(hint, "R_BRINGS", "curse"), reasonsText(hint))
end

-- 12. Incomplete data never raises.
do
	local ok, r = pcall(S.Evaluate, dungeonCtx({ {}, M("PRIEST", nil, "HEALER") }, { {} }))
	check("12a members without class/level are handled", ok and r and hasReason(r, "R_DATA_MISSING"), ok and reasonsText(r) or tostring(r))
	local ok2 = pcall(S.Evaluate, { host = {}, guest = {} })
	check("12b empty context is handled", ok2)
	local ok3 = pcall(S.Evaluate, dungeonCtx({ M("UNKNOWNCLASS", 20, "TANK") }, { M("MAGE", 20) }))
	check("12c unknown class and missing role are handled", ok3)
end

-- 12d. Engine with missing / failing API functions.
do
	_G.C_LFGList = {
		GetSearchResultInfo = function() error("API missing") end,
		GetSearchResultPlayerInfo = function() return nil end,
	}
	local ok, entry = pcall(ns.Engine.EvaluateResult, 1, { M("MAGE", 20) })
	check("12d failing GetSearchResultInfo returns nil without error", ok and entry == nil, tostring(entry))
	_G.issecretvalue = function() return true end
	_G.C_LFGList.GetSearchResultPlayerInfo = function() return { classFilename = "MAGE", level = 20 } end
	local members, state = ns.Engine.GetListingMembers(1, 2)
	check("12e secret member data is reported as locked", members == nil and state == "locked", tostring(state))
	_G.issecretvalue = nil
	_G.C_LFGList = nil
	local ok4, e4 = pcall(ns.Engine.EvaluateResult, 1, { M("MAGE", 20) })
	local ok5 = pcall(ns.Engine.GetListingMembers, 1, 2)
	check("12f whole C_LFGList API missing is handled", ok4 and e4 == nil and ok5)
end

print("Group value and combined filters (0.4.0)")
do
	local targets = ns.GetRoleTargets("dungeon", 5)
	local states = ns.DEFAULT_ABILITY_STATES.dungeon
	local full = S.GroupValue({ M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER"), M("MAGE", 30, "DAMAGER"),
		M("ROGUE", 30, "DAMAGER"), M("WARLOCK", 30, "DAMAGER") }, { roleTargets = targets, states = states })
	check("13a complete dungeon group with cc/interrupt/summon = 100 %", full and full.percent == 100
		and full.rolesFilled == 5 and full.rolesTotal == 5, full and full.percent)
	local tank = S.GroupValue({ M("WARRIOR", 30, "TANK") }, { roleTargets = targets, states = states })
	local dps = S.GroupValue({ M("WARRIOR", 30, "DAMAGER") }, { roleTargets = targets, states = states })
	check("13b the same warrior counts more as tank than as damage dealer", tank and dps and tank.percent > dps.percent,
		(tank and tank.percent or "?") .. " vs " .. (dps and dps.percent or "?"))
	check("13c abilities counted as covered/considered (warrior 30: shield bash + talent possible)",
		tank.abilitiesTotal == 2 and tank.abilitiesCovered == 2, tank.abilitiesCovered .. "/" .. tank.abilitiesTotal)
	check("13d no role targets (quests) -> no group value", S.GroupValue({ M("MAGE", 30) }, { states = states }) == nil)
	check("13e class chips: the member's class is always covered", S.Coverage({ M("DRUID", 5) }).class_DRUID == "sure"
		and S.Coverage({ M("DRUID", 5) }).class_MAGE == nil)
	check("13f 0.7.0 chips: 9 classes, 9 buffs, 4 dispels, 5 combat", #ns.ABILITIES == 27 and ns.ABILITY_BY_ID.healthstone
		and ns.ABILITY_BY_ID.summon and ns.ABILITY_BY_ID.buff_fearward and ns.ABILITY_BY_ID.healthstone.category == "combat", #ns.ABILITIES)
	check("13g all class chips start as 'ignore'", ns.DEFAULT_ABILITY_STATES.dungeon.class_WARLOCK == "ignore"
		and ns.DEFAULT_ABILITY_STATES.raid.class_PRIEST == "ignore" and ns.DEFAULT_ABILITY_STATES.dungeon.summon == "ignore")
	local old = { dungeon = { buff = "pref", utility = "need", cc = "need", class_DRUID = "pref" } }
	ns.CleanAbilityStates(old)
	check("13h settings of unknown chips are dropped", old.dungeon.buff == nil and old.dungeon.utility == nil
		and old.dungeon.cc == "need" and old.dungeon.class_DRUID == "pref")
	local hinted = false
	for _, list in pairs(ns.INSTANCE_HINTS) do for _, id in ipairs(list) do
		if not ns.ABILITY_BY_ID[id] then hinted = id end
	end end
	check("13i instance hints only use existing abilities", hinted == false, tostring(hinted))
	check("13j mana: paladin from 14, shaman talent from 25 (possible), totem from 26", S.Coverage({ M("PALADIN", 13) }).buff_mana == nil
		and S.Coverage({ M("PALADIN", 14) }).buff_mana == "sure" and S.Coverage({ M("SHAMAN", 24) }).buff_mana == nil
		and S.Coverage({ M("SHAMAN", 25) }).buff_mana == "possible" and S.Coverage({ M("SHAMAN", 26) }).buff_mana == "sure")
	local missing = false
	for class, list in pairs(ns.CLASS_ABILITIES) do
		for _, e in ipairs(list) do
			local known = ns.ABILITY_BY_ID[e.a] or e.a == "buff" or e.a == "utility"
			local conds = type(e.cond) == "table" and e.cond or { e.cond }
			for _, c in ipairs(conds) do
				if not ns.Locales.enUS["COND_" .. c] then known = false end
			end
			if not ns.SPELLS[e.sp] or not known then missing = class .. " " .. tostring(e.sp) end
		end
	end
	check("13k every class entry has a tooltip spell, a known ability and a condition text", missing == false, tostring(missing))
	local badFx = false
	for _, list in pairs(ns.CLASS_ABILITIES) do
		for _, e in ipairs(list) do
			if type(e.spells) == "table" then for k in pairs(e.spells) do if type(k) ~= "number" then badFx = e.sp end end end
			if e.fx and not ns.Locales.enUS["FX_" .. e.fx] then badFx = e.sp end
			if ns.ABILITY_BY_ID[e.a] and ns.ABILITY_BY_ID[e.a].category == "buff" and not e.fx then badFx = e.sp end
		end
	end
	check("13m every buff has an effect text, spell lists are clean", badFx == false, tostring(badFx))
	check("13l spell names fall back to the client language without game data", ns.SpellName("fear_ward") == "Furchtzauberschutz")
end

print("Class chips, talents and stricter 'required' (0.6.0)")
do
	local host = { M("WARRIOR", 30, "TANK"), M("PRIEST", 30, "HEALER") }
	local ctx = dungeonCtx(host, { M("DRUID", 30, "DAMAGER") }, { activity = { minLevel = 25, minSuggest = 25, maxSuggest = 35 } })
	local base = S.Evaluate(ctx)
	ctx = dungeonCtx(host, { M("DRUID", 30, "DAMAGER") }, { activity = { minLevel = 25, minSuggest = 25, maxSuggest = 35 } })
	ctx.states.class_DRUID = "pref"
	local pref = S.Evaluate(ctx)
	check("14a class chip 'preferred' adds its weight", pref.score - base.score == ns.CLASS_WEIGHT and hasReason(pref, "R_BRINGS", "class_DRUID"),
		("%s -> %s"):format(base.score, pref.score))
	ctx = dungeonCtx(host, { M("MAGE", 30, "DAMAGER") }, { activity = { minLevel = 25, minSuggest = 25, maxSuggest = 35 } })
	ctx.states.class_DRUID = "need"
	local noDruid = S.Evaluate(ctx)
	check("14b class chip 'required' missing -> still missing note with free slots", hasReason(noDruid, "R_STILL_MISSING", "class_DRUID")
		and not noDruid.excluded, reasonsText(noDruid))
	-- Talent: a level 30 priest may bring Silence; another player only "possible" with the talent named.
	local lone = { M("WARRIOR", 11, "TANK"), M("HUNTER", 30, "DAMAGER"), M("HUNTER", 30, "DAMAGER"), M("HUNTER", 30, "DAMAGER") }
	ctx = dungeonCtx(lone, { M("PRIEST", 30, "HEALER") }, { activity = { minLevel = 25, minSuggest = 25, maxSuggest = 35 } })
	ctx.states.interrupt = "need"
	ctx.states.cc = "ignore"
	local priest = S.Evaluate(ctx)
	local maybe
	for _, r in ipairs(priest.reasons) do if r[2] == "R_BRINGS_MAYBE" and r[3] == "interrupt" then maybe = r[4] end end
	check("14c talent abilities count as 'possible' with the condition as reason", maybe == "cond:TALENT", tostring(maybe))
	check("14d 'required' is not met by 'possible' only: last slot -> sorted out", priest.excluded
		and hasReason(priest, "R_REQUIRED_MISSING", "interrupt"), reasonsText(priest))
	check("14e reason text names the real condition", ns.FormatReason({ "plus", "R_BRINGS_MAYBE", "interrupt", "cond:TALENT" })
		== "+ bringt evtl. Unterbrechen (Talent)", ns.FormatReason({ "plus", "R_BRINGS_MAYBE", "interrupt", "cond:TALENT" }))
	check("14f several conditions are joined", ns.ConditionText({ cond = { "TALENT", "HUMANOID" } }) == "Talent, nur Humanoide")
	-- Own character: a learned talent is sure, a shield-dependent ability stays possible.
	local me = M("WARRIOR", 38, "TANK")
	me.isSelf = true
	local cov = S.Coverage({ me }, function() return true end)
	check("14g own learned talent counts as sure", cov.cc == "sure" and cov.interrupt == "sure", tostring(cov.cc))
	local lowMe = M("WARRIOR", 30, "TANK")
	lowMe.isSelf = true
	local onlyBash = S.Coverage({ lowMe }, function(e) return e.sp == "shield_bash" end)
	check("14h own shield bash stays possible (needs a shield)", onlyBash.interrupt == "possible", tostring(onlyBash.interrupt))
	check("14i hunter: Trueshot Aura possible from 25, Wyvern Sting gone", S.Coverage({ M("HUNTER", 25) }).buff_ap == "possible"
		and S.Coverage({ M("HUNTER", 24) }).buff_ap == nil and ns.SPELLS.wyvern_sting == nil)
	check("14j druid: Feral Charge from 20, Bash from 14", S.Coverage({ M("DRUID", 14) }).interrupt == "possible")
end

print("Links, favourites, open roles and priority (0.7.0)")
do
	local function has(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end return false end
	check("15a warrior links to attack power only", #ns.LINKS.class_WARRIOR == 1 and ns.LINKS.class_WARRIOR[1] == "buff_ap")
	check("15b priest links to Fortitude, Fear Ward, Divine Spirit", #ns.LINKS.class_PRIEST == 3 and has(ns.LINKS.class_PRIEST, "buff_stamina")
		and has(ns.LINKS.class_PRIEST, "buff_fearward") and has(ns.LINKS.class_PRIEST, "buff_spirit"))
	check("15c warlock links to healthstone and summoning", has(ns.LINKS.class_WARLOCK, "healthstone") and has(ns.LINKS.class_WARLOCK, "summon"))
	check("15d hunter's talent aura is not linked", ns.LINKS.class_HUNTER == nil)
	check("15e sole-class chips link back to their class", ns.LINKS.buff_stamina[1] == "class_PRIEST" and ns.LINKS.summon[1] == "class_WARLOCK"
		and ns.LINKS.buff_ap == nil)
	local states, info = S.ResolveStates({ class_WARRIOR = "need" }, {})
	check("15f warrior 'required' -> attack power 'required' (linked)", states.buff_ap == "need" and info.linked.buff_ap == "class_WARRIOR"
		and info.explicitNeed.class_WARRIOR and not info.explicitNeed.buff_ap)
	states = S.ResolveStates({}, {})
	check("15g switching the warrior off removes the linked state", states.buff_ap == "ignore")
	states, info = S.ResolveStates({ class_WARRIOR = "need" }, { buff_ap = true })
	check("15h override: attack power off despite the warrior", states.buff_ap == "ignore" and info.overridden.buff_ap == "class_WARRIOR"
		and states.class_WARRIOR == "need")
	states = S.ResolveStates({ class_WARRIOR = "pref", buff_ap = "need" }, {})
	check("15i an own stronger setting wins over the link", states.buff_ap == "need")
	states, info = S.ResolveStates({ buff_stamina = "pref" }, {})
	check("15j no chain reaction: Fortitude -> priest, but not Fear Ward", states.class_PRIEST == "pref" and states.buff_fearward == "ignore")
	-- Screenshot case: tank + 2 dps, a hunter joins as dps, only the healer slot is left.
	local host = { M("WARRIOR", 22, "TANK"), M("ROGUE", 22, "DAMAGER"), M("PALADIN", 22, "DAMAGER") }
	local ctx = dungeonCtx(host, { M("HUNTER", 22, "DAMAGER") })
	ctx.states.class_MAGE = "need"
	ctx.explicitNeed = { class_MAGE = true }
	local r = S.Evaluate(ctx)
	check("15k mage required, only a healer slot left -> sorted out", r.excluded and hasReason(r, "R_REQUIRED_NO_SLOT", "class_MAGE"), reasonsText(r))
	ctx = dungeonCtx(host, { M("HUNTER", 22, "DAMAGER") })
	ctx.states.class_PRIEST = "need"
	ctx.explicitNeed = { class_PRIEST = true }
	r = S.Evaluate(ctx)
	check("15l priest required, healer slot left -> stays (priest can heal)", not r.excluded and hasReason(r, "R_STILL_MISSING", "class_PRIEST")
		and hasReason(r, "R_LOWER_PRIORITY"), reasonsText(r))
	ctx = dungeonCtx(host, { M("HUNTER", 22, "DAMAGER") })
	ctx.states.buff_ap = "need"
	ctx.explicitNeed = {}
	r = S.Evaluate(ctx)
	check("15m a linked 'required' chip never sorts out alone", not r.excluded, reasonsText(r))
	ctx = dungeonCtx({ M("WARRIOR", 22, "TANK") }, { M("HUNTER", 22, "DAMAGER") })
	ctx.states.class_MAGE = "need"
	ctx.explicitNeed = { class_MAGE = true }
	r = S.Evaluate(ctx)
	check("15n with dps slots left the mage can still join", not r.excluded and #r.needMissing == 1, reasonsText(r))
	-- Instance names for templates
	ns.clientLocale = "deDE"
	local entry = { activityName = "Burg Shadowfang", activityInfo = { mapID = 33 } }
	check("15o English template gets the English name", ns.InstanceName(entry, "enUS") == "Shadowfang Keep", ns.InstanceName(entry, "enUS"))
	check("15p German template keeps the client name", ns.InstanceName(entry, "deDE") == "Burg Shadowfang")
	check("15q Ruins of Lordaeron (Forever map 2999)", ns.InstanceName({ activityName = "Ruinen von Lordaeron", activityInfo = { mapID = 2999 } }, "enUS")
		== "Ruins of Lordaeron")
	check("15r unknown map ID: found by the German name, wing translated",
		ns.InstanceName({ activityName = "Scharlachrotes Kloster - Bibliothek", activityInfo = { mapID = 99999 } }, "enUS") == "Scarlet Monastery - Library",
		ns.InstanceName({ activityName = "Scharlachrotes Kloster - Bibliothek", activityInfo = { mapID = 99999 } }, "enUS"))
	check("15s unknown instance keeps the client name", ns.InstanceName({ activityName = "Neue Instanz", activityInfo = { mapID = 4242 } }, "enUS") == "Neue Instanz")
end

print("Quests & zones and role chips (0.7.4)")
do
	local function otherCtx(host, guest)
		return { host = host, guest = guest, maxPlayers = 5, profileKey = "other", states = ns.CopyTable(ns.DEFAULT_ABILITY_STATES.other) }
	end
	local r = S.Evaluate(otherCtx({ M("HUNTER", 22, "DAMAGER") }, { M("HUNTER", 21, "DAMAGER") }))
	check("16a quests: another hunter is not sorted out", not r.excluded and not hasReason(r, "R_DUP_CLASS"), reasonsText(r))
	local ctx = otherCtx({ M("HUNTER", 22, "DAMAGER") }, { M("PRIEST", 21, "HEALER") })
	ctx.allowedGuestRoles = { DAMAGER = true }
	r = S.Evaluate(ctx)
	check("16b quests: role chips are ignored", not r.excluded, reasonsText(r))
	check("16c solo next to a solo player: no role restriction", ns.Engine.AllowedRolesFor(false, 1) == nil)
	ns.db.roleChips = { DAMAGER = true, TANK = false, HEALER = false }
	local own = ns.Engine.AllowedRolesFor(true, 1)
	local group = ns.Engine.AllowedRolesFor(false, 3)
	check("16d solo joining a group: chips are your roles; in a group: roles you look for", own and own.DAMAGER and not own.HEALER
		and group and group.DAMAGER)
	ns.db.roleChips = {}
	ctx = dungeonCtx({ M("HUNTER", 22, "DAMAGER") }, { M("PRIEST", 21, nil, { healer = true }) })
	ctx.allowedGuestRoles = ns.Engine.AllowedRolesFor(false, 1)
	r = S.Evaluate(ctx)
	check("16e screenshot case: solo hunter opening a group gets the healer", not r.excluded and (hasReason(r, "R_FILLS_ROLE", "HEALER") or hasReason(r, "R_SLOT_FREE", "HEALER")), reasonsText(r))
end

print("Abbreviations and template languages")
do
	local function contains(list, value) for _, v in ipairs(list) do if v == value then return true end end return false end
	local wc = ns.AbbreviationSteps("Höhlen des Wehklagens", "deDE")
	check("A1 'Höhlen des Wehklagens' -> 'Höhlen d. Wehklagens'", contains(wc, "Höhlen d. Wehklagens"), table.concat(wc, " | "))
	local rl = ns.AbbreviationSteps("Ruinen von Lordaeron", "deDE")
	check("A2 'Ruinen von Lordaeron' -> 'Ruinen v. Lordaeron'", contains(rl, "Ruinen v. Lordaeron"), table.concat(rl, " | "))
	local en = ns.AbbreviationSteps("The Temple of Atal'Hakkar", "enUS")
	check("A3 English: drop 'The', 'of' -> 'o.'", contains(en, "Temple o. Atal'Hakkar"), table.concat(en, " | "))
	check("A4 no change for words without fillers", #ns.AbbreviationSteps("Todesminen", "deDE") == 0)
	check("A5 'Aldarin Schattentanz' -> 'Aldarin S.'", ns.ShortName("Aldarin Schattentanz") == "Aldarin S.", tostring(ns.ShortName("Aldarin Schattentanz")))
	check("A6 umlaut initial kept whole", ns.ShortName("Grüne Ölbach") == "Grüne Ö.", tostring(ns.ShortName("Grüne Ölbach")))
	check("A7 single name is not shortened", ns.ShortName("Kragnar") == nil)
	local langs = ns.TemplateLanguages()
	check("T1 German client: templates in German + English only", #langs == 2 and langs[1] == "deDE" and langs[2] == "enUS", table.concat(langs, ","))
	local saved = ns.clientLocale
	ns.clientLocale = "enUS"
	local en1 = ns.TemplateLanguages()
	check("T2 English client: English only", #en1 == 1 and en1[1] == "enUS", table.concat(en1, ","))
	ns.clientLocale = saved
	check("T3 default template name", ns.GetTemplateName("deDE", "join_short") == ns.L.TONE_short, ns.GetTemplateName("deDE", "join_short"))
	ns.db.templateNames.deDE = { join_short = "Raid-Anfrage" }
	check("T4 custom template name", ns.GetTemplateName("deDE", "join_short") == "Raid-Anfrage")
	ns.db.templateNames.deDE = nil
end

print("Locale tests (Sprachdateien)")
do
	local base = ns.Locales.enUS
	for _, lang in ipairs(ns.ALL_LANGUAGES) do
		local strings = ns.Locales[lang]
		local missing = {}
		if not strings then
			missing[1] = "<locale missing>"
		else
			for key, text in pairs(base) do
				if not strings[key] then
					missing[#missing + 1] = key
				else
					-- format specifiers must match the English text
					local a = select(2, text:gsub("%%[ds]", ""))
					local b = select(2, strings[key]:gsub("%%[ds]", ""))
					if a ~= b then missing[#missing + 1] = key .. "(format)" end
				end
			end
		end
		check(("UI strings complete: %s"):format(lang), #missing == 0, table.concat(missing, ", "))
		local t = ns.DefaultTemplates[lang]
		local okT = t ~= nil
		for _, key in ipairs(ns.TEMPLATE_KEYS) do
			if not t or not t[key] then okT = false end
		end
		check(("templates complete: %s"):format(lang), okT)
		local w = ns.Words[lang]
		local okW = w and w.roles and w.roles.TANK and w.classes and w.classes.WARLOCK
		check(("class/role words: %s"):format(lang), okW and true or false)
	end
end

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
