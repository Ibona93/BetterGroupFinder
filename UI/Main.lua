local _, ns = ...

--[[
UI wiring inside Blizzard's Group Finder (LFGParentFrame / LFGBrowseFrame):
  * BGF list over Blizzard's list (Blizzard's list and footer buttons hidden while active)
  * filter button and view button next to Refresh, filter bar under the header
  * "Templates" button between "Send Message" and "Group Invite"
The window keeps Blizzard's original width; only the filter bar makes it taller
(changed out of combat only). Nothing of Blizzard's code is replaced; BGF only hooks,
reads and shows/hides.
]]

local UI = {}
ns.UI = UI

local LIST_TOP = -112          -- Blizzard's list top offset in LFGBrowseFrame
local LIST_BOTTOM = 40
local FILTER_TOP = -84
local GOLD = { 1, 0.82, 0 }

local base = {}               -- original height of LFGParentFrame
local pendingLayout = false

local function inCombat()
	return InCombatLockdown and InCombatLockdown()
end

-------------------------------------------------------------------------------
-- Blizzard list visibility
-------------------------------------------------------------------------------

-- BGF list shown at all (/bgf on|off). "BGF filter active" only switches the rating.
local function bgfActive()
	return ns.db.uiEnabled and LFGBrowseFrame and LFGBrowseFrame:IsShown()
end

local function setBlizzardListShown(shown)
	local f = LFGBrowseFrame
	if not f then return end
	for _, child in ipairs({ f.ScrollBox, f.ScrollBar, f.SendMessageButton, f.GroupInviteButton }) do
		if child then
			if shown then child:Show() else child:Hide() end
		end
	end
	if shown and f.ScrollBar and f.ScrollBox and f.ScrollBox.HasScrollableExtent then
		local ok, scrollable = pcall(f.ScrollBox.HasScrollableExtent, f.ScrollBox)
		if ok and not scrollable then f.ScrollBar:Hide() end
	end
end

local function keepHiddenWhileActive(frame)
	if frame and frame.HookScript then
		frame:HookScript("OnShow", function(self)
			if ns.db.uiEnabled then self:Hide() end
		end)
	end
end

-------------------------------------------------------------------------------
-- Layout: height grows with the filter bar
-------------------------------------------------------------------------------

function UI.ApplyLayout()
	local parent = LFGParentFrame
	if not parent or not base.height then return end
	local bar = ns.FilterBar.frame
	local open = ns.db.filterOpen and ns.db.uiEnabled and LFGBrowseFrame:IsShown()
	local combat = inCombat()
	pendingLayout = combat

	local barHeight = 0
	if open then
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", LFGBrowseFrame, "TOPLEFT", 8, FILTER_TOP)
		bar:SetPoint("TOPRIGHT", LFGBrowseFrame, "TOPRIGHT", -8, FILTER_TOP)
		bar:Show()
		barHeight = ns.FilterBar.Layout()
		bar:SetHeight(barHeight)
		ns.FilterBar.Update()
	else
		bar:Hide()
	end

	if not combat then
		parent:SetHeight(base.height + barHeight)
	end

	local scrollBox = ns.List.scrollBox
	scrollBox:ClearAllPoints()
	scrollBox:SetPoint("TOPLEFT", LFGBrowseFrame, "TOPLEFT", 7, LIST_TOP - barHeight)
	scrollBox:SetPoint("BOTTOMRIGHT", LFGBrowseFrame, "BOTTOMRIGHT", -24, LIST_BOTTOM)
	UI.UpdateFilterButton()
end

function UI.OnCombatStart() end

function UI.OnCombatEnd()
	if pendingLayout then UI.ApplyLayout() end
end

-------------------------------------------------------------------------------
-- Enable / disable
-------------------------------------------------------------------------------

function UI.ApplyEnabled()
	if not UI.attached then return end
	local ui = ns.db.uiEnabled
	setBlizzardListShown(not ui)
	ns.List.SetShown(ui)
	UI.messageButton:SetShown(ui)
	UI.inviteButton:SetShown(ui)
	UI.filterButton:SetShown(ui)
	UI.ApplyLayout()
	ns.FilterBar.Update()
	if ui then ns.RequestRefresh() end
	UI.UpdateButtons()
