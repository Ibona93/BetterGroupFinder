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
    talent), Fear Ward for all priests at level 20.
  * Combined filters: "summon" = summoning (20) and healthstones (10, counted as "possible"
    until 20). Buffs that only one class brings are one chip per class (priest, mage, druid);
    buffs several classes bring are named by purpose (attack power, mana).
  * Everything here is meant to be edited when Blizzard changes classes.
]]

-- Ability ids, default weight (points when a group gains it) and the profiles in which
-- they are preferred out of the box. `class` = only this class brings it: the chip is
-- named after the class and its tooltip lists the spells without the class prefix.
ns.ABILITIES = {
	{ id = "cc",           weight = 10 },
	{ id = "interrupt",    weight = 8 },
	{ id = "curse",        weight = 6 },
	{ id = "magic",        weight = 6 },
	{ id = "poison",       weight = 5 },
	{ id = "disease",      weight = 5 },
	{ id = "battleres",    weight = 6 },
	{ id = "summon",       weight = 7 },  -- summoning & healthstones (warlock); no meeting stones in Forever
	{ id = "buff_stamina", weight = 4, class = "PRIEST" },  -- Fortitude & Fear Ward
	{ id = "buff_int",     weight = 2, class = "MAGE" },    -- Arcane Intellect
	{ id = "buff_wild",    weight = 3, class = "DRUID" },   -- Mark of the Wild
	{ id = "buff_ap",      weight = 2 },  -- attack power: warrior, paladin, shaman
	{ id = "buff_mana",    weight = 2 },  -- mana: paladin, shaman
}

ns.ABILITY_BY_ID = {}
for i, ability in ipairs(ns.ABILITIES) do
	ability.order = i
	ns.ABILITY_BY_ID[ability.id] = ability
end

ns.CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

--[[
Spells shown in the chip tooltips. The name comes from the game (C_Spell.GetSpellName, so it
is in the client language); if the ID does not exist in Forever, BGF falls back to the names
below (German or English).
]]
ns.SPELLS = {
	battle_shout     = { id = 6673,  enUS = "Battle Shout",          deDE = "Schlachtruf" },
	shield_bash      = { id = 72,    enUS = "Shield Bash",           deDE = "Schildhieb" },
	pummel           = { id = 6552,  enUS = "Pummel",                deDE = "Zuschlagen" },
	blessing_might   = { id = 19740, enUS = "Blessing of Might",     deDE = "Segen der Macht" },
	blessing_wisdom  = { id = 19742, enUS = "Blessing of Wisdom",    deDE = "Segen der Weisheit" },
	purify           = { id = 1152,  enUS = "Purify",                deDE = "Läutern" },
	hammer_justice   = { id = 853,   enUS = "Hammer of Justice",     deDE = "Hammer der Gerechtigkeit" },
	turn_undead      = { id = 2878,  enUS = "Turn Undead",           deDE = "Untote vertreiben" },
	cleanse          = { id = 4987,  enUS = "Cleanse",               deDE = "Reinigung des Glaubens" },
	freezing_trap    = { id = 1499,  enUS = "Freezing Trap",         deDE = "Eiskältefalle" },
	sap              = { id = 6770,  enUS = "Sap",                   deDE = "Kopfnuss" },
	kick             = { id = 1766,  enUS = "Kick",                  deDE = "Tritt" },
	fortitude        = { id = 1243,  enUS = "Power Word: Fortitude", deDE = "Machtwort: Seelenstärke" },
	fear_ward        = { id = 6346,  enUS = "Fear Ward",             deDE = "Furchtzauberschutz" },
	cure_disease     = { id = 528,   enUS = "Cure Disease",          deDE = "Krankheit heilen" },
	dispel_magic     = { id = 527,   enUS = "Dispel Magic",          deDE = "Magiebannung" },
	shackle_undead   = { id = 9484,  enUS = "Shackle Undead",        deDE = "Untote fesseln" },
	earth_shock      = { id = 8042,  enUS = "Earth Shock",           deDE = "Erdschock" },
	strength_earth   = { id = 8075,  enUS = "Strength of Earth Totem", deDE = "Totem der Erdstärke" },
	mana_spring      = { id = 5675,  enUS = "Mana Spring Totem",     deDE = "Totem der Manaquelle" },
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
	banish           = { id = 710,   enUS = "Banish",                deDE = "Verbannen" },
	devour_magic     = { id = 19505, enUS = "Devour Magic",          deDE = "Magie verschlingen" },
	mark_wild        = { id = 1126,  enUS = "Mark of the Wild",      deDE = "Mal der Wildnis" },
	roots            = { id = 339,   enUS = "Entangling Roots",      deDE = "Wucherwurzeln" },
	cure_poison_druid = { id = 8946, enUS = "Cure Poison",           deDE = "Vergiftung heilen" },
	rebirth          = { id = 20484, enUS = "Rebirth",               deDE = "Wiedergeburt" },
	remove_curse     = { id = 2782,  enUS = "Remove Curse",          deDE = "Fluch aufheben" },
}

