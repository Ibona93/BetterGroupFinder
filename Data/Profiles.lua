local _, ns = ...

--[[
Rating profiles. BGF picks one from the listing's activity:
  * maxNumPlayers <= 5      -> "dungeon"
  * maxNumPlayers  > 5      -> "raid", role targets scaled by size
  * Quests & zones / custom -> "other" (no role limits, abilities only as a bonus)

`strictRoles`: a role above its target makes the listing "sorted out".
Role targets for raids are planning values; above them BGF only lowers the rating.
]]

ns.PROFILE_KEYS = { "dungeon", "raid", "other" }

local RAID_ROLES = {
	[10] = { TANK = 2, HEALER = 3, DAMAGER = 5 },
	[20] = { TANK = 3, HEALER = 5, DAMAGER = 12 },
	[40] = { TANK = 4, HEALER = 10, DAMAGER = 26 },
}

function ns.GetRoleTargets(profileKey, maxPlayers)
	if profileKey == "dungeon" then
		return { TANK = 1, HEALER = 1, DAMAGER = math.max((maxPlayers or 5) - 2, 1) }, true
	elseif profileKey == "raid" then
		local best
		for size, roles in pairs(RAID_ROLES) do
			if size >= (maxPlayers or 40) and (not best or size < best) then best = size end
		end
		local roles = RAID_ROLES[best or 40]
		local scale = (maxPlayers or 40) / (best or 40)
		local tanks = math.max(1, math.floor(roles.TANK * scale + 0.5))
		local healers = math.max(1, math.floor(roles.HEALER * scale + 0.5))
		return { TANK = tanks, HEALER = healers, DAMAGER = math.max((maxPlayers or 40) - tanks - healers, 1) }, false
	end
	return nil, false
end

-- Default state per ability and profile: "need", "pref" or "ignore".
-- Class chips (class_*) start as "ignore" everywhere.
ns.DEFAULT_ABILITY_STATES = {
	dungeon = {
		cc = "pref", interrupt = "pref", battleres = "ignore", buff_ap = "ignore", buff_mana = "ignore",
		curse = "ignore", magic = "ignore", poison = "ignore", disease = "ignore",
	},
	raid = {
		cc = "pref", interrupt = "pref", battleres = "pref", buff_ap = "pref", buff_mana = "pref",
		curse = "pref", magic = "pref", poison = "pref", disease = "pref",
	},
	other = {
		cc = "ignore", interrupt = "ignore", battleres = "ignore", buff_ap = "ignore", buff_mana = "ignore",
		curse = "ignore", magic = "ignore", poison = "ignore", disease = "ignore",
	},
}
for _, states in pairs(ns.DEFAULT_ABILITY_STATES) do
	for _, class in ipairs(ns.CLASS_ORDER) do states["class_" .. class] = "ignore" end
end

--[[
Instance hints by instance map ID (activityInfo.mapID). Listed abilities get 1.5x weight
and count as "preferred" even if the filter says "ignored". Classic map IDs; Forever-only
instances (e.g. Ruins of Lordaeron) can be added once their IDs are known: /bgf debug
prints the mapID of a hovered listing.
]]
ns.INSTANCE_HINTS = {
	[43]  = { "poison", "magic" },            -- Wailing Caverns
	[33]  = { "curse" },                       -- Shadowfang Keep
	[90]  = { "poison", "disease" },          -- Gnomeregan
	[47]  = { "poison", "curse" },            -- Razorfen Kraul
	[109] = { "curse", "magic" },             -- Sunken Temple
	[349] = { "poison", "curse" },            -- Maraudon
	[230] = { "class_PRIEST", "magic" },          -- Blackrock Depths (Fear Ward)
	[329] = { "disease", "curse" },           -- Stratholme
	[289] = { "curse", "disease", "magic" },  -- Scholomance
	[409] = { "curse", "magic", "class_PRIEST" }, -- Molten Core
	[249] = { "class_PRIEST" },                   -- Onyxia's Lair (Fear Ward)
	[469] = { "magic", "class_PRIEST" },          -- Blackwing Lair
	[309] = { "poison", "curse" },            -- Zul'Gurub
}
