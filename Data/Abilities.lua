local _, ns = ...

--[[
Group utility per class for WoW Forever.

Each entry: ability id, level the class learns it, rank-1 spell IDs (used only to check
YOUR OWN spellbook), and `possible = true` when it depends on a talent, a pet, a shield
or a creature type, so BGF can only say "may bring".

Source status (October 2026, beta build 1.60.1):
  * Learn levels and spell IDs follow WoW Classic. Forever keeps the classic spell set
    for these utilities as far as public class previews show, but they are NOT verified
    in the Forever client. If a spell ID does not exist in Forever, BGF notices that
    your own spellbook check fails and falls back to class + level.
  * Verified Forever changes: no Bloodlust/Heroism for shamans (only a personal
    talent), Fear Ward for all priests at level 20, Blessing of Kings/Salvation and Divine
    Spirit baseline, no Wyvern Sting.
  * Class chips (0.6.0) mean "this class in the group"; buffs only one class brings
    (Fortitude, Kings, Healthstones ...) appear in that class's tooltip only. Buffs several
    classes bring keep their own chips (attack power, mana).
  * Everything here is meant to be edited when Blizzard changes classes.
]]

-- Ability ids and default weight (points when a group gains it). `group` decides where the
-- chip sits in the filter bar: "core" always visible, "more" behind "+ more", "class"
-- behind "+ Classes". Class chips mean "this class in the group".
ns.CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
ns.CLASS_WEIGHT = 6

