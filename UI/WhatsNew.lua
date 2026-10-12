local _, ns = ...

--[[
"What's new" window: shown once per new version right at login (together with other
addons, no delay; after combat if you log in fighting). New users get the welcome page.
The version badge opens a list of all releases. Can be switched off in the window and in
the options. Texts: Data/News.lua (German for German clients, English otherwise).
]]

local News = {}
ns.WhatsNew = News

local WIDTH, PAD, ICON_SIZE = 560, 22, 40
local TEXT_X = PAD + ICON_SIZE + 16
local frame
local itemFrames = {}

local function ui() return ns.NEWS_UI[ns.NewsLang()] end

local function fontString(parent, template, r, g, b)
	local fs = parent:CreateFontString(nil, "ARTWORK", template)
	fs:SetJustifyH("LEFT")
	if r then fs:SetTextColor(r, g, b) end
	return fs
end

local function line(parent)
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetColorTexture(0.55, 0.44, 0.24, 0.6)
	t:SetHeight(1)
	return t
end

local function getItem(i)
	local it = itemFrames[i]
	if it then return it end
	it = CreateFrame("Frame", nil, frame)
	it.IconBorder = it:CreateTexture(nil, "BORDER")
	it.IconBorder:SetColorTexture(0.6, 0.48, 0.25, 1)
	it.IconBorder:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
	it.IconBorder:SetPoint("TOPLEFT", PAD - 2, 2)
	it.Icon = it:CreateTexture(nil, "ARTWORK")
	it.Icon:SetSize(ICON_SIZE, ICON_SIZE)
	it.Icon:SetPoint("TOPLEFT", PAD, 0)
	it.Title = fontString(it, "GameFontNormalLarge", 1, 0.82, 0)
	it.Title:SetPoint("TOPLEFT", TEXT_X, 0)
	it.Text = fontString(it, "GameFontHighlight", 0.92, 0.9, 0.86)
	it.Text:SetWidth(WIDTH - TEXT_X - PAD)
	it.Text:SetWordWrap(true)
	it.Tip = fontString(it, "GameFontHighlightSmall", 0.47, 0.82, 0.47)
	it.Tip:SetWidth(WIDTH - TEXT_X - PAD)
	it.Sep = line(it)
	itemFrames[i] = it
	return it
end

local function create()
	frame = CreateFrame("Frame", "BGFWhatsNew", UIParent, "BackdropTemplate")
	frame:SetWidth(WIDTH)
	frame:SetPoint("CENTER", 0, 60)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	if frame.SetBackdrop then
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
		frame:SetBackdropColor(0.05, 0.043, 0.035, 0.97)
		frame:SetBackdropBorderColor(0.6, 0.48, 0.25, 1)
	end
	-- warm glow at the top
	frame.Glow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	frame.Glow:SetPoint("TOPLEFT", 2, -2)
	frame.Glow:SetPoint("TOPRIGHT", -2, -2)
	frame.Glow:SetHeight(110)
	frame.Glow:SetColorTexture(0.22, 0.16, 0.06, 0.45)
	if frame.Glow.SetGradient and CreateColor then
		pcall(frame.Glow.SetGradient, frame.Glow, "VERTICAL", CreateColor(0.05, 0.04, 0.03, 0), CreateColor(0.25, 0.18, 0.07, 0.6))
	end

	frame.Logo = frame:CreateTexture(nil, "ARTWORK")
	frame.Logo:SetTexture("Interface\\AddOns\\BetterGroupFinder\\Media\\Logo")
	frame.Logo:SetSize(64, 64)
	frame.Logo:SetPoint("TOPLEFT", PAD, -18)
	frame.Title = fontString(frame, "GameFontNormalHuge", 1, 0.82, 0)
	frame.Title:SetPoint("TOPLEFT", frame.Logo, "TOPRIGHT", 14, -6)
	frame.Subtitle = fontString(frame, "GameFontDisable")
	frame.Subtitle:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 1, -6)

	-- version badge: click opens the list of releases
	local badge = CreateFrame("Button", nil, frame, "BackdropTemplate")
	badge:SetSize(96, 24)
	badge:SetPoint("TOPRIGHT", -44, -26)
	if badge.SetBackdrop then
		badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		badge:SetBackdropColor(0.12, 0.09, 0.03, 0.9)
		badge:SetBackdropBorderColor(1, 0.82, 0, 1)
	end
	badge.Text = fontString(badge, "GameFontNormal", 1, 0.82, 0)
	badge.Text:SetPoint("CENTER", -6, 0)
	badge.Arrow = badge:CreateTexture(nil, "ARTWORK")
	badge.Arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
	badge.Arrow:SetSize(18, 18)
	badge.Arrow:SetPoint("LEFT", badge.Text, "RIGHT", 0, -1)
	badge:SetScript("OnEnter", function(self)
		if self.SetBackdropColor then self:SetBackdropColor(0.25, 0.19, 0.05, 0.95) end
	end)
	badge:SetScript("OnLeave", function(self)
		if self.SetBackdropColor then self:SetBackdropColor(0.12, 0.09, 0.03, 0.9) end
	end)
	badge:SetScript("OnClick", function(self) News.OpenVersionMenu(self) end)
	frame.Badge = badge

	frame.TopLine = line(frame)
	frame.TopLine:SetPoint("TOPLEFT", PAD, -98)
	frame.TopLine:SetPoint("TOPRIGHT", -PAD, -98)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	-- footer
	frame.BottomLine = line(frame)
	frame.Check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	frame.Check:SetSize(24, 24)
	frame.Check:SetScript("OnClick", function(self)
		ns.db.showWhatsNew = self:GetChecked() and true or false
	end)
	frame.CheckText = fontString(frame, "GameFontHighlight")
	frame.CheckText:SetPoint("TOPLEFT", frame.Check, "TOPRIGHT", 4, -3)
	frame.CheckHint = fontString(frame, "GameFontDisableSmall")
	frame.CheckHint:SetPoint("TOPLEFT", frame.CheckText, "BOTTOMLEFT", 0, -2)

	frame.Ok = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.Ok:SetSize(130, 26)
	frame.Ok:SetScript("OnClick", function() frame:Hide() end)
	frame.OptionsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.OptionsButton:SetSize(130, 26)
	frame.OptionsButton:SetScript("OnClick", function()
		frame:Hide()
		local page = ns.NEWS[frame.version or ""]
		if ns.Options and ns.Options.Open then ns.Options.Open(page and page.options) end
	end)

	frame:SetScript("OnHide", function() if ns.Popup then ns.Popup.Close() end end)
	ns.Popup.CloseOnEscape(frame)
	frame:Hide()
