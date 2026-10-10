local _, ns = ...

--[[
Instance names for the {instance} placeholder. The game only returns names in the client
language, so an English template on a German client would say "Burg Shadowfang". BGF looks
the name up by the instance map ID (activityInfo.mapID, the same IDs as Classic; checked in
the Forever beta: 33, 36, 43, Ruins of Lordaeron = 2999) and falls back to the German name.
Wings ("Scharlachrotes Kloster - Bibliothek") are translated word by word from German.
]]
ns.INSTANCE_NAMES = {
	[389]  = { enUS = "Ragefire Chasm",           deDE = "Flammenschlund" },
	[36]   = { enUS = "The Deadmines",            deDE = "Todesminen" },
	[43]   = { enUS = "Wailing Caverns",          deDE = "Höhlen des Wehklagens" },
	[33]   = { enUS = "Shadowfang Keep",          deDE = "Burg Shadowfang" },
	[2999] = { enUS = "Ruins of Lordaeron",       deDE = "Ruinen von Lordaeron" },
	[34]   = { enUS = "The Stockade",             deDE = "Das Verlies" },
	[48]   = { enUS = "Blackfathom Deeps",        deDE = "Tiefschwarze Grotte" },
	[90]   = { enUS = "Gnomeregan",               deDE = "Gnomeregan" },
	[47]   = { enUS = "Razorfen Kraul",           deDE = "Kral der Klingenhauer" },
	[189]  = { enUS = "Scarlet Monastery",        deDE = "Scharlachrotes Kloster" },
	[129]  = { enUS = "Razorfen Downs",           deDE = "Hügel der Klingenhauer" },
	[70]   = { enUS = "Uldaman",                  deDE = "Uldaman" },
	[209]  = { enUS = "Zul'Farrak",               deDE = "Zul'Farrak" },
	[349]  = { enUS = "Maraudon",                 deDE = "Maraudon" },
	[109]  = { enUS = "Sunken Temple",            deDE = "Versunkener Tempel" },
	[230]  = { enUS = "Blackrock Depths",         deDE = "Schwarzfelstiefen" },
	[229]  = { enUS = "Blackrock Spire",          deDE = "Schwarzfelsspitze" },
	[429]  = { enUS = "Dire Maul",                deDE = "Düsterbruch" },
	[329]  = { enUS = "Stratholme",               deDE = "Stratholme" },
	[289]  = { enUS = "Scholomance",              deDE = "Scholomance" },
	[409]  = { enUS = "Molten Core",              deDE = "Geschmolzener Kern" },
	[249]  = { enUS = "Onyxia's Lair",            deDE = "Onyxias Hort" },
	[469]  = { enUS = "Blackwing Lair",           deDE = "Pechschwingenhort" },
	[309]  = { enUS = "Zul'Gurub",                deDE = "Zul'Gurub" },
	[509]  = { enUS = "Ruins of Ahn'Qiraj",       deDE = "Ruinen von Ahn'Qiraj" },
	[531]  = { enUS = "Temple of Ahn'Qiraj",      deDE = "Tempel von Ahn'Qiraj" },
	[533]  = { enUS = "Naxxramas",                deDE = "Naxxramas" },
}

-- Other German spellings (Classic names) that point to the same instance.
local GERMAN_ALIASES = {
	["Die Todesminen"] = 36, ["Burg Schattenfang"] = 33, ["Der Tempel von Atal'Hakkar"] = 109,
	["Untere Schwarzfelsspitze"] = 229, ["Obere Schwarzfelsspitze"] = 229,
}

-- Wing and difficulty words, German -> English.
local WING_WORDS = {
	deDE = {
		["Friedhof"] = "Graveyard", ["Bibliothek"] = "Library", ["Waffenkammer"] = "Armory",
		["Kathedrale"] = "Cathedral", ["Ost"] = "East", ["West"] = "West", ["Nord"] = "North",
		["Untere"] = "Lower", ["Obere"] = "Upper", ["Lebend"] = "Living", ["Untot"] = "Undead",
		["Heroisch"] = "Heroic", ["Normal"] = "Normal",
	},
}

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function translateRest(rest, fromLang)
	local words = WING_WORDS[fromLang]
	if not words or rest == "" then return rest end
	return (rest:gsub("[%a\128-\255]+", function(w) return words[w] or w end))
end

-- Name of the entry's instance in `lang` (template language).
function ns.InstanceName(entry, lang)
	local clientName = entry and entry.activityName or ""
	if not lang or lang == ns.clientLocale then return clientName end
	local mapID = entry.activityInfo and entry.activityInfo.mapID
	local names = mapID and ns.INSTANCE_NAMES[mapID]
	local localName
	if not names and ns.clientLocale == "deDE" then
		-- unknown map ID: find the German name inside the activity name
		for id, n in pairs(ns.INSTANCE_NAMES) do
			if clientName:find(n.deDE, 1, true) then names, localName = ns.INSTANCE_NAMES[id], n.deDE break end
		end
		if not names then
			for alias, id in pairs(GERMAN_ALIASES) do
				if clientName:find(alias, 1, true) then names, localName = ns.INSTANCE_NAMES[id], alias break end
			end
		end
	end
	if not names then return clientName end
	local target = names[lang] or names.enUS
	-- keep a wing or difficulty that follows (or precedes) the instance name
	localName = localName or names[ns.clientLocale]
	if localName and clientName:find(localName, 1, true) then
		local s, e = clientName:find(localName, 1, true)
		local before, after = trim(clientName:sub(1, s - 1)), trim(clientName:sub(e + 1))
		before = translateRest(before, ns.clientLocale)
		after = translateRest(after, ns.clientLocale)
		local text = target
		if before ~= "" then text = before .. " " .. text end
		if after ~= "" then
			text = text .. (after:match("^[%-:(]") and " " or " - ") .. after
		end
		return text
	end
	return target
end
