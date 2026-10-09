--[[
Smoke test with a mocked WoW UI (Lua 5.1). Run from the addon folder:
    lua tests/smoke.lua
Loads every file from the TOC in order, attaches the UI to a fake Group Finder, feeds
search results like the ones from the beta screenshots and clicks through the features.
This catches runtime errors (nil calls, wrong fields) - it does NOT prove the layout
looks right in the real client.
]]

local failures = 0
local function check(name, cond, detail)
	print((cond and "  ok   " or "  FAIL ") .. name .. ((not cond and detail) and ("  -> " .. tostring(detail)) or ""))
	if not cond then failures = failures + 1 end
end

-------------------------------------------------------------------------------
-- Generic frame mock
-------------------------------------------------------------------------------

local eventFrames = {}
local Frame = {}

local NUMBER_GETTERS = {
	GetWidth = 458, GetHeight = 535, GetScale = 1, GetEffectiveScale = 1, GetLeft = 20, GetTop = 900,
	GetFrameLevel = 5, GetStringHeight = 12,
}

local function newFrame(kind, name)
	local f = { __kind = kind, __shown = true, __scripts = {}, __points = {}, __size = {} }
	setmetatable(f, Frame)
	if name then _G[name] = f end
	return f
end

local METHOD_PREFIXES = { "Set", "Get", "Is", "Create", "Register", "Enable", "Disable", "Clear", "Add",
	"Hook", "Show", "Hide", "Raise", "Lower", "Start", "Stop", "Unregister", "Has", "Can", "Copy" }

local function isMethodName(key)
	if type(key) ~= "string" then return false end
	for _, p in ipairs(METHOD_PREFIXES) do
		if key:sub(1, #p) == p then return true end
	end
	return key == "ForEachFrame"
end

Frame.__index = function(self, key)
	if not isMethodName(key) then return nil end
	if NUMBER_GETTERS[key] then
		return function(s)
			if key == "GetWidth" and s.__size.w then return s.__size.w end
			if key == "GetHeight" and s.__size.h then return s.__size.h end
			if key == "GetScale" and s.__scale then return s.__scale end
			return NUMBER_GETTERS[key]
		end
	end
	if key == "CreateTexture" or key == "CreateFontString" or key == "CreateMaskTexture" or key == "GetFontString" then
		return function(s)
			s.__children = s.__children or {}
			local child = newFrame(key)
			table.insert(s.__children, child)
			return child
		end
	end
	if key == "SetScript" then return function(s, n, fn) s.__scripts[n] = fn end end
	if key == "GetScript" then return function(s, n) return s.__scripts[n] end end
	if key == "HookScript" then
		return function(s, n, fn)
			local old = s.__scripts[n]
			s.__scripts[n] = function(...) if old then old(...) end fn(...) end
		end
	end
	if key == "Show" then return function(s) s.__shown = true if s.__scripts.OnShow then s.__scripts.OnShow(s) end end end
	if key == "Hide" then return function(s) s.__shown = false end end
	if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
	if key == "IsShown" then return function(s) return s.__shown end end
	if key == "SetText" then return function(s, t) s.__text = t end end
	if key == "GetText" then return function(s) return s.__text or "" end end
	if key == "SetWidth" then return function(s, w) s.__size.w = w end end
	if key == "SetHeight" then return function(s, h) s.__size.h = h end end
	if key == "SetSize" then return function(s, w, h) s.__size.w, s.__size.h = w, h end end
	if key == "SetScale" then return function(s, v) s.__scale = v end end
	if key == "SetChecked" then return function(s, v) s.__checked = v end end
	if key == "GetChecked" then return function(s) return s.__checked end end
	if key == "SetAtlas" then return function() return true end end
	if key == "GetUnboundedStringWidth" or key == "GetStringWidth" then
		-- rough Friz width: about 0.56 x font size per character, color codes not counted
		return function(fs)
			local text = (fs.__text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			local _, chars = text:gsub("[^\128-\191]", "")
			local size = fs.__fontObj and fs.__fontObj.__fontSize or 10
			return chars * size * 0.56
		end
	end
	if key == "SetFont" then return function(f, _, size) f.__fontSize = size return true end end
	if key == "SetFontObject" then return function(fs, obj) fs.__fontObj = obj end end
	if key == "GetFontObject" then return function(fs) return fs.__fontObj end end
	if key == "GetSize" then return function() return 26, 10 end end
	if key == "GetFont" then return function() return "Fonts\\FRIZQT__.TTF", 12, "" end end
	if key == "IsOwned" then return function() return false end end
	if key == "RegisterEvent" then
		return function(s, e) eventFrames[s] = eventFrames[s] or {} eventFrames[s][e] = true end
	end
	if key == "ForEachFrame" then
		return function(s, fn) for _, fr in ipairs(s.__frames or {}) do fn(fr) end end
	end
	if key == "SetDataProvider" then
		return function(s, provider)
			s.__frames = {}
			local view = s.__view
			for _, data in ipairs(provider.items) do
				view.__factory(function(template, init)
					local fr = newFrame("Button")
					local mixin = (template == "BGFRowTemplate" and BGFRowMixin)
						or (template == "BGFHeaderTemplate" and BGFHeaderMixin) or BGFMessageMixin
					for k, v in pairs(mixin) do fr[k] = v end
					fr:OnLoad()
					init(fr, data)
					table.insert(s.__frames, fr)
				end, data)
				view.__extent(nil, data)
			end
		end
	end
	return function() return nil end
end

_G.CreateFrame = function(kind, name, parent, template)
	return newFrame(kind, name)
end
_G.CreateFont = function(name) return newFrame("Font", name) end
_G.GameFontHighlightSmall = newFrame("Font")
_G.GameFontNormal = newFrame("Font")

-------------------------------------------------------------------------------
-- WoW globals used by the addon
-------------------------------------------------------------------------------

_G.unpack = unpack
_G.GetLocale = function() return "deDE" end
_G.GetCurrentRegion = function() return 3 end
_G.IsBetaBuild = function() return false end
_G.InCombatLockdown = function() return false end
_G.C_Timer = { After = function(_, fn) fn() end }
_G.SlashCmdList = {}
_G.UISpecialFrames = {}
_G.tinsert = table.insert
_G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
_G.hooksecurefunc = function(tbl, name, fn)
	local old = tbl[name]
	tbl[name] = function(...) local r = { old(...) } fn(...) return unpack(r) end
end
_G.geterrorhandler = function() return function(e) print("ERROR HANDLER: " .. tostring(e)) end end
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) _G.__lastPrint = msg end }
_G.GameTooltip = newFrame("GameTooltip")
_G.RAID_CLASS_COLORS = {}
for _, c in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
	RAID_CLASS_COLORS[c] = { r = 0.5, g = 0.5, b = 0.5 }
