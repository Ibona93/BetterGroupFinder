local _, ns = ...

--[[
BGF result list: an own ScrollBox laid over Blizzard's list inside LFGBrowseFrame,
using the Group Finder's own textures and icons. Blizzard's list is not modified,
only hidden while BGF is active.

Font sizes like Blizzard's own list (names 14, everything else 12). Columns are sized from
the window's original width; texts that do not fit are abbreviated (instance names:
"Höhlen d. Wehklagens", player names: "Aldarin S.") and only then cut with "...".
The tooltip always shows the full texts.
]]

local List = {}
ns.List = List

local MAX_SLOTS = 5
local GAP = 4
local ROLE_ATLAS = {
	TANK = "groupfinder-icon-role-large-tank",
	HEALER = "groupfinder-icon-role-large-heal",
	DAMAGER = "groupfinder-icon-role-large-dps",
}
local ROLE_SORT = { TANK = 1, HEALER = 2, DAMAGER = 3 }
local COLORS = {
	activity = { 0.62, 0.62, 0.62 },
	level = { 0.55, 0.55, 0.55 },
	style = { 0.12, 1, 0.12 },
	score = { 1, 0.82, 0 },
	excluded = { 0.88, 0.63, 0.25 },
	header = { 1, 0.82, 0 },
	headerExcluded = { 0.66, 0.6, 0.53 },
	count = { 0.6, 0.6, 0.6 },
}

List.selectedID = nil

local function setAtlasSafe(texture, atlas, useAtlasSize)
	local ok, result = pcall(texture.SetAtlas, texture, atlas, useAtlasSize and true or false)
	return ok and result ~= false
end

local function classColor(class)
	local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if c then return c.r, c.g, c.b end
	return 1, 0.82, 0
end

local function colorize(text, r, g, b)
	return ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, text or "")
end

-------------------------------------------------------------------------------
-- Fonts and metrics
-------------------------------------------------------------------------------

function List.GetFont(size)
	return ns.Fonts.Get(size)
end

-- Fixed sizes like Blizzard's own list: names 14, everything else 12.
local FONT, NAME_FONT = 12, 14

function List.Metrics()
	return {
		font = FONT,
		name = NAME_FONT,
		row = NAME_FONT + FONT + 14,
		header = FONT + 12,
		slot = FONT + 4,
		icon = NAME_FONT,
	}
end

local measure

local function textWidth(text)
	measure:SetText(text)
	if measure.GetUnboundedStringWidth then return measure:GetUnboundedStringWidth() end
	return measure:GetStringWidth()
end

-- Shows the first variant that fits; the last one is cut by the font string if needed.
local function fit(fs, variants, width)
	measure:SetFontObject(fs:GetFontObject() or GameFontHighlightSmall)
	fs:SetWidth(math.max(width, 1))
	for i, text in ipairs(variants) do
		if i == #variants or textWidth(text) <= width then
			fs:SetText(text)
			return
		end
	end
end

function List.ShowScores()
	return ns.db.showScores and ns.db.enabled and true or false
end

--[[
Two-line rows:
  [icon] name (+ level)            play style   role icons   +30 (benefit)
         instance                  (centered)   (centered)   62 % (group value, groups only)
]]
function List.Columns(rowWidth)
	local m = List.Metrics()
	measure:SetFontObject(List.GetFont(m.font))
	local styleW = 0
	for i = 1, 3 do
		local s = GetGeneralPlaystyleString and GetGeneralPlaystyleString(i) or ""
		if s ~= "" then styleW = math.max(styleW, textWidth(s)) end
	end
	styleW = math.min(math.ceil(styleW) + 2, 82)
	local scoreW = 0
	if List.ShowScores() then
		scoreW = math.ceil(textWidth("188")) + 2
	end
	local slotsW = MAX_SLOTS * m.slot + (MAX_SLOTS - 1)
	local inner = rowWidth - 6 - 6 - 4 -- background insets and side padding
	local fixed = m.icon + 3 + styleW + slotsW + scoreW + GAP * 3
	return {
		m = m,
		styleW = styleW,
		scoreW = scoreW,
		slotsW = slotsW,
		textW = math.max(inner - fixed, 60),
	}