end

-------------------------------------------------------------------------------
-- Selection and footer buttons
-------------------------------------------------------------------------------

local function blizzardSelectedID()
	local f = LFGBrowseFrame
	if not f or not f.selectionBehavior then return nil end
	local ok, has = pcall(f.selectionBehavior.HasSelection, f.selectionBehavior)
	if not ok or not has then return nil end
	local okData, data = pcall(f.selectionBehavior.GetSelectedElementData, f.selectionBehavior)
	local element = okData and data and data[1]
	return element and element.data and element.data.resultID
end

function UI.GetSelectedEntry()
	if ns.db.uiEnabled then
		return ns.List.GetSelectedEntry()
	end
	local id = blizzardSelectedID()
	if not id then return nil end
	return ns.Engine.EvaluateResult(id, ns.Engine.GetMySide())
end

function UI.UpdateButtons()
	if not UI.attached then return end
	local entry = UI.GetSelectedEntry()
	local valid = entry and not entry.own and entry.info and not entry.info.isDelisted
	UI.requestButton:SetEnabled(valid and true or false)
	UI.messageButton:SetEnabled(valid and true or false)
	local canInvite = valid and entry.isSolo and ns.Contact.Mode(entry) == "invite"
	UI.inviteButton:SetEnabled(canInvite and true or false)
end