--[[
Per class: `a` ability, `level` learn level, `sp` spell for the tooltip, `spells` rank-1 IDs
for YOUR OWN spellbook check, `possible` = BGF can only say "may bring", `cond` = condition
shown in the tooltip (locale key COND_*), `partial` = counts as "possible" without a remark
(healthstones before summoning).
]]
ns.CLASS_ABILITIES = {
	WARRIOR = {
		{ a = "buff_ap",   level = 1,  sp = "battle_shout", spells = { 6673 } },
		{ a = "interrupt", level = 12, sp = "shield_bash", spells = { 72 }, possible = true, cond = "SHIELD" },
		{ a = "interrupt", level = 38, sp = "pummel", spells = { 6552 } },
	},
	PALADIN = {
		{ a = "buff_ap",   level = 4,  sp = "blessing_might", spells = { 19740 } },
		{ a = "poison",    level = 8,  sp = "purify", spells = { 1152 } },
		{ a = "disease",   level = 8,  sp = "purify", spells = { 1152 } },
		{ a = "interrupt", level = 8,  sp = "hammer_justice", spells = { 853 }, cond = "STUN" },
		{ a = "buff_mana", level = 14, sp = "blessing_wisdom", spells = { 19742 } },
		{ a = "cc",        level = 24, sp = "turn_undead", spells = { 2878 }, possible = true, cond = "UNDEAD" },
		{ a = "magic",     level = 42, sp = "cleanse", spells = { 4987 } },
	},
	HUNTER = {
		{ a = "cc",        level = 20, sp = "freezing_trap", spells = { 1499 } },
	},
	ROGUE = {
		{ a = "cc",        level = 10, sp = "sap", spells = { 6770 } },
		{ a = "interrupt", level = 12, sp = "kick", spells = { 1766 } },
	},
	PRIEST = {
		{ a = "buff_stamina", level = 1, sp = "fortitude", spells = { 1243 } },
		{ a = "disease",   level = 14, sp = "cure_disease", spells = { 528 } },
		{ a = "magic",     level = 18, sp = "dispel_magic", spells = { 527 } },
		{ a = "buff_stamina", level = 20, sp = "fear_ward", spells = { 6346 } }, -- all priests in Forever
		{ a = "cc",        level = 20, sp = "shackle_undead", spells = { 9484 }, possible = true, cond = "UNDEAD" },
	},
	SHAMAN = {
		{ a = "interrupt", level = 4,  sp = "earth_shock", spells = { 8042 } },
		{ a = "buff_ap",   level = 10, sp = "strength_earth", spells = { 8075 } },
		{ a = "poison",    level = 16, sp = "cure_poison_sham", spells = { 526 } },
		{ a = "disease",   level = 22, sp = "cure_disease_sham", spells = { 2870 } },
		{ a = "buff_mana", level = 26, sp = "mana_spring", spells = { 5675 } },
	},
	MAGE = {
		{ a = "buff_int",  level = 1,  sp = "arcane_intellect", spells = { 1459 } },
		{ a = "cc",        level = 8,  sp = "polymorph", spells = { 118 } },
		{ a = "curse",     level = 18, sp = "remove_lesser_curse", spells = { 475 } },
		{ a = "interrupt", level = 24, sp = "counterspell", spells = { 2139 } },
	},
	WARLOCK = {
		{ a = "cc",        level = 8,  sp = "fear", spells = { 5782 }, possible = true, cond = "RISKY" },
		{ a = "summon",    level = 10, sp = "healthstone", possible = true, partial = true }, -- no summoning before 20
		{ a = "battleres", level = 18, sp = "soulstone", spells = { 693 } },
		{ a = "summon",    level = 20, sp = "summoning", spells = { 698 } },
		{ a = "cc",        level = 28, sp = "banish", spells = { 710 }, cond = "DEMON" },
		{ a = "magic",     level = 30, sp = "devour_magic", possible = true, cond = "PET" }, -- Felhunter
	},
	DRUID = {
		{ a = "buff_wild", level = 1,  sp = "mark_wild", spells = { 1126 } },
		{ a = "cc",        level = 8,  sp = "roots", spells = { 339 } },   -- indoors in Forever
		{ a = "poison",    level = 14, sp = "cure_poison_druid", spells = { 8946 } },
		{ a = "battleres", level = 20, sp = "rebirth", spells = { 20484 } },
		{ a = "curse",     level = 24, sp = "remove_curse", spells = { 2782 } },
	},
}

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