end

-------------------------------------------------------------------------------
-- Role slot: class-colored ring + role icon
-------------------------------------------------------------------------------

local function CreateSlot(parent)
	local slot = CreateFrame("Frame", nil, parent)
	slot.Ring = slot:CreateTexture(nil, "BACKGROUND")
	slot.Ring:SetAllPoints()
	slot.Ring:SetColorTexture(1, 1, 1, 1)
	local mask = slot:CreateMaskTexture()
	mask:SetAllPoints(slot.Ring)
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	slot.Ring:AddMaskTexture(mask)
	slot.Icon = slot:CreateTexture(nil, "ARTWORK")
	slot.Icon:SetPoint("CENTER")
	return slot
end

local function SetSlot(slot, size, role, class, faded)
	slot:SetSize(size, size)
	slot.Icon:SetAlpha(faded and 0.35 or 1)
	if role then
		setAtlasSafe(slot.Icon, ROLE_ATLAS[role] or ROLE_ATLAS.DAMAGER)
		slot.Icon:SetSize(size - 3, size - 3)
		if class and ns.db.classColorRings ~= false then
			slot.Ring:SetVertexColor(classColor(class))
			slot.Ring:Show()
		else
			slot.Ring:Hide()
			-- ring switched off in the options: the icon fills the whole slot instead
			if class then slot.Icon:SetSize(size, size) end
		end
	else
		setAtlasSafe(slot.Icon, "groupfinder-icon-emptyslot")
		slot.Icon:SetSize(size - 6, size - 6)
		slot.Ring:Hide()
	end
	slot:Show()
end

-------------------------------------------------------------------------------
-- Row
-------------------------------------------------------------------------------

BGFRowMixin = {}

local function newText(parent, justify)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	fs:SetFontObject(GameFontHighlightSmall)
	fs:SetJustifyH(justify or "LEFT")
	fs:SetWordWrap(false)
	return fs
end

function BGFRowMixin:OnLoad()
	self.ResultBG = self:CreateTexture(nil, "BACKGROUND")
	self.ResultBG:SetPoint("TOPLEFT", 3, -1)
	self.ResultBG:SetPoint("BOTTOMRIGHT", -3, 0)
	if not setAtlasSafe(self.ResultBG, "common-button-list-mid2") then
		self.ResultBG:SetColorTexture(0.1, 0.08, 0.06, 0.8)
	end

	self.Highlight = self:CreateTexture(nil, "HIGHLIGHT")
	self.Highlight:SetAllPoints(self.ResultBG)
	if not setAtlasSafe(self.Highlight, "common-button-list-mid2-hover") then
		self.Highlight:SetColorTexture(0.3, 0.5, 0.8, 0.15)
	end
	self.Highlight:SetBlendMode("ADD")

	self.Selected = self:CreateTexture(nil, "ARTWORK", nil, -1)
	self.Selected:SetAllPoints(self.ResultBG)
	if not setAtlasSafe(self.Selected, "common-button-list-mid2-selected") then
		self.Selected:SetColorTexture(1, 0.82, 0, 0.15)
	end
	self.Selected:SetBlendMode("ADD")
	self.Selected:Hide()

	self.Icon = self:CreateTexture(nil, "ARTWORK")
	self.NewPlayer = self:CreateTexture(nil, "ARTWORK")
	setAtlasSafe(self.NewPlayer, "newplayerchat-chaticon-newcomer")

	self.Name = newText(self)
	self.Activity = newText(self)
	self.Style = newText(self)
	self.Reason = newText(self)
	self.Score = newText(self, "RIGHT")
	self.Value = newText(self, "RIGHT")
	self.ScoreAnchor = CreateFrame("Frame", nil, self)
	self.Counts = newText(self, "RIGHT")

	self.Slots = {}
	for i = 1, MAX_SLOTS do self.Slots[i] = CreateSlot(self) end
