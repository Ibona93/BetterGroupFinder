local ADDON_NAME, ns = ...

--[[
Core: saved settings, locale, events, slash command and refresh scheduling.
The Group Finder ("Blizzard_GroupFinder_VanillaStyle") is load-on-demand, so the UI is
attached when that addon loads.
]]

local BLIZZ_ADDON = "Blizzard_GroupFinder_VanillaStyle"

ns.DEFAULTS = {
	schema = 5,
	enabled = true,         -- "BGF filter active": rating, sorting, sorting out
	uiEnabled = true,       -- /bgf on|off: BGF list at all (off = Blizzard's original list)
	showScores = true,
	filterOpen = false,
	font = "friz",
	showAllAbilities = false,
	showClasses = false,
	autoSend = true,
	showReasons = true,
	abilityStates = ns.DEFAULT_ABILITY_STATES,
	roleChips = {},
	collapsed = { excluded = true },
	templates = {},
	templateNames = {},
	debug = false,
}

-- 0.6.0 replaced the class buff chips and "summon" by class chips: drop settings of
-- abilities that no longer exist (class chips start as "ignore").
function ns.CleanAbilityStates(states)
	for _, profile in pairs(states or {}) do
		for id in pairs(profile) do
			if not ns.ABILITY_BY_ID[id] then profile[id] = nil end
		end
	end
end

-------------------------------------------------------------------------------
-- Locale
-------------------------------------------------------------------------------

ns.clientLocale = ns.NormalizeLocale(GetLocale and GetLocale() or "enUS")

local function buildLocale()
	local base = ns.Locales.enUS or {}
	local own = ns.Locales[ns.clientLocale] or {}
	ns.L = setmetatable({}, {
		__index = function(_, key)
			return own[key] or base[key] or key
		end,
	})
end
buildLocale()

-- Localized ability and role names for the UI.
-- Buffs only one class brings are named after that class.
function ns.AbilityName(id)
	local ability = ns.ABILITY_BY_ID and ns.ABILITY_BY_ID[id]
	if ability and ability.class then return ns.ClassName(ability.class) end
	return ns.L["AB_" .. id]
end

function ns.RoleName(role)
	local words = ns.Words[ns.clientLocale] or ns.Words.enUS
	local global = (role == "TANK" and _G.TANK) or (role == "HEALER" and _G.HEALER) or (role == "DAMAGER" and _G.DAMAGER)
	return global or (words and words.roles[role]) or role
end

function ns.ClassName(class)
	local names = _G.LOCALIZED_CLASS_NAMES_MALE
	local words = ns.Words[ns.clientLocale] or ns.Words.enUS
	return (names and names[class]) or (words and words.classes[class]) or ns.Words.enUS.classes[class] or class
end

-- Formats a reason tuple { kind, key, args... } for display.
function ns.FormatReason(reason)
	local key = reason[2]
	local args = {}
	for i = 3, #reason do
		local v = reason[i]
		if type(v) == "string" then
			if v:sub(1, 5) == "cond:" then
				local keys = {}
				for condKey in v:sub(6):gmatch("[^,]+") do keys[#keys + 1] = condKey end
				v = ns.ConditionText({ cond = keys }) or ""
			elseif ns.ABILITY_BY_ID[v] then
				v = ns.AbilityName(v)
			elseif v == "TANK" or v == "HEALER" or v == "DAMAGER" then
				v = ns.RoleName(v)
			elseif RAID_CLASS_COLORS and RAID_CLASS_COLORS[v] then
				v = ns.ClassName(v)
			end
		end
		args[#args + 1] = v
	end
	local ok, text = pcall(string.format, ns.L[key], unpack(args))
	return ok and text or ns.L[key]
end

-------------------------------------------------------------------------------
-- Languages for templates
-------------------------------------------------------------------------------

-- Languages offered for templates: your client language plus English as fallback.
function ns.TemplateLanguages()
	local list = { ns.DefaultTemplates[ns.clientLocale] and ns.clientLocale or "enUS" }
	if list[1] ~= "enUS" then list[2] = "enUS" end
	return list
end

-- Display name of a template (editable), default "Friendly" / "Short".
function ns.GetTemplateName(lang, key)
	local user = ns.db and ns.db.templateNames[lang]
	if user and user[key] and user[key] ~= "" then return user[key] end
	local tone = key:match("_(%a+)$")
	return ns.L["TONE_" .. (tone or "friendly")]
end

function ns.GetTemplate(lang, key)
	local user = ns.db and ns.db.templates[lang]
	if user and user[key] and user[key] ~= "" then return user[key] end
	local defaults = ns.DefaultTemplates[lang] or ns.DefaultTemplates.enUS
	return defaults[key] or ns.DefaultTemplates.enUS[key]
end

-------------------------------------------------------------------------------
-- Refresh scheduling
-------------------------------------------------------------------------------

local refreshPending = false

function ns.RequestRefresh()
	if refreshPending then return end
	refreshPending = true
	C_Timer.After(0.05, function()
		refreshPending = false
		if ns.UI and ns.UI.Refresh then
			local ok, err = pcall(ns.UI.Refresh)
			if not ok then
				ns.Debug("refresh failed: " .. tostring(err))
				if ns.db and ns.db.debug then geterrorhandler()(err) end
			end
		end
	end)
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local frame = CreateFrame("Frame")
ns.eventFrame = frame

local function attachUI()
	if ns.UI and not ns.UI.attached and LFGBrowseFrame then
		local ok, err = pcall(ns.UI.Setup)
		if not ok then
			ns.Print("UI setup failed: " .. tostring(err))
			geterrorhandler()(err)
		end
	end
end

local function isBlizzLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		return C_AddOns.IsAddOnLoaded(BLIZZ_ADDON)
	end
	return LFGBrowseFrame ~= nil
end

frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			BetterGroupFinderDB = BetterGroupFinderDB or {}
			local isNew = next(BetterGroupFinderDB) == nil
			local oldSchema = BetterGroupFinderDB.schema or 0
			ns.db = ns.MergeDefaults(BetterGroupFinderDB, ns.DEFAULTS)
			ns.db.scale = nil -- removed in 0.2.0
			if not isNew and oldSchema < 5 then
				ns.db.compact = nil  -- 0.4.0: only the two-line view
				ns.db.fontSize = nil -- 0.4.0: fixed sizes like Blizzard (names 14, rest 12)
				ns.db.schema = 5
			end
			ns.CleanAbilityStates(ns.db.abilityStates)
			if ns.Fonts then ns.Fonts.RegisterShared() end
			if isBlizzLoaded() then attachUI() end
		elseif arg1 == BLIZZ_ADDON then
			attachUI()
		end
	elseif event == "PLAYER_LOGIN" then
		if isBlizzLoaded() then attachUI() end
	elseif event == "PLAYER_REGEN_DISABLED" then
		if ns.UI and ns.UI.OnCombatStart then ns.UI.OnCombatStart() end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if ns.UI and ns.UI.OnCombatEnd then ns.UI.OnCombatEnd() end
		ns.RequestRefresh()
	elseif event == "PLAYER_LEVEL_UP" or event == "SPELLS_CHANGED" then
		ns.Engine.InvalidateSpellCheck()
		ns.RequestRefresh()
	else
		ns.RequestRefresh()
	end
end)

for _, event in ipairs({
	"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
	"PLAYER_LEVEL_UP", "SPELLS_CHANGED", "GROUP_ROSTER_UPDATE", "LFG_LIST_ROLE_UPDATE",
	"LFG_LIST_SEARCH_RESULT_UPDATED", "LFG_LIST_ACTIVE_ENTRY_UPDATE",
}) do
	pcall(frame.RegisterEvent, frame, event)
end

-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------

SLASH_BETTERGROUPFINDER1 = "/bgf"
SlashCmdList.BETTERGROUPFINDER = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local L = ns.L
	if msg == "on" then
		ns.db.uiEnabled = true
		ns.Print(L.SLASH_ON)
		if ns.UI and ns.UI.ApplyEnabled then ns.UI.ApplyEnabled() end
	elseif msg == "off" then
		ns.db.uiEnabled = false
		ns.Print(L.SLASH_OFF)
		if ns.UI and ns.UI.ApplyEnabled then ns.UI.ApplyEnabled() end
	elseif msg == "debug" then
		ns.db.debug = not ns.db.debug
		ns.Print(ns.db.debug and L.DEBUG_ON or L.DEBUG_OFF)
		if ns.db.debug then
			ns.Print(("version %s, client %s, lockdown %s"):format(ns.VERSION, ns.clientLocale,
				tostring(ns.Engine.IsLockedDown())))
		end
	elseif msg == "help" or msg == "?" then
		ns.Print(L.SLASH_HELP)
	else
		if ns.Options and ns.Options.Open then ns.Options.Open() else ns.Print(L.SLASH_HELP) end
	end
end