end
_G.LOCALIZED_CLASS_NAMES_MALE = { HUNTER = "Jäger", WARRIOR = "Krieger", PRIEST = "Priester", MAGE = "Magier", ROGUE = "Schurke", DRUID = "Druide", WARLOCK = "Hexenmeister", SHAMAN = "Schamane", PALADIN = "Paladin" }
_G.LEVEL_ABBR = "St."
_G.TANK, _G.HEALER, _G.DAMAGER = "Tank", "Heiler", "Schaden"
_G.SEND_MESSAGE, _G.GROUP_INVITE = "Nachricht senden", "Gruppeneinladung"
_G.LFGBROWSE_ACTIVITY_COUNT = "%d Aktivitäten"
_G.GetGeneralPlaystyleString = function(v) return ({ "Lernen", "Entspannt", "Kompetitiv", "Beförderung angeboten" })[v] or "" end
_G.CreateAtlasMarkup = function(a) return "|A:" .. a .. "|a" end
_G.Ambiguate = function(name) return (name:gsub("%-.*", "")) end
_G.ScrollBoxConstants = { RetainScrollPosition = true }
_G.CreateDataProvider = function(items) return { items = items } end
_G.CreateScrollBoxListLinearView = function()
	local v = {}
	function v:SetElementFactory(fn) self.__factory = fn end
	function v:SetElementExtentCalculator(fn) self.__extent = fn end
	return v
end
_G.ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.__view = view end }
_G.PlaySound = function() end
_G.SOUNDKIT = { IG_MAINMENU_OPTION_CHECKBOX_ON = 1 }