end

function BGFRowMixin:Layout(cols)
	local m = cols.m
	local font = List.GetFont(m.font)
	for _, fs in ipairs({ self.Name, self.Activity, self.Style, self.Reason, self.Score, self.Value, self.Counts }) do
		fs:SetFontObject(font)
		fs:ClearAllPoints()
	end
	self.Name:SetFontObject(List.GetFont(m.name))
	self.Activity:SetTextColor(unpack(COLORS.activity))
	self.Style:SetTextColor(unpack(COLORS.style))
	self.Reason:SetTextColor(unpack(COLORS.excluded))
	self.Score:SetTextColor(unpack(COLORS.score))
	self.Value:SetTextColor(unpack(COLORS.activity))
	self.Counts:SetTextColor(unpack(COLORS.activity))

	-- right column: benefit (+ group value below for groups); anchored in Init
	self.Score:SetWidth(cols.scoreW)
	self.Value:SetWidth(cols.scoreW)
	self.ScoreAnchor:ClearAllPoints()
	self.ScoreAnchor:SetSize(math.max(cols.scoreW, 1), 1)
	self.ScoreAnchor:SetPoint("RIGHT", -8, 0)

	for i = MAX_SLOTS, 1, -1 do
		local slot = self.Slots[i]
		slot:ClearAllPoints()
		slot:SetSize(m.slot, m.slot)
		if i == MAX_SLOTS then
			slot:SetPoint("RIGHT", self.ScoreAnchor, "LEFT", -GAP, 0)
		else
			slot:SetPoint("RIGHT", self.Slots[i + 1], "LEFT", -1, 0)
		end
	end
	self.Counts:SetPoint("RIGHT", self.ScoreAnchor, "LEFT", -GAP, 0)
	self.Counts:SetWidth(cols.slotsW + 30)

	-- play style vertically centered, level with the role icons
	self.Style:SetPoint("RIGHT", self.Slots[1], "LEFT", -GAP, 0)
	self.Style:SetWidth(cols.styleW)

	-- name above, instance below
	local half = m.font / 2 + 2
	self.Icon:ClearAllPoints()
	self.Icon:SetSize(m.icon, m.icon)
	self.Icon:SetPoint("LEFT", 9, half)
	self.NewPlayer:ClearAllPoints()
	self.NewPlayer:SetSize(m.icon, m.icon)
	self.Name:SetPoint("LEFT", self.Icon, "RIGHT", 3, 0)
	self.Activity:SetPoint("LEFT", self.Icon, "RIGHT", 3, -2 * half)
	self.Reason:SetPoint("LEFT", self.Activity, "LEFT")
end