local function createFooter()
	local f = LFGBrowseFrame
	local L = ns.L

	UI.messageButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	UI.messageButton:SetSize(111, 28)
	UI.messageButton:SetPoint("BOTTOMLEFT", 21, 16)
	UI.messageButton:SetText(SEND_MESSAGE or "Send Message")
	UI.messageButton:SetScript("OnClick", function()
		local entry = UI.GetSelectedEntry()
		if entry and entry.info and entry.info.leaderName and ChatFrameUtil and ChatFrameUtil.SendTell then
			ChatFrameUtil.SendTell(entry.info.leaderName)
		end
	end)

	UI.inviteButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	UI.inviteButton:SetSize(109, 28)
	UI.inviteButton:SetPoint("BOTTOMRIGHT", -21, 16)
	UI.inviteButton:SetText(GROUP_INVITE or "Group Invite")
	UI.inviteButton:SetScript("OnClick", function()
		local entry = UI.GetSelectedEntry()
		if entry and entry.info and entry.info.leaderName and C_PartyInfo and C_PartyInfo.InviteUnit then
			pcall(C_PartyInfo.InviteUnit, entry.info.leaderName)
		end
	end)

	UI.requestButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	UI.requestButton:SetSize(100, 28)
	UI.requestButton:SetPoint("BOTTOM", 0, 16)
	UI.requestButton:SetText(L.REQUEST)
	UI.requestButton:SetScript("OnClick", function(self)
		ns.Contact.OpenMenu(self, UI.GetSelectedEntry())
	end)
	UI.requestButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L.REQUEST, 1, 1, 1)
		GameTooltip:AddLine(L.REQUEST_TT, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	UI.requestButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-------------------------------------------------------------------------------
-- Header buttons: same square frame as Refresh, plain drawn icons
-------------------------------------------------------------------------------

local function bar(parent, width, height, x, y)
	local t = parent:CreateTexture(nil, "ARTWORK", nil, 5)
	t:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
	t:SetSize(width, height)
	t:SetPoint("CENTER", x, y)
	return t
end

local BUTTON_SIZE = 24          -- fits between Refresh and Blizzard's gear icon
local UP = "Interface\\Buttons\\UI-SquareButton-Up"
local DOWN = "Interface\\Buttons\\UI-SquareButton-Down"

local function createHeaderButtons()
	local L = ns.L
	local b = CreateFrame("Button", nil, LFGBrowseFrame)
	b:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	if LFGBrowseFrame.RefreshButton then
		b:SetPoint("LEFT", LFGBrowseFrame.RefreshButton, "RIGHT", 0, 0)
	else
		b:SetPoint("TOPRIGHT", -36, -40)
	end
	b:SetNormalTexture(UP)
	b:SetPushedTexture(DOWN)
	b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	b.Icon = CreateFrame("Frame", nil, b)
	b.Icon:SetSize(14, 14)
	b.Icon:SetPoint("CENTER")
	-- three lines getting shorter (funnel)
	bar(b.Icon, 11, 2, 0, 3)
	bar(b.Icon, 7, 2, 0, 0)
	bar(b.Icon, 3, 2, 0, -3)
	b:SetScript("OnMouseDown", function(self) self.Icon:SetPoint("CENTER", -1, -1) end)
	b:SetScript("OnMouseUp", function() UI.UpdateFilterButton() end)
	b:SetScript("OnClick", function()
		if inCombat() then ns.Print(L.COMBAT_FILTER) return end
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		ns.db.filterOpen = not ns.db.filterOpen
		UI.ApplyLayout()
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.FILTER_BUTTON_TT, 1, 1, 1)
		GameTooltip:AddLine(L.FILTER_BUTTON_TT2, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	UI.filterButton = b
end

-- Open filter bar: the button stays visibly pressed in.
function UI.UpdateFilterButton()
	local b = UI.filterButton
	if not b then return end
	local open = ns.db.filterOpen and ns.FilterBar.frame and ns.FilterBar.frame:IsShown() or false
	b.pressed = open
	b:SetNormalTexture(open and DOWN or UP)
	b.Icon:ClearAllPoints()
	if open then b.Icon:SetPoint("CENTER", -1, -1) else b.Icon:SetPoint("CENTER", 0, 0) end
	b.Icon:SetAlpha(open and 0.85 or 1)
end

-------------------------------------------------------------------------------
-- Refresh
-------------------------------------------------------------------------------

function UI.Refresh()
	if not UI.attached or not LFGBrowseFrame then return end
	ns.FilterBar.Update()
	if not bgfActive() then
		UI.UpdateButtons()
		return
	end
	setBlizzardListShown(false)
	local f = LFGBrowseFrame
	if f.searching then
		ns.List.SetSections(nil)
	else
		local results = f.results
		if type(results) ~= "table" then
			local ok, _, filtered = false, nil, nil
			if C_LFGList and C_LFGList.GetFilteredSearchResults then ok, _, filtered = pcall(C_LFGList.GetFilteredSearchResults) end
			results = ok and filtered or {}
		end
		if f.searchFailed or (f.totalResults or 0) == 0 then results = {} end
		ns.List.SetSections(ns.Engine.BuildSections(results, ns.db.enabled))
	end
	UI.UpdateButtons()
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------

function UI.Setup()
	if UI.attached or not LFGBrowseFrame or not LFGParentFrame then return end
	base.height = LFGParentFrame:GetHeight()

	ns.List.Create(LFGBrowseFrame)
	ns.FilterBar.Create(LFGBrowseFrame)
	createFooter()
	createHeaderButtons()
	UI.attached = true

	keepHiddenWhileActive(LFGBrowseFrame.ScrollBox)
	keepHiddenWhileActive(LFGBrowseFrame.ScrollBar)
	keepHiddenWhileActive(LFGBrowseFrame.SendMessageButton)
	keepHiddenWhileActive(LFGBrowseFrame.GroupInviteButton)

	--[[
	No hooks on Blizzard's functions (UpdateResults, UpdateButtonState, dropdown SetValue):
	with /console taintLog 1 the 1.60.1 beta client broke Blizzard's call chain there. BGF
	follows the Group Finder through events (Core.lua) and only hooks frame scripts.
	The refresh runs a moment later, after Blizzard has stored the new results.
	]]
	LFGBrowseFrame:HookScript("OnShow", function()
		UI.ApplyLayout()
		ns.RequestRefresh()
	end)
	LFGBrowseFrame:HookScript("OnHide", function()
		ns.Tooltip.Hide()
		UI.ApplyLayout()
	end)
	if LFGBrowseFrame.RefreshButton then
		-- a new search starts: show "searching" and clear the list
		LFGBrowseFrame.RefreshButton:HookScript("OnClick", function() ns.RequestRefresh() end)
	end

	UI.ApplyEnabled()
	ns.Debug("UI attached")
end