ns.ABILITIES = {
	{ id = "cc",        weight = 10, group = "core" },
	{ id = "interrupt", weight = 8,  group = "core" },
	{ id = "battleres", weight = 6,  group = "core" },
	{ id = "buff_ap",   weight = 2,  group = "core" },  -- attack power: warrior, paladin, shaman, hunter (talent)
	{ id = "buff_mana", weight = 2,  group = "core" },  -- mana: paladin, shaman
	{ id = "curse",     weight = 6,  group = "more" },
	{ id = "magic",     weight = 6,  group = "more" },
	{ id = "poison",    weight = 5,  group = "more" },
	{ id = "disease",   weight = 5,  group = "more" },
}
for _, class in ipairs(ns.CLASS_ORDER) do
	ns.ABILITIES[#ns.ABILITIES + 1] = { id = "class_" .. class, weight = ns.CLASS_WEIGHT, group = "class", class = class }
end

ns.ABILITY_BY_ID = {}
for i, ability in ipairs(ns.ABILITIES) do
	ability.order = i
	ns.ABILITY_BY_ID[ability.id] = ability
end

-- Categories that only appear in the class tooltips (not rated on their own).
ns.TOOLTIP_CATEGORIES = { "buff", "utility" }

--[[
Spells shown in the tooltips. The name comes from the game (C_Spell.GetSpellName, so it is in
the client language); if the ID does not exist in Forever, BGF falls back to the names below
(German or English).
]]
ns.SPELLS = {
	battle_shout     = { id = 6673,  enUS = "Battle Shout",          deDE = "Schlachtruf" },
	shield_bash      = { id = 72,    enUS = "Shield Bash",           deDE = "Schildhieb" },
	pummel           = { id = 6552,  enUS = "Pummel",                deDE = "Zuschlagen" },
	concussion_blow  = { id = 12809, enUS = "Concussion Blow",       deDE = "Erschütternder Schlag" },
	blessing_might   = { id = 19740, enUS = "Blessing of Might",     deDE = "Segen der Macht" },
	blessing_wisdom  = { id = 19742, enUS = "Blessing of Wisdom",    deDE = "Segen der Weisheit" },
	blessing_kings   = { id = 20217, enUS = "Blessing of Kings",     deDE = "Segen der Könige" },
	blessing_salvation = { id = 1038, enUS = "Blessing of Salvation", deDE = "Segen der Rettung" },
	purify           = { id = 1152,  enUS = "Purify",                deDE = "Läutern" },
	hammer_justice   = { id = 853,   enUS = "Hammer of Justice",     deDE = "Hammer der Gerechtigkeit" },
	turn_undead      = { id = 2878,  enUS = "Turn Undead",           deDE = "Untote vertreiben" },
	repentance       = { id = 20066, enUS = "Repentance",            deDE = "Buße" },
	cleanse          = { id = 4987,  enUS = "Cleanse",               deDE = "Reinigung des Glaubens" },
	freezing_trap    = { id = 1499,  enUS = "Freezing Trap",         deDE = "Eiskältefalle" },
	scatter_shot     = { id = 19503, enUS = "Scatter Shot",          deDE = "Streuschuss" },
	intimidation     = { id = 19577, enUS = "Intimidation",          deDE = "Einschüchterung" },
	trueshot_aura    = { id = 19506, enUS = "Trueshot Aura",         deDE = "Aura des Volltreffers" },
	sap              = { id = 6770,  enUS = "Sap",                   deDE = "Kopfnuss" },
	kick             = { id = 1766,  enUS = "Kick",                  deDE = "Tritt" },
	fortitude        = { id = 1243,  enUS = "Power Word: Fortitude", deDE = "Machtwort: Seelenstärke" },
	fear_ward        = { id = 6346,  enUS = "Fear Ward",             deDE = "Furchtzauberschutz" },
	divine_spirit    = { id = 14752, enUS = "Divine Spirit",         deDE = "Göttlicher Willen" },
	silence          = { id = 15487, enUS = "Silence",               deDE = "Stille" },
	cure_disease     = { id = 528,   enUS = "Cure Disease",          deDE = "Krankheit heilen" },
	dispel_magic     = { id = 527,   enUS = "Dispel Magic",          deDE = "Magiebannung" },
	shackle_undead   = { id = 9484,  enUS = "Shackle Undead",        deDE = "Untote fesseln" },
	earth_shock      = { id = 8042,  enUS = "Earth Shock",           deDE = "Erdschock" },
	strength_earth   = { id = 8075,  enUS = "Strength of Earth Totem", deDE = "Totem der Erdstärke" },
	mana_spring      = { id = 5675,  enUS = "Mana Spring Totem",     deDE = "Totem der Manaquelle" },
	mana_tide        = { id = 16190, enUS = "Mana Tide Totem",       deDE = "Totem der Manaflut" },
	cure_poison_sham = { id = 526,   enUS = "Cure Poison",           deDE = "Vergiftung heilen" },
	cure_disease_sham = { id = 2870, enUS = "Cure Disease",          deDE = "Krankheit heilen" },
	arcane_intellect = { id = 1459,  enUS = "Arcane Intellect",      deDE = "Arkane Intelligenz" },
	polymorph        = { id = 118,   enUS = "Polymorph",             deDE = "Verwandlung" },
	remove_lesser_curse = { id = 475, enUS = "Remove Lesser Curse",  deDE = "Geringen Fluch aufheben" },
	counterspell     = { id = 2139,  enUS = "Counterspell",          deDE = "Gegenzauber" },
	fear             = { id = 5782,  enUS = "Fear",                  deDE = "Furcht" },
	healthstone      = { id = 6201,  enUS = "Create Healthstone",    deDE = "Gesundheitsstein herstellen" },
	soulstone        = { id = 693,   enUS = "Create Soulstone",      deDE = "Seelenstein herstellen" },
	summoning        = { id = 698,   enUS = "Ritual of Summoning",   deDE = "Ritual der Beschwörung" },
	seduction        = { id = 6358,  enUS = "Seduction",             deDE = "Verführung" },
	banish           = { id = 710,   enUS = "Banish",                deDE = "Verbannen" },
	devour_magic     = { id = 19505, enUS = "Devour Magic",          deDE = "Magie verschlingen" },
	spell_lock       = { id = 19244, enUS = "Spell Lock",            deDE = "Zaubersperre" },
	mark_wild        = { id = 1126,  enUS = "Mark of the Wild",      deDE = "Mal der Wildnis" },
	roots            = { id = 339,   enUS = "Entangling Roots",      deDE = "Wucherwurzeln" },
	hibernate        = { id = 2637,  enUS = "Hibernate",             deDE = "Winterschlaf" },
	bash             = { id = 5211,  enUS = "Bash",                  deDE = "Hieb" },
	feral_charge     = { id = 16979, enUS = "Feral Charge",          deDE = "Wilde Attacke" },
	cure_poison_druid = { id = 8946, enUS = "Cure Poison",           deDE = "Vergiftung heilen" },
	rebirth          = { id = 20484, enUS = "Rebirth",               deDE = "Wiedergeburt" },
	remove_curse     = { id = 2782,  enUS = "Remove Curse",          deDE = "Fluch aufheben" },
}

--[[
Per class: `a` ability id (or "buff"/"utility" = shown only in the class tooltip), `level`,
`sp` tooltip spell, `spells` rank-1 IDs for YOUR OWN spellbook check (none for pet spells),
`possible` = BGF can only say "may bring", `cond` = condition(s) shown in the tooltip
(locale keys COND_*).

Talents (cond TALENT) follow the Forever beta trees, build 1.60.1.70291 (talentsforever.com,
CC BY 4.0): earliest level = 10 + 5 x (row - 1). They count as "possible" for other players;
your own character counts as sure once the talent is in your spellbook.
]]
ns.CLASS_ABILITIES = {
	WARRIOR = {
		{ a = "buff_ap",   level = 1,  sp = "battle_shout", spells = { 6673 } },
		{ a = "interrupt", level = 12, sp = "shield_bash", spells = { 72 }, possible = true, cond = "SHIELD" },
		{ a = "interrupt", level = 38, sp = "pummel", spells = { 6552 } },
		{ a = "cc",        level = 30, sp = "concussion_blow", spells = { 12809 }, possible = true, cond = "TALENT" },
	},
	PALADIN = {
		{ a = "buff_ap",   level = 4,  sp = "blessing_might", spells = { 19740 } },
		{ a = "poison",    level = 8,  sp = "purify", spells = { 1152 } },
		{ a = "disease",   level = 8,  sp = "purify", spells = { 1152 } },
		{ a = "interrupt", level = 8,  sp = "hammer_justice", spells = { 853 }, cond = "STUN" },
		{ a = "buff_mana", level = 14, sp = "blessing_wisdom", spells = { 19742 } },
		{ a = "buff",      level = 20, sp = "blessing_kings", spells = { 20217 } },     -- baseline in Forever
		{ a = "buff",      level = 26, sp = "blessing_salvation", spells = { 1038 } },  -- baseline in Forever
		{ a = "cc",        level = 24, sp = "turn_undead", spells = { 2878 }, possible = true, cond = "UNDEAD" },
		{ a = "cc",        level = 30, sp = "repentance", spells = { 20066 }, possible = true, cond = { "TALENT", "HUMANOID" } },
		{ a = "magic",     level = 42, sp = "cleanse", spells = { 4987 } },
	},
	HUNTER = {
		{ a = "cc",        level = 20, sp = "freezing_trap", spells = { 1499 } },
		{ a = "buff_ap",   level = 25, sp = "trueshot_aura", spells = { 19506 }, possible = true, cond = { "TALENT", "RANGED" } },
		{ a = "cc",        level = 30, sp = "scatter_shot", spells = { 19503 }, possible = true, cond = "TALENT" },
		{ a = "cc",        level = 30, sp = "intimidation", spells = { 19577 }, possible = true, cond = "TALENT" },
	},
	ROGUE = {
		{ a = "cc",        level = 10, sp = "sap", spells = { 6770 } },
		{ a = "interrupt", level = 12, sp = "kick", spells = { 1766 } },
	},
	PRIEST = {
		{ a = "buff",      level = 1,  sp = "fortitude", spells = { 1243 } },
		{ a = "disease",   level = 14, sp = "cure_disease", spells = { 528 } },
		{ a = "magic",     level = 18, sp = "dispel_magic", spells = { 527 } },
		{ a = "buff",      level = 20, sp = "fear_ward", spells = { 6346 } },          -- all priests in Forever
		{ a = "cc",        level = 20, sp = "shackle_undead", spells = { 9484 }, possible = true, cond = "UNDEAD" },
		{ a = "buff",      level = 30, sp = "divine_spirit", spells = { 14752 } },     -- baseline in Forever
		{ a = "interrupt", level = 30, sp = "silence", spells = { 15487 }, possible = true, cond = "TALENT" },
	},
	SHAMAN = {
		{ a = "interrupt", level = 4,  sp = "earth_shock", spells = { 8042 } },
		{ a = "buff_ap",   level = 10, sp = "strength_earth", spells = { 8075 } },
		{ a = "poison",    level = 16, sp = "cure_poison_sham", spells = { 526 } },
		{ a = "disease",   level = 22, sp = "cure_disease_sham", spells = { 2870 } },
		{ a = "buff_mana", level = 25, sp = "mana_tide", spells = { 16190 }, possible = true, cond = "TALENT" },
		{ a = "buff_mana", level = 26, sp = "mana_spring", spells = { 5675 } },
	},
	MAGE = {
		{ a = "buff",      level = 1,  sp = "arcane_intellect", spells = { 1459 } },
		{ a = "cc",        level = 8,  sp = "polymorph", spells = { 118 } },
		{ a = "curse",     level = 18, sp = "remove_lesser_curse", spells = { 475 } },
		{ a = "interrupt", level = 24, sp = "counterspell", spells = { 2139 } },
	},
	WARLOCK = {
		{ a = "cc",        level = 8,  sp = "fear", spells = { 5782 }, possible = true, cond = "RISKY" },
		{ a = "utility",   level = 10, sp = "healthstone", spells = { 6201 } },
		{ a = "battleres", level = 18, sp = "soulstone", spells = { 693 } },
		{ a = "utility",   level = 20, sp = "summoning", spells = { 698 } },
		{ a = "cc",        level = 20, sp = "seduction", possible = true, cond = "SUCCUBUS" },  -- pet spell
		{ a = "cc",        level = 28, sp = "banish", spells = { 710 }, cond = "DEMON" },
		{ a = "magic",     level = 30, sp = "devour_magic", possible = true, cond = "PET" },    -- Felhunter
		{ a = "interrupt", level = 36, sp = "spell_lock", possible = true, cond = "PET" },      -- Felhunter
	},
	DRUID = {
		{ a = "buff",      level = 1,  sp = "mark_wild", spells = { 1126 } },
		{ a = "cc",        level = 8,  sp = "roots", spells = { 339 } },   -- indoors in Forever
		{ a = "poison",    level = 14, sp = "cure_poison_druid", spells = { 8946 } },
		{ a = "interrupt", level = 14, sp = "bash", spells = { 5211 }, possible = true, cond = "BEAR" }, -- classic level, not verified
		{ a = "cc",        level = 18, sp = "hibernate", spells = { 2637 }, possible = true, cond = "BEAST" },
		{ a = "battleres", level = 20, sp = "rebirth", spells = { 20484 } },
		{ a = "interrupt", level = 20, sp = "feral_charge", spells = { 16979 }, possible = true, cond = { "TALENT", "BEAR" } },
		{ a = "curse",     level = 24, sp = "remove_curse", spells = { 2782 } },
	},
}

-- Condition text of an entry, e.g. "Talent, nur Humanoide"; nil without condition.
function ns.ConditionText(entry)
	local cond = entry and entry.cond
	if not cond then return nil end
	if type(cond) == "string" then cond = { cond } end
	local parts = {}
	for _, key in ipairs(cond) do parts[#parts + 1] = ns.L["COND_" .. key] end
	return table.concat(parts, ", ")
end

-- Spell name in the client language: game data first, then the table above.
function ns.SpellName(key)
	local spell = ns.SPELLS[key]
	if not spell then return key end
	local api = _G.C_Spell
	if api and api.GetSpellName then
		local ok, name = pcall(api.GetSpellName, spell.id)
		if ok and type(name) == "string" and name ~= "" then return name end
	end
	return spell[ns.clientLocale or "enUS"] or spell.enUS
end