local function sortedMembers(members)
	local list = {}
	for _, m in ipairs(members or {}) do list[#list + 1] = m end
	table.sort(list, function(a, b)
		return (ROLE_SORT[a.role or "DAMAGER"] or 3) < (ROLE_SORT[b.role or "DAMAGER"] or 3)
	end)
	return list
end

function BGFRowMixin:Init(data)
	local entry = data.entry
	local cols = List.columns
	local m = cols.m
	self.entry = entry
	self.resultID = entry.resultID
	local info = entry.info
	self:Layout(cols)
	self:SetAlpha(1)

	-- Icon
	local leaderClass
	for _, member in ipairs(entry.members or {}) do
		if member.isLeader or entry.isSolo then leaderClass = member.class break end
	end
	local iconAtlas = "groupfinder-icon-leader"
	if entry.isSolo and leaderClass then iconAtlas = "groupfinder-icon-class-" .. leaderClass:lower() end
	if not setAtlasSafe(self.Icon, iconAtlas) then setAtlasSafe(self.Icon, "groupfinder-icon-leader") end

	-- Name (+ level for players)
	local name = info.leaderName or "?"
	if Ambiguate then name = Ambiguate(name, "none") end
	local level = entry.isSolo and entry.members and entry.members[1] and entry.members[1].level
	local levelText = ""
	if level then
		levelText = " " .. colorize((LEVEL_ABBR or "Lvl") .. " " .. level, unpack(COLORS.level))
	end
	local r, g, b = classColor(leaderClass)
	local variants = { colorize(name, r, g, b) .. levelText }
	local short = ns.ShortName(name)
	if short then variants[#variants + 1] = colorize(short, r, g, b) .. levelText end
	local nameWidth = cols.textW
	measure:SetFontObject(List.GetFont(m.name))
	if info.newPlayerFriendly then nameWidth = nameWidth - m.icon - 2 end
	fit(self.Name, variants, nameWidth)
	self.NewPlayer:SetShown(info.newPlayerFriendly and true or false)
	if info.newPlayerFriendly then
		measure:SetFontObject(List.GetFont(m.name))
		self.NewPlayer:SetPoint("LEFT", self.Name, "LEFT", math.min(textWidth(self.Name:GetText() or ""), nameWidth) + 2, 0)
	end

	-- Activity (abbreviated if needed) and play style
	local activityW = cols.textW
	local activity = entry.activityName or ""
	if entry.own then
		activity = LFG_SELF_LISTING or ns.L.OWN_LISTING
		if (entry.numActivities or 0) <= 1 and (entry.activityName or "") ~= "" then
			activity = activity .. " · " .. entry.activityName
		end
	elseif (entry.numActivities or 0) > 1 and activity == "" and LFGBROWSE_ACTIVITY_COUNT then
		activity = LFGBROWSE_ACTIVITY_COUNT:format(entry.numActivities)
	end
	local actSteps = { activity }
	for _, step in ipairs(ns.AbbreviationSteps(activity, ns.clientLocale)) do actSteps[#actSteps + 1] = step end
	-- current zone after the activity: green = your zone, grey = elsewhere (leader's zone)
	local activityVariants = actSteps
	if entry.zone and not entry.own then
		local color = entry.sameZone and "ff4ce64c" or "ff8c8c8c"
		local function withZone(a, z)
			local zoneText = "|c" .. color .. z .. "|r"
			if a == "" then return zoneText end
			return a .. " · " .. zoneText
		end
		activityVariants = {}
		for _, a in ipairs(actSteps) do activityVariants[#activityVariants + 1] = withZone(a, entry.zone) end
		local last = actSteps[#actSteps]
		for _, z in ipairs(ns.AbbreviationSteps(entry.zone, ns.clientLocale)) do
			activityVariants[#activityVariants + 1] = withZone(last, z)
		end
	end
	fit(self.Activity, activityVariants, activityW)

	local style = ""
	if info.generalPlaystyle and GetGeneralPlaystyleString then
		style = GetGeneralPlaystyleString(info.generalPlaystyle) or ""
	end
	fit(self.Style, { style, (style:match("^(%S+)") or style) }, cols.styleW)

	-- Members / roles
	for _, slot in ipairs(self.Slots) do slot:Hide() end
	self.Counts:Hide()
	if entry.isSolo then
		local member = entry.members and entry.members[1]
		local roles = member and member.lfgRoles
		local list = {}
		if roles then
			if roles.tank then list[#list + 1] = "TANK" end
			if roles.healer then list[#list + 1] = "HEALER" end
			if roles.dps then list[#list + 1] = "DAMAGER" end
		end
		local offset = MAX_SLOTS - #list
		for i, role in ipairs(list) do SetSlot(self.Slots[offset + i], m.slot, role, member.class) end
	elseif (entry.maxPlayers or 5) <= MAX_SLOTS then
		local members = sortedMembers(entry.members)
		local maxPlayers = math.min(entry.maxPlayers or MAX_SLOTS, MAX_SLOTS)
		local offset = MAX_SLOTS - maxPlayers
		local missing = entry.own and entry.missingRoles or {}
		local nextMissing = 1
		for i = 1, maxPlayers do
			local member = members[i]
			if member then
				SetSlot(self.Slots[offset + i], m.slot, member.role or "DAMAGER", member.class)
			elseif missing[nextMissing] then
				-- own listing: the role you still look for, faded
				SetSlot(self.Slots[offset + i], m.slot, missing[nextMissing], nil, true)
				nextMissing = nextMissing + 1
			else
				SetSlot(self.Slots[offset + i], m.slot, nil, nil)
			end
		end
	elseif (info.numMembers or #(entry.members or {})) <= MAX_SLOTS then
		-- large activity (quests report 40) but a small group: one icon per member, no empty slots
		local members = sortedMembers(entry.members)
		local offset = MAX_SLOTS - #members
		for i, member in ipairs(members) do
			SetSlot(self.Slots[offset + i], m.slot, member.role or "DAMAGER", member.class)
		end
	else
		local counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
		for _, member in ipairs(entry.members or {}) do
			local role = member.role or "DAMAGER"
			counts[role] = counts[role] + 1
		end
		local parts = {}
		for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
			local icon = CreateAtlasMarkup and CreateAtlasMarkup(ROLE_ATLAS[role], m.font + 2, m.font + 2) or role:sub(1, 1)
			parts[#parts + 1] = icon .. counts[role]
		end
		local size = entry.profileKey == "raid" and ((info.numMembers or 0) .. "/" .. (entry.maxPlayers or 40)) or nil
		self.Counts:SetText(table.concat(parts, " ") .. (size and (" " .. size) or ""))
		self.Counts:Show()
	end
	-- play style left of the icons, or left of the (wider) role counts
	self.Style:ClearAllPoints()
	if self.Counts:IsShown() then
		local w = math.ceil(self.Counts:GetStringWidth() or 0)
		self.Style:SetPoint("RIGHT", self.ScoreAnchor, "LEFT", -(2 * GAP + w), 0)
	else
		self.Style:SetPoint("RIGHT", self.Slots[1], "LEFT", -GAP, 0)
	end

	-- Score / exclusion
	local result = entry.result
	local excluded = data.excluded
	self.Reason:SetShown(excluded)
	self.Activity:SetShown(not excluded)
	self.Style:SetShown(not excluded)
	if excluded then
		self.NewPlayer:Hide()
		fit(self.Reason, { result and result.excludeReason and ns.FormatReason(result.excludeReason) or "" },
			activityW + cols.styleW + GAP)
		self:SetAlpha(0.62)
	end

	-- Right column: the points, coloured by verdict (the group value is in the tooltip)
	self.Score:SetText("")
	self.Value:SetText("")
	self.Score:ClearAllPoints()
	self.Value:ClearAllPoints()
	if not excluded and result and not entry.own and List.ShowScores() then
		self.Score:SetText(tostring(result.score))
		local c = ns.ScoreColor(result)
		self.Score:SetTextColor(c[1], c[2], c[3])
		self.Score:SetPoint("RIGHT", self.ScoreAnchor, "RIGHT", 0, 0)
	end
	self:UpdateSelection()
end

function BGFRowMixin:UpdateSelection()
	self.Selected:SetShown(self.resultID ~= nil and self.resultID == List.selectedID)
end

function BGFRowMixin:OnClick(button)
	local entry = self.entry
	if not entry or entry.own then return end
	if button == "RightButton" then
		-- own menu: Blizzard's entry menu runs through its protected menu system (crash with
		-- taintLog in the 1.60.1 beta) and reporting is not allowed for addons anyway
		List.selectedID = entry.resultID
		List.UpdateSelections()
		if ns.UI and ns.UI.UpdateButtons then ns.UI.UpdateButtons() end
		if ns.Contact and ns.Contact.OpenEntryMenu then ns.Contact.OpenEntryMenu(self, entry) end
		return
	end
	if entry.info and entry.info.isDelisted then return end
	if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
	if List.selectedID == entry.resultID then
		List.selectedID = nil
	else
		List.selectedID = entry.resultID
	end
	List.UpdateSelections()
	if ns.UI and ns.UI.UpdateButtons then ns.UI.UpdateButtons() end
end

function BGFRowMixin:OnEnter()
	if not self.entry then return end
	if ns.db.debug then ns.Engine.DumpResult(self.entry.resultID) end
	ns.Tooltip.Show(self, self.entry)
end

function BGFRowMixin:OnLeave()
	ns.Tooltip.Hide()
end

-------------------------------------------------------------------------------
-- Header
-------------------------------------------------------------------------------

BGFHeaderMixin = {}

function BGFHeaderMixin:OnLoad()
	self.BG = self:CreateTexture(nil, "BACKGROUND")
	self.BG:SetPoint("TOPLEFT", 3, -3)
	self.BG:SetPoint("BOTTOMRIGHT", -3, 0)
	if not setAtlasSafe(self.BG, "common-button-list-collapseExpand") then
		self.BG:SetColorTexture(0.16, 0.11, 0.07, 0.9)
	end
	self.Label = newText(self)
	self.Label:SetPoint("LEFT", 12, -1)
	self.Count = newText(self, "RIGHT")
	self.Toggle = self:CreateTexture(nil, "ARTWORK")
	self.Toggle:SetPoint("RIGHT", -12, -1)
	self.Count:SetPoint("RIGHT", self.Toggle, "LEFT", -8, 0)
	self.Highlight = self:CreateTexture(nil, "HIGHLIGHT")
	self.Highlight:SetAllPoints(self.BG)
	if not setAtlasSafe(self.Highlight, "common-button-list-collapseExpand") then
		self.Highlight:SetColorTexture(1, 1, 1, 0.05)
	end
	self.Highlight:SetBlendMode("ADD")
	self.Highlight:SetAlpha(0.4)
end

-- Uses the atlas in its own proportions (a stretched minus looked like a yellow box).
local function setToggleIcon(texture, atlas, maxHeight)
	if not setAtlasSafe(texture, atlas, true) then return end
	local w, h = texture:GetSize()
	if w and h and h > 0 and h > maxHeight then
		texture:SetSize(w * maxHeight / h, maxHeight)
	end
end

function BGFHeaderMixin:Init(data)
	local m = List.Metrics()
	local font = List.GetFont(m.font + 1)
	self.Label:SetFontObject(font)
	self.Count:SetFontObject(List.GetFont(m.font))
	self.key = data.key
	self.Label:SetText(data.label)
	self.Count:SetText(data.count or "")
	self.Count:SetTextColor(unpack(COLORS.count))
	local collapsed = ns.db.collapsed[data.key]
	setToggleIcon(self.Toggle, collapsed and "common-button-list-plus" or "common-button-list-minus", m.font + 2)
	if data.key == "excluded" then
		self.Label:SetTextColor(unpack(COLORS.headerExcluded))
	else
		self.Label:SetTextColor(unpack(COLORS.header))
	end
end

function BGFHeaderMixin:OnClick()
	ns.db.collapsed[self.key] = not ns.db.collapsed[self.key]
	if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
	List.Render()
end

-------------------------------------------------------------------------------
-- Message line
-------------------------------------------------------------------------------

BGFMessageMixin = {}

function BGFMessageMixin:OnLoad()
	self.Text = newText(self)
	self.Text:SetPoint("LEFT", 12, 0)
	self.Text:SetPoint("RIGHT", -12, 0)
	self.Text:SetWordWrap(true)
	self.Text:SetTextColor(unpack(COLORS.excluded))
end

function BGFMessageMixin:Init(data)
	self.Text:SetFontObject(List.GetFont(List.Metrics().font))
	self.Text:SetText(data.text)
	local c = data.color or COLORS.excluded
	self.Text:SetTextColor(c[1], c[2], c[3])
end

-------------------------------------------------------------------------------
-- List frame
-------------------------------------------------------------------------------

function List.Create(parent)
	local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
	local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, -4)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 2)
	measure = parent:CreateFontString(nil, "ARTWORK")
	measure:SetFontObject(GameFontHighlightSmall)
	measure:Hide()

	local view = CreateScrollBoxListLinearView()
	view:SetElementFactory(function(factory, data)
		if data.kind == "header" then
			factory("BGFHeaderTemplate", function(frame, d) frame:Init(d) end)
		elseif data.kind == "message" then
			factory("BGFMessageTemplate", function(frame, d) frame:Init(d) end)
		else
			factory("BGFRowTemplate", function(frame, d) frame:Init(d) end)
		end
	end)
	view:SetElementExtentCalculator(function(_, data)
		local m = List.Metrics()
		if data.kind == "header" then return m.header end
		if data.kind == "message" then return 2 * m.font + 14 end
		return m.row
	end)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

	List.scrollBox = scrollBox
	List.scrollBar = scrollBar
	List.view = view
	return scrollBox, scrollBar
end

function List.SetShown(shown)
	if not List.scrollBox then return end
	List.scrollBox:SetShown(shown)
	List.scrollBar:SetShown(shown)
end

function List.UpdateSelections()
	if not List.scrollBox then return end
	List.scrollBox:ForEachFrame(function(frame)
		if frame.UpdateSelection then frame:UpdateSelection() end
	end)
end

function List.GetSelectedEntry()
	if not List.selectedID or not List.sections then return nil end
	for _, key in ipairs({ "groups", "players", "excluded", "own" }) do
		for _, entry in ipairs(List.sections[key] or {}) do
			if entry.resultID == List.selectedID then return entry end
		end
	end
	return nil
end

-- `hint`: a line shown instead of the list (e.g. no Group Finder category chosen yet).
function List.SetSections(sections, hint)
	List.sections = sections
	List.hint = hint
	if List.selectedID and not List.GetSelectedEntry() then
		List.selectedID = nil
	end
	List.Render()
end

function List.Render()
	if not List.scrollBox then return end
	local width = List.scrollBox:GetWidth()
	if not width or width < 200 then width = 427 end
	List.columns = List.Columns(width)

	local sections = List.sections
	local L = ns.L
	local items = {}
	if List.hint then
		items[1] = { kind = "message", text = List.hint, color = { 1, 0.82, 0 } }
	elseif sections then
		if ns.Engine.locked then
			items[#items + 1] = { kind = "message", text = L.LOCKDOWN }
		end
		for _, entry in ipairs(sections.own) do
			items[#items + 1] = { kind = "row", entry = entry }
		end
		local shown = #sections.groups + #sections.players
		if sections.total > 0 and shown == 0 and #sections.own == 0 and #sections.excluded > 0 then
			items[#items + 1] = { kind = "message", text = L.ALL_EXCLUDED:format(#sections.excluded) }
		end
		local function addSection(key, label, list, excluded)
			if #list == 0 then return end
			items[#items + 1] = {
				kind = "header", key = key, label = label,
				count = (excluded or not sections.rated) and #list or L.MATCHING:format(#list),
			}
			if not ns.db.collapsed[key] then
				for _, entry in ipairs(list) do
					items[#items + 1] = { kind = "row", entry = entry, excluded = excluded }
				end
			end
		end
		addSection("groups", L.GROUPS, sections.groups, false)
		addSection("players", L.PLAYERS, sections.players, false)
		addSection("excluded", L.EXCLUDED, sections.excluded, true)
	end
	List.scrollBox:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
end
