local _, ns = ...

--[[
Small popup menu in Blizzard's look, used instead of Blizzard's menu system (MenuUtil /
dropdown menus). Blizzard's menus run through protected code; with /console taintLog 1 the
1.60.1 beta client crashed when an addon button owned such a menu (ldebug.c assertion).
This menu only uses plain frames.

Items: { kind = "title" | "header" | "divider" | "button", text, fn, tooltip(tooltip),
         indent, checked (radio dot), fontObject }
]]

local Popup = {}
ns.Popup = Popup

local ROW_H = 18
local PAD = 10

local frame, catcher
local rows = {}

local function close()
	if frame then frame:Hide() end
	if catcher then catcher:Hide() end
	Popup.current = nil
end
Popup.Close = close

-- Escape closes a BGF window without Blizzard's UISpecialFrames list (which Blizzard walks on
-- every Escape and panel change, logging addon names in the taint log). Out of combat only:
-- keyboard propagation may not be changed by addons in combat.
function Popup.CloseOnEscape(f, onClose)
	f:HookScript("OnShow", function(self)
		local combat = InCombatLockdown and InCombatLockdown()
		self:EnableKeyboard(not combat)
		if not combat and self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
	end)
	f:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown and InCombatLockdown() then return end
		if key == "ESCAPE" then
			if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
			if onClose then onClose() else self:Hide() end
		elseif self.SetPropagateKeyboardInput then
			self:SetPropagateKeyboardInput(true)
		end
	end)
end

local function create()
	catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN")
	catcher:RegisterForClicks("AnyDown")
	catcher:SetScript("OnClick", close)
	catcher:Hide()

	frame = CreateFrame("Frame", "BGFPopupMenu", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
		})
		frame:SetBackdropColor(0.04, 0.035, 0.03, 0.96)
		frame:SetBackdropBorderColor(0.55, 0.45, 0.28, 1)
	end
	frame:SetScript("OnHide", function()
		if catcher then catcher:Hide() end
	end)
	frame:Hide()
	Popup.CloseOnEscape(frame, close)
end

local function row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, frame)
	r:SetHeight(ROW_H)
	r.Highlight = r:CreateTexture(nil, "HIGHLIGHT")
	r.Highlight:SetAllPoints()
	r.Highlight:SetColorTexture(1, 0.82, 0, 0.12)
	r.Dot = r:CreateTexture(nil, "ARTWORK")
	r.Dot:SetTexture("Interface\\AddOns\\BetterGroupFinder\\Media\\Circle")
	r.Dot:SetSize(7, 7)
	r.Dot:SetPoint("LEFT", PAD - 2, 0)
	r.Text = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	r.Text:SetJustifyH("LEFT")
	r.Text:SetWordWrap(false)
	r.Line = r:CreateTexture(nil, "ARTWORK")
	r.Line:SetColorTexture(0.55, 0.45, 0.28, 0.6)
	r.Line:SetHeight(1)
	r.Line:SetPoint("LEFT", PAD, 0)
	r.Line:SetPoint("RIGHT", -PAD, 0)
	r:SetScript("OnEnter", function(self)
		if self.item and self.item.tooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			self.item.tooltip(GameTooltip)
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	r:SetScript("OnClick", function(self)
		local item = self.item
		if not item or item.kind ~= "button" then return end
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		close()
		if item.fn then item.fn() end
	end)
	rows[i] = r
	return r
end

-- Opens the menu below `owner` (toggles when it is already open for the same owner).
function Popup.Open(owner, items)
	if not frame then create() end
	if frame:IsShown() and Popup.owner == owner then close() return end
	Popup.owner = owner
	Popup.current = items
	local width, y = 120, -6
	for i, item in ipairs(items) do
		local r = row(i)
		r.item = item
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 0, y)
		r:SetPoint("TOPRIGHT", 0, y)
		r.Line:SetShown(item.kind == "divider")
		r.Text:SetShown(item.kind ~= "divider")
		r.Dot:SetShown(item.checked ~= nil)
		if item.checked ~= nil then
			r.Dot:SetVertexColor(item.checked and 1 or 0.35, item.checked and 0.82 or 0.33, item.checked and 0 or 0.3)
		end
		r:EnableMouse(item.kind == "button" or item.tooltip ~= nil)
		if item.kind == "divider" then
			r:SetHeight(9)
			y = y - 9
		else
			r:SetHeight(ROW_H)
			r.Text:SetFontObject(item.fontObject or (item.kind == "button" and GameFontHighlight or GameFontNormal))
			r.Text:SetText((item.indent and "    " or "") .. (item.text or ""))
			if item.kind == "title" then
				r.Text:SetTextColor(1, 1, 1)
			elseif item.kind == "header" then
				r.Text:SetTextColor(1, 0.82, 0)
			else
				r.Text:SetTextColor(1, 1, 1)
			end
			r.Text:ClearAllPoints()
			r.Text:SetPoint("LEFT", PAD + (item.checked ~= nil and 10 or 0), 0)
			width = math.max(width, (r.Text:GetStringWidth() or 0) + 2 * PAD + (item.checked ~= nil and 10 or 0))
			y = y - ROW_H
		end
		r:Show()
	end
	for i = #items + 1, #rows do rows[i]:Hide() end
	frame:SetSize(math.ceil(width), -y + 6)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
	catcher:Show()
	frame:Show()
	frame:Raise()
end