-- Player: level 22 hunter, solo, DPS
local inGroup = false
_G.UnitExists = function(u) return u == "player" or (inGroup and u == "party1") end
_G.UnitClass = function(u) if u == "player" then return "Jäger", "HUNTER" end return "Priester", "PRIEST" end
_G.UnitLevel = function() return 22 end
_G.UnitName = function(u) return u == "player" and "Ibona" or "Elowen" end
_G.UnitIsUnit = function(a, b) return a == b end
_G.UnitGroupRolesAssigned = function(u) if u == "party1" then return "HEALER" end return inGroup and "DAMAGER" or "NONE" end
_G.UnitIsGroupLeader = function() return true end
_G.UnitIsGroupAssistant = function() return false end
_G.IsInGroup = function() return inGroup end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return inGroup and 2 or 0 end
_G.GetNumSubgroupMembers = function() return inGroup and 1 or 0 end
_G.C_LFGListRoles = { GetRoles = function() return { tank = false, healer = false, dps = true } end }
_G.C_SpellBook = { IsSpellKnown = function(id) return id == 1499 end }
_G.C_AddOns = { IsAddOnLoaded = function() return true end }

local sent = {}
_G.C_ChatInfo = {
	InChatMessagingLockdown = function() return false end,
	SendChatMessage = function(text, chatType, _, target) sent[#sent + 1] = { text = text, type = chatType, target = target } end,
}
local invited = {}
_G.C_PartyInfo = { InviteUnit = function(name) invited[#invited + 1] = name end }
_G.ChatFrameUtil = {
	SendTell = function() end,
	SendTellWithMessage = function(name, text) sent[#sent + 1] = { text = text, prefill = true, target = name } end,
}

-- Menu API: runs the generator immediately and records the buttons.
local lastMenu
local function menuDescription()
	local d = { buttons = {} }
	function d:CreateTitle(t) self.title = self.title or t end
	function d:CreateDivider() end
	function d:CreateButton(text, fn)
		local b = menuDescription()
		b.text, b.fn = text, fn
		function b:SetTooltip(fn2) self.tooltip = fn2 end
		table.insert(self.buttons, b)
		return b
	end
	return d
end
_G.MenuUtil = { CreateContextMenu = function(_, gen) lastMenu = menuDescription() gen(nil, lastMenu) end }
_G.Settings = nil

-- LibSharedMedia mock: one foreign font, records our registrations
local lsmRegistered = {}
local LSM = {
	LOCALE_BIT_western = 1, LOCALE_BIT_ruRU = 2,
	Register = function(_, kind, name, path) lsmRegistered[name] = path end,
	List = function() return { "Expressway", "Philosopher" } end,
	Fetch = function(_, _, name) return name == "Expressway" and "Interface\\AddOns\\SharedMedia\\Expressway.ttf" or nil end,
}
_G.LibStub = setmetatable({}, { __call = function(_, name) if name == "LibSharedMedia-3.0" then return LSM end end })

-- Group Finder data: activities and results like in the beta screenshots
local ACT = {
	[11] = { fullName = "Höhlen des Wehklagens", shortName = "", categoryID = 2, maxNumPlayers = 5, minLevel = 15, minLevelSuggestion = 15, maxLevelSuggestion = 24, mapID = 43 },
	[12] = { fullName = "Burg Shadowfang", shortName = "", categoryID = 2, maxNumPlayers = 5, minLevel = 20, minLevelSuggestion = 20, maxLevelSuggestion = 30, mapID = 33 },
	[13] = { fullName = "Ruinen von Lordaeron", shortName = "", categoryID = 2, maxNumPlayers = 5, minLevel = 15, minLevelSuggestion = 15, maxLevelSuggestion = 22, mapID = 9999 },
}
local RESULTS = {
	[1] = { leaderName = "Alde Eisenfaust", numMembers = 4, activityIDs = { 11 }, generalPlaystyle = 2,
		members = { { "WARRIOR", 18, "TANK", true }, { "PALADIN", 21, "DAMAGER" }, { "PRIEST", 18, "HEALER" }, { "ROGUE", 24, "DAMAGER" } } },
	[2] = { leaderName = "Selune Selunar", numMembers = 3, activityIDs = { 11 }, generalPlaystyle = 3, newPlayerFriendly = true,
		members = { { "PRIEST", 22, "HEALER", true }, { "WARRIOR", 19, "TANK" }, { "DRUID", 22, "DAMAGER" } } },
	[3] = { leaderName = "Zwerg Naseweis", numMembers = 4, activityIDs = { 12 }, generalPlaystyle = 2,
		members = { { "PRIEST", 21, "HEALER", true }, { "MAGE", 22, "DAMAGER" }, { "WARLOCK", 22, "DAMAGER" }, { "ROGUE", 22, "DAMAGER" } } },
	[4] = { leaderName = "Chronos Temporalis", numMembers = 1, activityIDs = { 11 }, generalPlaystyle = 2,
		members = { { "DRUID", 15, nil, true, { dps = true } } } },
	[5] = { leaderName = "Imogshaarig Bär", numMembers = 1, activityIDs = { 11 }, generalPlaystyle = 2,
		members = { { "DRUID", 16, nil, true, { tank = true } } } },
	[7] = { leaderName = "Aldarin Schattentanz", numMembers = 1, activityIDs = { 11 }, generalPlaystyle = 4, newPlayerFriendly = true,
		members = { { "HUNTER", 26, nil, true, { dps = true } } } },
	[6] = { leaderName = "Nandhelia Mondklinge", numMembers = 1, activityIDs = { 11, 13 }, generalPlaystyle = 2,
		members = { { "WARRIOR", 19, nil, true, { dps = true } } } },
}
_G.C_LFGList = {
	GetSearchResultInfo = function(id)
		local r = RESULTS[id]
		if not r then return nil end
		return { searchResultID = id, leaderName = r.leaderName, numMembers = r.numMembers, activityIDs = r.activityIDs,
			generalPlaystyle = r.generalPlaystyle, newPlayerFriendly = r.newPlayerFriendly, hasSelf = false, isDelisted = false }
	end,
	GetSearchResultPlayerInfo = function(id, i)
		local m = RESULTS[id].members[i]
		if not m then return nil end
		return { classFilename = m[1], level = m[2], assignedRole = m[3] or "DAMAGER", isLeader = m[4], lfgRoles = m[5] or { dps = true }, name = "Member" .. i }
	end,
	GetActivityInfoTable = function(id) return ACT[id] end,
	GetActiveEntryInfo = function() return nil end,
	GetFilteredSearchResults = function() return 7, { 1, 2, 3, 4, 5, 6, 7 } end,
}

-- Fake Group Finder frames
local parent = newFrame("Frame", "LFGParentFrame")
parent.__size = { w = 458, h = 535 }
local browse = newFrame("Frame", "LFGBrowseFrame")
browse.RefreshButton = newFrame("Button")
browse.ScrollBox = newFrame("Frame")
browse.ScrollBar = newFrame("Frame")
browse.SendMessageButton = newFrame("Button")
browse.GroupInviteButton = newFrame("Button")
browse.ActivityDropdown = { selectedValues = {}, ValueIsSelected = function() return false end }
browse.CategoryDropdown = { GetValue = function() return 2 end, SetValue = function() end, HookScript = function() end }
browse.results = { 1, 2, 3, 4, 5, 6, 7 }
browse.totalResults = 7
browse.searching = false
browse.UpdateResults = function() end
browse.UpdateButtonState = function() end
browse.CreateSearchEntryMenu = function() end
browse.selectionBehavior = { HasSelection = function() return false end }

-------------------------------------------------------------------------------
-- Load the addon in TOC order
-------------------------------------------------------------------------------

local ns = {}
for line in io.lines("BetterGroupFinder.toc") do
	local file = line:match("^([%w_\\/]+%.lua)%s*$")
	if file then
		local path = file:gsub("\\", "/")
		local chunk, err = loadfile(path)
		check("load " .. path, chunk ~= nil, err)
		if chunk then
			local ok, runErr = pcall(chunk, "BetterGroupFinder", ns)
			check("run " .. path, ok, runErr)
		end
	end
end

local function fire(event, ...)
	for f, events in pairs(eventFrames) do
		if events[event] and f.__scripts.OnEvent then f.__scripts.OnEvent(f, event, ...) end
	end
end

print("Events")
local ok, err = pcall(fire, "ADDON_LOADED", "BetterGroupFinder")
check("ADDON_LOADED creates the saved variables and attaches the UI", ok and BetterGroupFinderDB ~= nil and ns.UI.attached, err)
ok, err = pcall(fire, "PLAYER_LOGIN")
check("PLAYER_LOGIN builds the options", ok, err)

print("List")
ok, err = pcall(ns.UI.Refresh)
check("refresh without errors", ok, err)
local sections = ns.List.sections
check("sections built", sections and sections.total == 7, sections and sections.total)
local frames = ns.List.scrollBox.__frames or {}
check("rows and headers rendered", #frames >= 5, #frames)
check("Blizzard list hidden while BGF active", browse.ScrollBox.__shown == false)
for _, e in ipairs(sections.groups) do print(("      group  %-18s score %s"):format(e.info.leaderName, e.result.score)) end
for _, e in ipairs(sections.players) do print(("      player %-18s score %s"):format(e.info.leaderName, e.result.score)) end
for _, e in ipairs(sections.excluded) do print(("      out    %-18s %s"):format(e.info.leaderName, ns.FormatReason(e.result.excludeReason))) end
local excludedNames = {}
for _, e in ipairs(sections.excluded) do excludedNames[e.info.leaderName] = ns.FormatReason(e.result.excludeReason) end
check("Zwerg Naseweis (only a tank missing) is sorted out for a hunter", excludedNames["Zwerg Naseweis"] ~= nil, excludedNames["Zwerg Naseweis"])

-- real list width at the original window width: 458 - 7 - 24
ns.List.scrollBox.__size.w = 427
ns.UI.Refresh()
print("Columns at the original width (estimated 0.56 x font size per character, base 12 / names 14)")
local cols = ns.List.columns
print(("      text %d, style %d, slots %d, score %d"):format(cols.textW, cols.styleW, cols.slotsW, cols.scoreW))
local groupValueOK, soloValueOK = true, true
for _, fr in ipairs(ns.List.scrollBox.__frames) do
	if fr.entry then
		print(("      %-40s | %-24s | %-10s | %4s %s"):format(fr.Name.__text or "", fr.Activity.__text or "", fr.Style.__text or "",
			fr.Score.__text or "", fr.Value.__text or ""))
		if not fr.entry.excluded then
			if fr.entry.isSolo then
				if (fr.Value.__text or "") ~= "" then soloValueOK = false end
			elseif not (fr.Value.__text or ""):match("^%d+ %%$") then
				groupValueOK = false
			end
		end
	end
end
check("groups show their group value in percent", groupValueOK)
check("solo players show no group value", soloValueOK)

print("Filter bar and header buttons")
ok, err = pcall(ns.UI.filterButton.__scripts.OnClick)
check("filter button opens the bar", ok and ns.db.filterOpen and ns.FilterBar.frame.__shown, err)
check("filter button stays pressed while the bar is open", ns.UI.filterButton.pressed == true)
check("window grows in height by the bar", (parent.__size.h or 0) > 535, parent.__size.h)
check("window keeps its original width", (parent.__size.w or 458) == 458, parent.__size.w)
local chip = ns.FilterBar.frame.AbilityChips[3]
ok, err = pcall(chip.__scripts.OnClick, chip)
check("ability chip cycles state", ok and ns.db.abilityStates.dungeon[chip.ability] ~= ns.DEFAULT_ABILITY_STATES.dungeon[chip.ability], err)
local roleChip = ns.FilterBar.frame.RoleChips[1]
ok, err = pcall(roleChip.__scripts.OnClick, roleChip)
check("role chip switches to manual roles", ok and next(ns.db.roleChips) ~= nil, err)
ns.FilterBar.ResetFilters()
local enableBox = ns.FilterBar.frame.Enable
enableBox.__checked = false
ok, err = pcall(enableBox.__scripts.OnClick, enableBox)
check("unchecking 'BGF filter active' keeps the bar open", ok and ns.FilterBar.frame.__shown and ns.UI.filterButton.pressed, err)
check("... BGF list stays (Blizzard list never under the bar)", ns.List.scrollBox.__shown == true and browse.ScrollBox.__shown == false)
local unrated = ns.List.sections
check("... nothing rated or sorted out, Blizzard order", unrated and not unrated.rated and #unrated.excluded == 0
	and unrated.players[1] and unrated.players[1].resultID == 4, unrated and #unrated.excluded)
local anyScore = false
for _, fr in ipairs(ns.List.scrollBox.__frames) do if fr.Score and (fr.Score.__text or "") ~= "" then anyScore = true end end
check("... no points shown", not anyScore)
check("... view row is gone", ns.FilterBar.frame.ViewNormal == nil and ns.FilterBar.frame.ViewCompact == nil)
enableBox.__checked = true
pcall(enableBox.__scripts.OnClick, enableBox)
check("re-checking rates again", ns.List.sections.rated == true and ns.List.scrollBox.__shown == true)
local druidChip, roleChip1
for _, c in ipairs(ns.FilterBar.frame.AbilityChips) do if c.ability == "class_DRUID" then druidChip = c end end
roleChip1 = ns.FilterBar.frame.RoleChips[1]
local tt = ns.FilterBar.AbilitySources("interrupt")
check("interrupt tooltip names spells, conditions and talents", tt[1].text:find("Schildhieb ab Stufe 12 (nur mit Schild)", 1, true)
	and tt[2].text:find("Zuschlagen ab Stufe 38", 1, true), tt[1] and tt[1].text)
local silence = false
for _, l in ipairs(tt) do
	print("      interrupt: " .. l.text)
	if l.text:find("Stille ab Stufe 30 (Talent)", 1, true) then silence = true end
end
check("... including Silence as a talent", silence)
tt = ns.FilterBar.AbilitySources("buff_mana")
check("mana chip: Paladin 14, Schamane talent 25 + totem 26", #tt == 3 and tt[1].text:find("Segen der Weisheit ab Stufe 14", 1, true)
	and tt[2].text:find("Totem der Manaflut ab Stufe 25 (Talent)", 1, true) and tt[3].text:find("Totem der Manaquelle ab Stufe 26", 1, true),
	tt[1] and tt[1].text)
tt = ns.FilterBar.ClassSources("DRUID")
for _, l in ipairs(tt) do print("      Druide: " .. l.text) end
check("class tooltip groups what the class brings", tt[1].text:find("^Kontrolle: Wucherwurzeln ab Stufe 8, Winterschlaf ab Stufe 18 %(nur Wildtiere/Drachkin%)")
	and tt[#tt].text == "Buffs: Mal der Wildnis ab Stufe 1", tt[1] and tt[1].text)
tt = ns.FilterBar.ClassSources("WARLOCK")
local util = tt[#tt].text
check("warlock tooltip lists healthstones and summoning under utility", util == "Sonstiges: Gesundheitsstein herstellen ab Stufe 10, Ritual der Beschwörung ab Stufe 20", util)
tt = ns.FilterBar.ClassSources("PALADIN")
local kings = false
for _, l in ipairs(tt) do if l.text:find("Buffs: Segen der Könige ab Stufe 20, Segen der Rettung ab Stufe 26", 1, true) then kings = true end end
check("paladin tooltip has Kings and Salvation", kings)
tt = ns.FilterBar.ClassSources("PRIEST")
check("priest tooltip: Seelenstärke, Furchtzauberschutz, Göttlicher Willen", tt[#tt].text ==
	"Buffs: Machtwort: Seelenstärke ab Stufe 1, Furchtzauberschutz ab Stufe 20, Göttlicher Willen ab Stufe 30", tt[#tt].text)
check("class chips are named after the class", ns.AbilityName("class_WARLOCK") == "Hexenmeister" and ns.AbilityName("class_DRUID") == "Druide"
	and ns.AbilityName("buff_mana") == "Mana")
_G.C_Spell = { GetSpellName = function(id) if id == 6673 then return "Schlachtruf (Spiel)" end end }
check("spell names come from the game when it knows the ID", ns.SpellName("battle_shout") == "Schlachtruf (Spiel)"
	and ns.SpellName("pummel") == "Zuschlagen")
_G.C_Spell = nil
ok, err = pcall(function() druidChip.__scripts.OnEnter(druidChip) druidChip.__scripts.OnLeave(druidChip) end)
check("class chip tooltip shows and hides", ok, err)
ok, err = pcall(function() roleChip1.__scripts.OnEnter(roleChip1) roleChip1.__scripts.OnLeave(roleChip1) end)
check("role chip tooltip shows and hides", ok, err)
check("no profile display and no grey role hint any more", ns.FilterBar.frame.ProfileValue == nil and ns.FilterBar.frame.RolesHint == nil)
pcall(ns.UI.filterButton.__scripts.OnClick)
check("closing the bar restores the original height", parent.__size.h == 535 and not ns.UI.filterButton.pressed, parent.__size.h)

print("Fonts and '+ more'")
check("shipped fonts are registered in LibSharedMedia", lsmRegistered["Philosopher"] ~= nil and lsmRegistered["PT Sans Narrow"] ~= nil)
local fontNames = {}
for _, f in ipairs(ns.Fonts.List()) do fontNames[f.name] = f.key end
check("font list has game, shipped and LibSharedMedia fonts", fontNames["Friz Quadrata"] and fontNames["Roboto Condensed"] and fontNames["Expressway"], "")
check("default font is the game font", ns.db.font == "friz" and ns.Fonts.Path() == "Fonts\\FRIZQT__.TTF", ns.Fonts.Path())
ok, err = pcall(ns.Fonts.Set, fontNames["Expressway"])
check("switching to a LibSharedMedia font", ok and ns.Fonts.Path():find("Expressway", 1, true) ~= nil, err or ns.Fonts.Path())
ok, err = pcall(ns.Fonts.Set, "philosopher")
check("switching to Philosopher", ok and ns.Fonts.Path():find("Philosopher", 1, true) ~= nil, err)
ns.clientLocale = "koKR"
check("Korean client always uses the game font", ns.Fonts.Path() == "Fonts\\FRIZQT__.TTF", ns.Fonts.Path())
ns.clientLocale = "deDE"
ns.Fonts.Set("friz")
ns.db.filterOpen = false
pcall(ns.UI.filterButton.__scripts.OnClick)
local f = ns.FilterBar.frame
local function shownGroups()
	local count = { core = 0, more = 0, class = 0 }
	for _, c in ipairs(f.AbilityChips) do
		if c.__shown then local g = ns.ABILITY_BY_ID[c.ability].group count[g] = count[g] + 1 end
	end
	return count
end
local v = shownGroups()
check("only the 5 main abilities are visible", v.core == 5 and v.more == 0 and v.class == 0, v.core .. "/" .. v.more .. "/" .. v.class)
check("toggle chips '+ mehr' and '+ Klassen'", f.More.label == "+ mehr" and f.Classes.label == "+ Klassen", f.Classes.label)
local profile = ns.FilterBar.CurrentProfile()
ns.db.abilityStates[profile].class_DRUID = "pref"
ns.db.abilityStates[profile].curse = "need"
ns.UI.ApplyLayout()
v = shownGroups()
check("collapsed groups stay hidden even when active (variant B)", v.more == 0 and v.class == 0, v.more .. "/" .. v.class)
check("... the toggle chip counts active chips", f.Classes.label == "+ Klassen (1)" and f.More.label == "+ mehr (1)", f.Classes.label .. " | " .. f.More.label)
pcall(f.Classes.__scripts.OnClick, f.Classes)
v = shownGroups()
check("'+ Klassen' shows all 9 class chips", v.class == 9 and ns.db.showClasses == true and f.Classes.label == "- Klassen", v.class)
pcall(f.More.__scripts.OnClick, f.More)
v = shownGroups()
check("'+ mehr' shows the 4 removal chips", v.more == 4 and f.More.label == "- weniger", v.more)
pcall(f.More.__scripts.OnClick, f.More)
pcall(f.Classes.__scripts.OnClick, f.Classes)
ns.db.abilityStates[profile].class_DRUID = "ignore"
ns.db.abilityStates[profile].curse = "ignore"
pcall(ns.UI.filterButton.__scripts.OnClick)

print("Request button")
local row
for _, fr in ipairs(ns.List.scrollBox.__frames) do
	if fr.entry and fr.entry.info.leaderName == "Selune Selunar" then row = fr end
end
check("row for Selune Selunar exists", row ~= nil)
ok, err = pcall(row.OnClick, row, "LeftButton")
check("clicking a row selects it", ok and ns.List.selectedID == 2, err)
ok, err = pcall(ns.UI.requestButton.__scripts.OnClick, ns.UI.requestButton)
check("request menu opens", ok and lastMenu ~= nil, err)
check("menu title names the leader", lastMenu and lastMenu.title and lastMenu.title:find("Selune", 1, true) ~= nil, lastMenu and lastMenu.title)
check("menu title is white", lastMenu.title:find("|cffffffff", 1, true) == 1, lastMenu.title)
check("menu has German + English templates only (4 + empty whisper + edit)", #lastMenu.buttons == 6, #lastMenu.buttons)
print("      menu: " .. lastMenu.title .. " | " .. lastMenu.buttons[1].text .. " | " .. lastMenu.buttons[2].text .. " | " .. lastMenu.buttons[3].text)
local first = lastMenu.buttons[1]
ok, err = pcall(first.fn)
local msg = sent[#sent]
check("template is sent as whisper automatically", ok and msg and msg.type == "WHISPER" and not msg.prefill, err)
check("placeholders filled (class, role, level, instance)", msg and msg.text:find("Jäger", 1, true) and msg.text:find("DPS", 1, true)
	and msg.text:find("22", 1, true) and msg.text:find("Höhlen des Wehklagens", 1, true) and not msg.text:find("{", 1, true), msg and msg.text)
print("      -> " .. (msg and msg.text or "?"))
ns.db.templateNames.deDE = { join_friendly = "Locker" }
ns.UI.requestButton.__scripts.OnClick(ns.UI.requestButton)
check("custom template name appears in the menu", lastMenu.buttons[1].text:find("Locker", 1, true) ~= nil, lastMenu.buttons[1].text)
ns.db.templateNames.deDE = nil
local english = lastMenu.buttons[3]
ok, err = pcall(english.fn)
msg = sent[#sent]
check("English fallback templates are offered", ok and msg and msg.text:find("Hunter", 1, true) ~= nil, msg and msg.text)
print("      -> " .. (msg and msg.text or "?"))

-- Lockdown: message goes to the chat box instead
C_ChatInfo.InChatMessagingLockdown = function() return true end
pcall(first.fn)
check("during chat lockdown the text is prefilled instead of sent", sent[#sent].prefill == true)
C_ChatInfo.InChatMessagingLockdown = function() return false end

-- Invite a solo player as group leader
inGroup = true
ns.UI.Refresh()
local bear
for _, fr in ipairs(ns.List.scrollBox.__frames) do
	if fr.entry and fr.entry.info.leaderName == "Imogshaarig Bär" then bear = fr end
end
if bear then
	bear:OnClick("LeftButton")
	ns.UI.requestButton.__scripts.OnClick(ns.UI.requestButton)
	pcall(lastMenu.buttons[1].fn)
	check("inviting a solo player invites and whispers", invited[#invited] == "Imogshaarig Bär" and sent[#sent].text:find("Imogshaarig", 1, true) ~= nil, sent[#sent].text)
	print("      -> " .. sent[#sent].text)
else
	check("solo tank listed for your group", false, "not in visible rows")
end

print("Tooltip and toggles")
ok, err = pcall(function() row:OnEnter() row:OnLeave() end)
check("tooltip shows and hides", ok, err)
check("no font size setting any more", ns.db.fontSize == nil and ns.db.compact == nil)
ns.db.showScores = false
ns.UI.Refresh()
anyScore = false
for _, fr in ipairs(ns.List.scrollBox.__frames) do if fr.Score and (fr.Score.__text or "") ~= "" then anyScore = true end end
check("option 'show points' off hides all points", not anyScore and ns.List.sections.rated == true)
ns.db.showScores = true
local helpWin
ok, helpWin = pcall(ns.Options.ShowScoreHelp)
check("points explanation window opens", ok and helpWin, helpWin)
if ok and helpWin then
	local headers, weights, plusRows = 0, 0, 0
	for _, item in ipairs(helpWin.Items) do
		if item.kind == "header" then headers = headers + 1 end
		if item.kind == "row" and item.tag == "weights" and item.value ~= "" then weights = weights + 1 end
		if item.kind == "row" and item.tag == "plus" then plusRows = plusRows + 1 end
	end
	check("... with 7 sections, 5 generated weight rows (classes in one row) and plus rows", headers == 7 and weights == 5 and plusRows == 5,
		headers .. "/" .. weights .. "/" .. plusRows)
	for _, item in ipairs(helpWin.Items) do
		if item.tag == "weights" and item.kind == "row" then print(("      %3s | %s"):format(item.value, item.text)) end
	end
end
ok, err = pcall(SlashCmdList.BETTERGROUPFINDER, "off")
check("/bgf off shows Blizzard's list again", ok and browse.ScrollBox.__shown == true and ns.List.scrollBox.__shown == false, err)
check("... and hides filter bar and filter button", ns.FilterBar.frame.__shown == false and ns.UI.filterButton.__shown == false)
ok, err = pcall(SlashCmdList.BETTERGROUPFINDER, "on")
check("/bgf on switches back", ok and ns.List.scrollBox.__shown == true and ns.UI.filterButton.__shown == true, err)
ok, err = pcall(SlashCmdList.BETTERGROUPFINDER, "debug")
check("/bgf debug", ok, err)
ok, err = pcall(SlashCmdList.BETTERGROUPFINDER, "")
check("/bgf opens options", ok, err)

print(failures == 0 and "\nall smoke checks passed" or ("\n" .. failures .. " smoke checks failed"))
os.exit(failures == 0 and 0 or 1)