end

-- Fills the window with the page of one version.
function News.ShowPage(version)
	if not frame then create() end
	local page = ns.NEWS[version] or ns.NEWS[ns.NEWS_ORDER[1]]
	version = ns.NEWS[version] and version or ns.NEWS_ORDER[1]
	local lang = ns.NewsLang()
	local texts = page[lang] or page.enUS
	local u = ui()
	frame.version = version
	frame.Title:SetText(texts.title)
	frame.Subtitle:SetText(u.subtitle)
	frame.Badge.Text:SetText("v" .. version)
	frame.Badge:SetWidth(math.ceil(frame.Badge.Text:GetStringWidth()) + 40)
	frame.CheckText:SetText(u.show)
	frame.CheckHint:SetText(u.hint)
	frame.Ok:SetText(u.ok)
	frame.OptionsButton:SetText(u.options)
	frame.Check:SetChecked(ns.db.showWhatsNew ~= false)

	local y = -116
	for i, item in ipairs(texts.items) do
		local it = getItem(i)
		it:ClearAllPoints()
		it:SetPoint("TOPLEFT", 0, y)
		it:SetPoint("TOPRIGHT", 0, y)
		it.Icon:SetTexture(item.icon)
		it.Title:SetText(item.title)
		it.Text:ClearAllPoints()
		it.Text:SetPoint("TOPLEFT", it.Title, "BOTTOMLEFT", 0, -6)
		it.Text:SetText(item.text)
		local h = (it.Title:GetStringHeight() or 16) + 6 + (it.Text:GetStringHeight() or 14)
		if item.tip then
			it.Tip:ClearAllPoints()
			it.Tip:SetPoint("TOPLEFT", it.Text, "BOTTOMLEFT", 0, -5)
			it.Tip:SetText("› " .. item.tip)
			it.Tip:Show()
			h = h + 5 + (it.Tip:GetStringHeight() or 12)
		else
			it.Tip:Hide()
		end
		h = math.max(h, ICON_SIZE)
		it:SetHeight(h)
		it.Sep:ClearAllPoints()
		it.Sep:SetPoint("TOPLEFT", TEXT_X, -(h + 12))
		it.Sep:SetPoint("TOPRIGHT", -PAD, -(h + 12))
		it.Sep:SetShown(i < #texts.items)
		it:Show()
		y = y - h - 26
	end
	for i = #texts.items + 1, #itemFrames do itemFrames[i]:Hide() end

	y = y + 4
	frame.BottomLine:ClearAllPoints()
	frame.BottomLine:SetPoint("TOPLEFT", PAD, y)
	frame.BottomLine:SetPoint("TOPRIGHT", -PAD, y)
	frame.Check:ClearAllPoints()
	frame.Check:SetPoint("TOPLEFT", PAD - 4, y - 14)
	frame.Ok:ClearAllPoints()
	frame.Ok:SetPoint("TOPRIGHT", -PAD, y - 16)
	frame.OptionsButton:ClearAllPoints()
	frame.OptionsButton:SetPoint("RIGHT", frame.Ok, "LEFT", -8, 0)
	frame:SetHeight(-y + 62)
	frame:Show()
	if frame.Raise then frame:Raise() end
	return frame
end

-- Version badge: all releases, the shown one marked.
function News.OpenVersionMenu(owner)
	local u = ui()
	local items = { { kind = "title", text = u.versions } }
	for i, v in ipairs(ns.NEWS_ORDER) do
		local note = (i == 1 and u.latest) or (v == ns.NEWS_FIRST and u.first) or nil
		items[#items + 1] = {
			kind = "button", checked = (frame and frame.version == v) or false,
			text = "v" .. v .. (note and ("  |cff9d9d9d" .. note .. "|r") or ""),
			fn = function() News.ShowPage(v) end,
		}
	end
	ns.Popup.Open(owner, items)
end

-- Which page belongs to this login: welcome for new users, the current version after an
-- update (once), nothing when switched off or already seen.
function News.PageForLogin()
	local db = ns.db
	if not db then return nil end
	local current = ns.VERSION
	if db.lastSeenVersion == current then return nil end
	local page
	if ns.isNewInstall then
		page = ns.NEWS_FIRST
	elseif db.showWhatsNew ~= false then
		page = ns.NEWS[current] and current or ns.NEWS_ORDER[1]
	end
	db.lastSeenVersion = current
	return page
end

local pending
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event, isLogin, isReload)
	if event == "PLAYER_ENTERING_WORLD" then
		-- only the first loading screen (login or /reload), not instances
		if not (isLogin or isReload) then return end
		local page = News.PageForLogin()
		if not page then return end
		if InCombatLockdown and InCombatLockdown() then
			pending = page
		else
			News.ShowPage(page)
		end
	elseif pending then
		local page = pending
		pending = nil
		News.ShowPage(page)
	end
end)
