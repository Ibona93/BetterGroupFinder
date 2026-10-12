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
	if key == "SetPoint" then return function(s, ...) s.__point = { ... } end end
	if key == "SetAlpha" then return function(s, a) s.__alpha = a end end
	if key == "GetPoint" then return function(s) if s.__point then return unpack(s.__point) end end end
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
local specialFrameInserts = 0
_G.tinsert = function(t, ...) if t == _G.UISpecialFrames then specialFrameInserts = specialFrameInserts + 1 end return table.insert(t, ...) end
_G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
local hookedBlizzard = {}
_G.hooksecurefunc = function(tbl, name, fn)
	if type(tbl) == "table" then hookedBlizzard[#hookedBlizzard + 1] = tostring(name) end
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
local categoryValue = 2
browse.CategoryDropdown = { GetValue = function() return categoryValue end, SetValue = function() end, HookScript = function() end }
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
-- "What's new": new users get the welcome page at login, once; not on instance loading screens
ok, err = pcall(fire, "PLAYER_ENTERING_WORLD", true, false)
local newsWin = _G.BGFWhatsNew or (ns.WhatsNew and ns.WhatsNew.ShowPage and nil)
check("login shows the welcome page for new users", ok and ns.db.lastSeenVersion == ns.VERSION, err)
local shownPage = newsWin and newsWin.version
check("... page 0.8.0 (welcome)", shownPage == "0.8.0", tostring(shownPage))
if newsWin then newsWin:Hide() end
ok, err = pcall(fire, "PLAYER_ENTERING_WORLD", false, false)
check("instance loading screen shows nothing", ok and not (newsWin and newsWin.__shown), err)
-- after an update: page of the current version, unless switched off
ns.isNewInstall = false
ns.db.lastSeenVersion = "0.8.2"
pcall(fire, "PLAYER_ENTERING_WORLD", true, false)
check("after an update the current version's page is shown", newsWin and newsWin.__shown and newsWin.version == ns.VERSION,
	newsWin and newsWin.version)
newsWin:Hide()
ns.db.lastSeenVersion, ns.db.showWhatsNew = "0.8.2", false
pcall(fire, "PLAYER_ENTERING_WORLD", false, true)
check("switched off: nothing after the next update", not newsWin.__shown and ns.db.lastSeenVersion == ns.VERSION)
ns.db.showWhatsNew = true
ok, err = pcall(ns.WhatsNew.OpenVersionMenu, newsWin.Badge)
local vmenu = ns.Popup.current
check("version badge lists all releases", ok and vmenu and #vmenu == 1 + #ns.NEWS_ORDER, err)
if vmenu then vmenu[#vmenu].fn() end
ns.Popup.Close()
check("choosing a version shows its page", newsWin.version == "0.8.0" and newsWin.__shown)
local deOK, enOK = true, true
for _, v in ipairs(ns.NEWS_ORDER) do
	local p = ns.NEWS[v]
	if not (p and p.deDE and p.enUS and #p.deDE.items == #p.enUS.items) then deOK = false end
end
check("every release page exists in German and English", deOK and enOK)
newsWin:Hide()

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
			if (fr.Value.__text or "") ~= "" then
				if fr.entry.isSolo then soloValueOK = false else groupValueOK = false end
			end
			if (fr.Score.__text or ""):find("+", 1, true) then groupValueOK = false end
		end
	end
end
check("list shows the points without + and no group value (moved to the tooltip)", groupValueOK)
check("solo players show no group value", soloValueOK)

check("no hooks on Blizzard functions (taint log safe)", #hookedBlizzard == 0, table.concat(hookedBlizzard, ","))
do
	local refreshed = false
	local orig = ns.UI.Refresh
	ns.UI.Refresh = function() refreshed = true end
	fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
	ns.UI.Refresh = orig
	check("search results event refreshes the BGF list", refreshed)
end
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
local function plain(t) return (t or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
local function linesOf(list)
	local out = {}
	for i, l in ipairs(list) do out[i] = l.header and ("# " .. l.header) or plain(l.text) end
	return out
end
local tt = linesOf(ns.FilterBar.AbilitySources("interrupt"))
check("interrupt tooltip: class, spell, level, condition", tt[1] == "Krieger  Schildhieb  ab Stufe 12  nur mit Schild"
	and tt[2] == "Krieger  Zuschlagen  ab Stufe 38", tt[1])
local silence = false
for _, l in ipairs(tt) do
	print("      interrupt: " .. l)
	if l == "Priester  Stille  ab Stufe 30  Talent" then silence = true end
end
check("... including Silence as a talent", silence)
local raw = ns.FilterBar.AbilitySources("interrupt")[1].text
check("... coloured: name white, level grey, condition orange", raw:find("|cffffffffSchildhieb|r", 1, true) and raw:find("|cff9d9d9dab Stufe 12|r", 1, true)
	and raw:find("|cffff9933nur mit Schild|r", 1, true), raw)
tt = linesOf(ns.FilterBar.AbilitySources("buff_mana"))
check("mana chip with effects", #tt == 3 and tt[1] == "Paladin  Segen der Weisheit  ab Stufe 14  · Manaregeneration +"
	and tt[2] == "Schamane  Totem der Manaflut  ab Stufe 25  Talent  · Mana + (kurzzeitig)", tt[2])
tt = linesOf(ns.FilterBar.ClassSources("DRUID"))
for _, l in ipairs(tt) do print("      Druide: " .. l) end
check("druid tooltip in sections, one spell per line", tt[1] == "# Kampf & Hilfsmittel" and tt[2] == "  Wucherwurzeln  ab Stufe 8  – Kontrolle"
	and tt[3] == "  Hieb  ab Stufe 14  Bärform  – Unterbrechen" and tt[7] == "# Dispells" and tt[8] == "  Vergiftung heilen  ab Stufe 14  – Gift"
	and tt[10] == "# Buffs" and tt[11] == "  Mal der Wildnis  ab Stufe 1  · Rüstung, Werte, Widerstände +", table.concat(tt, " | "))
tt = linesOf(ns.FilterBar.ClassSources("WARLOCK"))
local hs, sum = false, false
for _, l in ipairs(tt) do
	if l == "  Gesundheitsstein herstellen  ab Stufe 10  · Gesundheitssteine für die Gruppe" then hs = true end
	if l == "  Ritual der Beschwörung  ab Stufe 20  · Mitspieler herbeirufen" then sum = true end
end
check("warlock tooltip: healthstones and summoning with effect", hs and sum)
tt = linesOf(ns.FilterBar.ClassSources("PALADIN"))
local purify, kings = false, false
for _, l in ipairs(tt) do
	print("      Paladin: " .. l)
	if l == "  Läutern  ab Stufe 8  – Gift, Krankheit" then purify = true end
	if l == "  Segen der Könige  ab Stufe 20  · Alle Werte +10 %" then kings = true end
end
check("paladin: Purify once for poison and disease, Kings with effect", purify and kings)
check("links text: druid selects Mark of the Wild", plain(ns.FilterBar.LinksText("class_DRUID")) == "Wählt mit aus: Mal der Wildnis"
	and plain(ns.FilterBar.LinksText("buff_stamina")) == "Wählt mit aus: Priester")
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
local sure, maybe = ns.FilterBar.AbilityShort("interrupt")
local function joined(t) local o = {} for i, v in ipairs(t) do o[i] = plain(v) end return table.concat(o, ", ") end
check("short interrupt tooltip: sure classes and 'maybe' classes", joined(sure) == "Krieger, Paladin, Schurke, Schamane, Magier"
	and joined(maybe) == "Priester, Hexenmeister, Druide", joined(sure) .. " / " .. joined(maybe))
local short = {}
for i, l in ipairs(ns.FilterBar.ClassShort("PALADIN")) do short[i] = plain(l) end
check("short paladin tooltip: one line per section", #short == 3 and short[1] == "Kampf & Hilfsmittel: Kontrolle, Unterbrechen"
	and short[2]:find("Gift", 1, true) and short[3]:find("Segen der Könige", 1, true), table.concat(short, " | "))
local interruptChip
for _, c in ipairs(ns.FilterBar.frame.AbilityChips) do if c.ability == "interrupt" then interruptChip = c end end
_G.IsShiftKeyDown = function() return true end
ok, err = pcall(function() interruptChip.__scripts.OnEnter(interruptChip) interruptChip.__scripts.OnLeave(interruptChip) end)
check("chip tooltip with Shift held (details) shows and hides", ok, err)
_G.IsShiftKeyDown = function() return false end
ok, err = pcall(function() interruptChip.__scripts.OnEnter(interruptChip) interruptChip.__scripts.OnLeave(interruptChip) end)
check("chip tooltip without Shift (short) shows and hides", ok, err)
_G.IsShiftKeyDown = nil
check("score colours by verdict, quests neutral", ns.ScoreColor({ verdict = "VERDICT_GOOD" })[1] < 0.5
	and ns.ScoreColor({ verdict = "VERDICT_OK" })[2] == 0.82 and ns.ScoreColor({ verdict = "VERDICT_LOW", relaxed = true }) == ns.SCORE_COLORS.neutral)
-- own defaults: Save, change, Reset -> back to the saved chips; restore built-in -> defaults again
ns.FilterBar.ResetFilters()
ns.db.abilityStates.dungeon.buff_ap = "need"
ns.FilterBar.SaveCurrent()
ns.db.abilityStates.dungeon.buff_ap = "ignore"
ns.db.abilityStates.dungeon.cc = "ignore"
ns.FilterBar.ResetCurrent()
check("Reset goes back to the saved own default", ns.db.abilityStates.dungeon.buff_ap == "need"
	and ns.db.abilityStates.dungeon.cc == ns.DEFAULT_ABILITY_STATES.dungeon.cc)
ns.db.abilityStates.raid.cc = "ignore"
ns.FilterBar.ResetFilters()
check("Reset filters keeps own defaults per category", ns.db.abilityStates.dungeon.buff_ap == "need"
	and ns.db.abilityStates.raid.cc == ns.DEFAULT_ABILITY_STATES.raid.cc)
ns.FilterBar.RestoreBuiltIn()
check("restoring built-in defaults drops the own ones", next(ns.db.userDefaults) == nil
	and ns.db.abilityStates.dungeon.buff_ap == ns.DEFAULT_ABILITY_STATES.dungeon.buff_ap)
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
check("each font key gets its own font object (font menu entries)", ns.Fonts.GetFor("morpheus", 12) ~= ns.Fonts.GetFor("friz", 12)
	and ns.Fonts.GetFor("morpheus", 12).__fontSize == 12)
ns.clientLocale = "koKR"
check("Korean client always uses the game font", ns.Fonts.Path() == "Fonts\\FRIZQT__.TTF", ns.Fonts.Path())
ns.clientLocale = "deDE"
ns.Fonts.Set("friz")
ns.db.filterOpen = false
pcall(ns.UI.filterButton.__scripts.OnClick)
local f = ns.FilterBar.frame
local function shownByCategory()
	local count = { class = 0, buff = 0, dispel = 0, combat = 0, loot = 0 }
	for _, c in ipairs(f.AbilityChips) do
		if c.__shown then local g = ns.ABILITY_BY_ID[c.ability].category count[g] = count[g] + 1 end
	end
	return count
end
local function shownFavorites()
	local n = 0
	for _, c in pairs(f.FavChips) do if c.__shown then n = n + 1 end end
	return n
end
local v = shownByCategory()
check("all categories closed: no category chips, 6 default favourites (incl. loot)", v.class + v.buff + v.dispel + v.combat == 0 and shownFavorites() == 6,
	shownFavorites())
check("loot chip stands directly in the abilities row (no '+ Loot' toggle)", v.loot == 1 and not f.CategoryToggles.loot.__shown)
check("category toggles", f.CategoryToggles.class.label == "+ Klassen" and f.CategoryToggles.buff.label == "+ Buffs"
	and f.CategoryToggles.dispel.label == "+ Dispells" and f.CategoryToggles.combat.label == "+ Kampf & Hilfsmittel (2)", f.CategoryToggles.combat.label)
local profile = ns.FilterBar.CurrentProfile()
-- link: warrior required -> attack power required (teal border)
local warrior, ap
for _, c in ipairs(f.AbilityChips) do
	if c.ability == "class_WARRIOR" then warrior = c end
	if c.ability == "buff_ap" then ap = c end
end
warrior.__scripts.OnClick(warrior, "LeftButton")
warrior.__scripts.OnClick(warrior, "LeftButton")
check("warrior 'required' selects attack power along", ns.db.abilityStates[profile].class_WARRIOR == "need" and ap.state == "need" and ap.linked == "class_WARRIOR"
	and f.FavChips.buff_ap.linked == "class_WARRIOR", tostring(ap.state))
check("... counters on closed categories", f.CategoryToggles.class.label == "+ Klassen (1)" and f.CategoryToggles.buff.label == "+ Buffs (1)",
	f.CategoryToggles.buff.label)
ap.__scripts.OnClick(ap, "LeftButton")
check("clicking the linked chip switches it off despite the warrior", ap.state == "ignore" and ap.overridden == "class_WARRIOR"
	and ns.db.abilityStates[profile].class_WARRIOR == "need")
check("... shown struck through, also in the favourites row", ap.Strike.__shown and f.FavChips.buff_ap.Strike.__shown)
warrior.__scripts.OnClick(warrior, "LeftButton")
check("warrior off: the override ends", next(ns.db.linkOverrides[profile]) == nil and ap.state == "ignore" and not ap.Strike.__shown)
-- opening categories: each open category in its own rows
pcall(f.CategoryToggles.buff.__scripts.OnClick, f.CategoryToggles.buff)
v = shownByCategory()
check("'+ Buffs' shows the 9 buffs", v.buff == 9 and f.CategoryToggles.buff.label == "- Buffs", v.buff)
check("open category toggle is gold, closed ones stay grey", f.CategoryToggles.buff.state == "open" and f.CategoryToggles.class.state == "more")
local _, _, buffY = f.CategoryToggles.buff:GetPoint()
local _, _, classY = f.CategoryToggles.class:GetPoint()
local _, _, dispelY = f.CategoryToggles.dispel:GetPoint()
check("open category starts a new row and the next category another one", buffY and classY and dispelY and buffY < classY and dispelY < buffY,
	tostring(classY) .. "/" .. tostring(buffY) .. "/" .. tostring(dispelY))
pcall(f.CategoryToggles.class.__scripts.OnClick, f.CategoryToggles.class)
v = shownByCategory()
check("several categories can be open", v.class == 9 and v.buff == 9, v.class)
pcall(f.CategoryToggles.class.__scripts.OnClick, f.CategoryToggles.class)
pcall(f.CategoryToggles.buff.__scripts.OnClick, f.CategoryToggles.buff)
-- chip positions are recalculated when states (and so widths) change, e.g. after a category change
do
	local function overlaps()
		local list = {}
		for _, c in pairs(f.FavChips) do if c.__shown and c.__point then list[#list + 1] = c end end
		for _, a in ipairs(list) do
			for _, b in ipairs(list) do
				if a ~= b and a.__point[3] == b.__point[3] then
					local ax, bx = a.__point[2], b.__point[2]
					if ax < bx and ax + a.__size.w > bx then return true end
				end
			end
		end
		return false
	end
	categoryValue = 4 -- Quests & zones: cc/interrupt without markers -> narrower chips
	ns.UI.Refresh()
	local q = overlaps()
	categoryValue = 2
	ns.UI.Refresh()
	check("chip rows are laid out again after a category change (no overlap, no gaps)", not q and not overlaps())
	categoryValue = 0
	ns.UI.Refresh()
	check("no category chosen: hint instead of the list", ns.List.hint == "Wähle oben links eine Kategorie, z. B. Dungeons.")
	categoryValue = 2
	ns.UI.Refresh()
	check("... and the list comes back with a category", ns.List.hint == nil and ns.List.sections ~= nil)
end
-- reset in the filter bar: only the shown category
ns.db.abilityStates[profile].class_MAGE = "need"
ns.db.abilityStates.other.class_MAGE = "pref"
ns.db.roleChips = { DAMAGER = true }
f.Reset.__scripts.OnClick(f.Reset)
check("filter bar reset: shown category and roles reset, other categories kept", ns.db.abilityStates[profile].class_MAGE == "ignore"
	and ns.db.abilityStates.other.class_MAGE == "pref" and next(ns.db.roleChips) == nil and ns.db.favorites.cc == true)
ns.db.abilityStates.other.class_MAGE = "ignore"
ok, err = pcall(function() f.Reset.__scripts.OnEnter(f.Reset) f.Reset.__scripts.OnLeave(f.Reset) end)
check("reset tooltip", ok, err)
-- favourites by right click
local summonFav = f.FavChips.summon
local summon
for _, c in ipairs(f.AbilityChips) do if c.ability == "summon" then summon = c end end
summon.__scripts.OnClick(summon, "RightButton")
check("right click adds a favourite (star on the chip, shown in the favourites row)", ns.db.favorites.summon == true and summonFav.__shown
	and summon.favorite and shownFavorites() == 7)
summonFav.__scripts.OnClick(summonFav, "LeftButton")
check("favourite and original are the same chip", summon.state == "pref" and ns.db.abilityStates[profile].summon == "pref")
-- loot competition chip: label shows for whom, Shift-click opens the member menu
local lootChip = f.FavChips.loot
check("loot chip is a default favourite and shows for whom it checks", lootChip.__shown and plain(lootChip.label) == "Loot (ich)", lootChip.label)
ok, err = pcall(function() lootChip.__scripts.OnEnter(lootChip) lootChip.__scripts.OnLeave(lootChip) end)
check("loot chip tooltip shows and hides", ok, err)
local hunterSure, hunterMaybe = ns.FilterBar.LootClasses({ class = "HUNTER", level = 23, role = "DAMAGER" })
local hs = {} for i, v in ipairs(hunterSure) do hs[i] = plain(v) end
check("hunter 23 competes with hunters, rogues and feral druids (leather, agility)", table.concat(hs, ", ") == "Jäger, Schurke, Druide"
	and #hunterMaybe == 1, table.concat(hs, ", ") .. " / " .. #hunterMaybe)
_G.IsShiftKeyDown = function() return true end
ok, err = pcall(lootChip.__scripts.OnClick, lootChip, "LeftButton")
_G.IsShiftKeyDown = nil
local lootMenu = ns.Popup.current
check("Shift-click on the loot chip opens the member menu instead of cycling", ok and lootMenu and lootMenu[2] and lootMenu[2].checked == true
	and (ns.db.abilityStates[profile].loot or "ignore") == "ignore", err)
if lootMenu and lootMenu[2] then lootMenu[2].fn() end
ns.Popup.Close()
check("unticking yourself: chip shows 'nobody'", ns.db.lootFor["@self"] == false and plain(f.FavChips.loot.label) == "Loot (niemand)", f.FavChips.loot.label)
ns.db.lootFor = {}
-- options "Shown chips": window, hidden rows and categories
local chipsPage = ns.Options.Pages.chips
check("Filter & Chips page has the checks (filter active, rows, categories, chips)", chipsPage and #chipsPage.Checks == 1 + 2 + 4 + 27 + 1,
	chipsPage and #chipsPage.Checks)
ok, err = pcall(chipsPage.Refresh)
check("... refresh without errors", ok, err)
ns.db.showFavRow = false
ns.UI.ApplyLayout()
check("favourites row can be hidden", shownFavorites() == 0 and not f.FavLabel.__shown)
ns.db.showFavRow = true
ns.db.hiddenCategories.class = true
ns.UI.ApplyLayout()
check("hidden category: its toggle chip is gone", not f.CategoryToggles.class.__shown and f.CategoryToggles.buff.__shown)
ns.db.showAbilityRow = false
ns.UI.ApplyLayout()
check("abilities row can be hidden", not f.CategoryToggles.buff.__shown and not f.AbilitiesLabel.__shown)
ns.db.showAbilityRow = true
ns.db.hiddenCategories = {}
ns.UI.ApplyLayout()
do
	ns.UI.Refresh()
	local players = ns.List.sections.players
	local mine = ns.Engine.GetMySide()[1].class
	local last, cls
	for i = #players, 2, -1 do
		local c = players[i].members and players[i].members[1] and players[i].members[1].class
		if c and c ~= mine and c ~= players[1].members[1].class then last, cls = players[i], c break end
	end
	ns.db.abilityStates[profile]["class_" .. tostring(cls)] = "need"
	ns.UI.Refresh()
	local first = ns.List.sections.players[1]
	check("entries that bring everything required come first", cls and first and first.resultID == last.resultID,
		tostring(cls) .. " " .. tostring(first and first.info.leaderName))
	ns.db.abilityStates[profile]["class_" .. tostring(cls)] = "ignore"
	ns.UI.Refresh()
end
check("summoning selects the warlock (only class with it)", ns.Engine.ProfileStates(profile).class_WARLOCK == "pref")
summonFav.__scripts.OnClick(summonFav, "LeftButton")
summonFav.__scripts.OnClick(summonFav, "LeftButton")
summon.__scripts.OnClick(summon, "RightButton")
check("right click again removes it (stored as false)", ns.db.favorites.summon == false and not summonFav.__shown)
pcall(ns.UI.filterButton.__scripts.OnClick)

print("Request button")
local row
for _, fr in ipairs(ns.List.scrollBox.__frames) do
	if fr.entry and fr.entry.info.leaderName == "Selune Selunar" then row = fr end
end
check("row for Selune Selunar exists", row ~= nil)
ok, err = pcall(row.OnClick, row, "LeftButton")
check("clicking a row selects it", ok and ns.List.selectedID == 2, err)
-- The template menu is BGF's own popup now (UI/Popup.lua); read its items like a menu.
local function openTemplateMenu()
	ns.Popup.Close()
	local okOpen, errOpen = pcall(ns.UI.requestButton.__scripts.OnClick, ns.UI.requestButton)
	local items = ns.Popup.current
	if not items then lastMenu = nil return okOpen, errOpen end
	lastMenu = { title = items[1].text, buttons = {}, items = items }
	for _, item in ipairs(items) do
		if item.kind == "button" then lastMenu.buttons[#lastMenu.buttons + 1] = { text = item.text, fn = item.fn, tooltip = item.tooltip } end
	end
	return okOpen, errOpen
end
ok, err = openTemplateMenu()
check("request menu opens", ok and lastMenu ~= nil, err)
check("menu title names the leader", lastMenu and lastMenu.title and lastMenu.title:find("Selune", 1, true) ~= nil, lastMenu and lastMenu.title)
check("menu title is white", lastMenu.title:find("|cffffffff", 1, true) == 1, lastMenu.title)
check("menu has German + English templates only (4 + empty whisper + edit)", #lastMenu.buttons == 6, #lastMenu.buttons)
check("menu is BGF's own popup, not Blizzard's menu system", ns.Popup.current ~= nil and lastMenu.items[3].kind == "header")
ok, err = pcall(lastMenu.buttons[1].tooltip, GameTooltip)
check("template preview tooltip works", ok, err)
print("      menu: " .. lastMenu.title .. " | " .. lastMenu.buttons[1].text .. " | " .. lastMenu.buttons[2].text .. " | " .. lastMenu.buttons[3].text)
local first = lastMenu.buttons[1]
ok, err = pcall(first.fn)
local msg = sent[#sent]
check("template is sent as whisper automatically", ok and msg and msg.type == "WHISPER" and not msg.prefill, err)
check("placeholders filled (class, role, level, instance)", msg and msg.text:find("Jäger", 1, true) and msg.text:find("DPS", 1, true)
	and msg.text:find("22", 1, true) and msg.text:find("Höhlen des Wehklagens", 1, true) and not msg.text:find("{", 1, true), msg and msg.text)
print("      -> " .. (msg and msg.text or "?"))
ns.db.templateNames.deDE = { join_friendly = "Locker" }
openTemplateMenu()
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
	openTemplateMenu()
	pcall(lastMenu.buttons[1].fn)
	check("inviting a solo player invites and whispers", invited[#invited] == "Imogshaarig Bär" and sent[#sent].text:find("Imogshaarig", 1, true) ~= nil, sent[#sent].text)
	print("      -> " .. sent[#sent].text)
else
	check("solo tank listed for your group", false, "not in visible rows")
end

print("Entry menu and role display (0.7.8)")
do
	local rowFrame
	for _, fr in ipairs(ns.List.scrollBox.__frames) do if fr.entry and fr.entry.info then rowFrame = fr break end end
	ok, err = pcall(rowFrame.OnClick, rowFrame, "RightButton")
	local items = ns.Popup.current
	local labels = {}
	for _, it in ipairs(items or {}) do if it.kind == "button" then labels[#labels + 1] = it.text end end
	check("right click opens BGF's own entry menu (message, templates, report hint)", ok and items and #labels >= 3
		and labels[#labels]:find("Melden", 1, true) ~= nil, err or table.concat(labels, " | "))
	ns.Popup.Close()
	-- quests report 40 players: a 2-member group shows two icons, no counts
	local e = {}
	for k, v in pairs(rowFrame.entry) do e[k] = v end
	e.maxPlayers, e.profileKey, e.isSolo = 40, "other", false
	e.info = setmetatable({ numMembers = 2 }, { __index = rowFrame.entry.info })
	e.members = { { class = "MAGE", role = "DAMAGER" }, { class = "PRIEST", role = "HEALER" } }
	rowFrame:Init({ kind = "row", entry = e })
	local icons = 0
	for _, slot in ipairs(rowFrame.Slots) do if slot.__shown then icons = icons + 1 end end
	check("small group in a large activity: one icon per member, no counts", icons == 2 and not rowFrame.Counts.__shown, icons)
	-- a real raid group: counts with /40, style placed left of them
	e.profileKey = "raid"
	e.info = setmetatable({ numMembers = 12 }, { __index = rowFrame.entry.info })
	e.members = {}
	for i = 1, 12 do e.members[i] = { class = "WARRIOR", role = i == 1 and "TANK" or "DAMAGER" } end
	rowFrame:Init({ kind = "row", entry = e })
	check("raid group: role counts with 12/40", rowFrame.Counts.__shown and (rowFrame.Counts.__text or ""):find("12/40", 1, true) ~= nil,
		rowFrame.Counts.__text)
	e.profileKey = "other"
	rowFrame:Init({ kind = "row", entry = e })
	check("... no '/40' outside raids", not (rowFrame.Counts.__text or ""):find("/40", 1, true), rowFrame.Counts.__text)
	-- own listing: members of your group, the missing role faded, activity in line 2
	local origInfo = C_LFGList.GetSearchResultInfo
	C_LFGList.GetSearchResultInfo = function(id)
		local info = origInfo(id)
		if info then
			local copy = {}
			for k, v in pairs(info) do copy[k] = v end
			copy.hasSelf, copy.numMembers = true, 4
			return copy
		end
	end
	local mySide = { { class = "HUNTER", role = "DAMAGER", isSelf = true }, { class = "PRIEST", role = "HEALER" },
		{ class = "MAGE", role = "DAMAGER" }, { class = "ROGUE", role = "DAMAGER" } }
	local own = ns.Engine.EvaluateResult(rowFrame.entry.resultID, mySide, false)
	C_LFGList.GetSearchResultInfo = origInfo
	check("own listing reads your group and the missing tank", own and own.own and #own.members == 4
		and own.missingRoles[1] == "TANK" and #own.missingRoles == 1, own and #(own.members or {}))
	rowFrame:Init({ kind = "row", entry = own })
	local rings, faded = 0, 0
	for _, slot in ipairs(rowFrame.Slots) do
		if slot.__shown and slot.Ring.__shown then rings = rings + 1 end
		if slot.__shown and slot.Icon.__alpha and slot.Icon.__alpha < 1 then faded = faded + 1 end
	end
	check("... 4 class-coloured icons and 1 faded tank slot", rings == 4 and faded == 1, rings .. "/" .. faded)
	check("... line 2 names the activity", (rowFrame.Activity.__text or ""):find("·", 1, true) ~= nil, rowFrame.Activity.__text)
	check("no BGF window in Blizzard's Escape list (UISpecialFrames)", specialFrameInserts == 0, specialFrameInserts)
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
check("options: main page plus display, chips and templates pages", ns.Options.Pages.main and ns.Options.Pages.display
	and ns.Options.Pages.chips and ns.Options.Pages.templates and ns.Options.Pages.templates.LangButtons ~= nil)
local okOpen, errOpen = pcall(ns.Options.Open, "templates")
check("options open on a sub page", okOpen, errOpen)
local mainPage = ns.Options.Pages.main
check("main page shows the release notes of this version (no 'What's new' button)", mainPage.newsVersion == ns.VERSION
	and mainPage.Badge and mainPage.Badge.version == ns.VERSION)
pcall(mainPage.RenderNews, "0.8.0")
check("... the version badge switches to earlier releases", mainPage.newsVersion == "0.8.0" and mainPage.Badge.version == "0.8.0")
local langs = ns.Options.Pages.templates.LangButtons
check("templates: your own language is chosen right away (lit up), both buttons clickable",
	langs[1].lang == "deDE" and langs[1].chosen and not langs[2].chosen)
check("points explanation window opens", ok and helpWin, helpWin)
local fontList = ns.Options.FontItems and ns.Options.FontItems()
check("font list is BGF's own popup with one font object per entry", fontList and #fontList >= 8 and fontList[3].fontObject ~= fontList[1].fontObject
	and fontList[1].checked ~= nil)
if ok and helpWin then
	local headers, weights, plusRows = 0, 0, 0
	for _, item in ipairs(helpWin.Items) do
		if item.kind == "header" then headers = headers + 1 end
		if item.kind == "row" and item.tag == "weights" and item.value ~= "" then weights = weights + 1 end
		if item.kind == "row" and item.tag == "plus" then plusRows = plusRows + 1 end
	end
	check("... with 7 sections, generated weight rows (classes in one row) and plus rows", headers == 7 and weights == 8 and plusRows == 5,
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
