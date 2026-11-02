local _, ns = ...

--[[
Introduction tour (1.0.0): a small window with six pages (points, chips, tooltip, filter bar,
templates, options + Discord). Shown once at login instead of "What's new" when
BetterGroupFinderDB.tourSeen is missing: new installs, and with 1.0.0 every existing user once.
Restart from the options main page.

Only BGF's own frames: nothing is drawn over Blizzard's Group Finder (taint). The pictures are
built from plain frames, textures and font strings, so they speak the client language and use
the real chip, role and button names. Texts: Data/Tour.lua (German or English).
]]

local Tour = {}
ns.Tour = Tour

local WIDTH, HEIGHT, PAD = 560, 420, 22
local BOX_Y, BOX_W, BOX_H = -64, 516, 170
local CIRCLE = "Interface\\AddOns\\BetterGroupFinder\\Media\\Circle"
local GOLD = { 1, 0.82, 0 }
local TEXT = { 0.92, 0.9, 0.86 }
local GREY = { 0.62, 0.62, 0.62 }
local GREEN = { 0.47, 0.82, 0.47 }

local frame
local pictures = {}
Tour.pictures = pictures

-------------------------------------------------------------------------------
-- Small drawing helpers for the pictures
-------------------------------------------------------------------------------

local function fs(parent, template, color, x, y, text)
	local s = parent:CreateFontString(nil, "ARTWORK", template)
	s:SetJustifyH("LEFT")
	if color then s:SetTextColor(color[1], color[2], color[3]) end
	if x then s:SetPoint("TOPLEFT", x, y) end
	if text then s:SetText(text) end
	return s
end

local function box(parent, x, y, w, h, bg, border)
	local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	b:SetPoint("TOPLEFT", x, y)
	b:SetSize(w, h)
	if b.SetBackdrop then
		b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
		b:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
	end
	return b
end

local function dot(parent, x, y, size, r, g, b, a)
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetTexture(CIRCLE)
	t:SetSize(size, size)
	t:SetPoint("TOPLEFT", x, y)
	t:SetVertexColor(r, g, b, a or 1)
	return t
end

-- A real filter bar chip ("ignore", "pref", "need"), placed at x/y; returns the next x.
local function chip(parent, x, y, label, state, star)
	local c = ns.FilterBar.PreviewChip(parent, label, state, star)
	c:SetPoint("TOPLEFT", x, y)
	return x + math.ceil(c:GetWidth() or 40) + 5
end

local function fakeButton(parent, x, y, w, label, primary)
	local b = box(parent, x, y, w, 22, primary and { 0.27, 0.07, 0.05 } or { 0.2, 0.16, 0.11 }, { 0.6, 0.48, 0.25 })
	local t = fs(b, "GameFontHighlightSmall", primary and GOLD or TEXT)
	t:SetPoint("CENTER")
	t:SetText(label)
	return b
end

-------------------------------------------------------------------------------
-- The six pictures (each one built once, on first use)
-------------------------------------------------------------------------------

local SCORE_GREEN, SCORE_YELLOW = { 0.12, 1, 0.12 }, { 1, 0.82, 0 }
local ROLE_DOTS = { { 0.27, 0.47, 0.86 }, { 0.24, 0.67, 0.31 }, { 0.78, 0.27, 0.24 }, { 0.78, 0.27, 0.24 }, { 0.78, 0.27, 0.24 } }

local DRAW = {}

function DRAW.points(p, s)
	for i, row in ipairs(s.rows) do
		local y = -14 - (i - 1) * 50
		local r = box(p, 16, y, BOX_W - 32, 42, i == 1 and { 0.18, 0.14, 0.1 } or { 0.13, 0.11, 0.07 }, { 0.31, 0.25, 0.16 })
		fs(r, "GameFontHighlight", TEXT, 12, -6, row[1])
		fs(r, "GameFontDisableSmall", GREY, 12, -24, row[2])
		local filled = ({ 3, 2, 4 })[i]
		for k, col in ipairs(ROLE_DOTS) do
			dot(r, 270 + (k - 1) * 22, -12, 16, col[1], col[2], col[3], k <= filled and 1 or 0.25)
		end
		local score = fs(r, "GameFontNormalLarge")
		score:SetPoint("RIGHT", -14, 0)
		score:SetText(tostring(row[3]))
		local c = row[3] >= 40 and SCORE_GREEN or (row[3] >= 15 and SCORE_YELLOW or GREY)
		score:SetTextColor(c[1], c[2], c[3])
	end
end

function DRAW.chips(p, s)
	fs(p, "GameFontDisableSmall", GREY, 18, -16, s.states)
	local x = 18
	x = chip(p, x, -38, s.ignored, "ignore")
	x = chip(p, x, -38, s.preferred, "pref")
	chip(p, x, -38, s.required, "need")
	fs(p, "GameFontDisableSmall", GREY, 18, -84, s.favorites)
	x = 18
	for _, c in ipairs({ { "cc", "need" }, { "interrupt", "pref" }, { "battleres", "ignore" }, { "buff_crit", "ignore" } }) do
		x = chip(p, x, -106, ns.AbilityName(c[1]), c[2], true)
	end
end

function DRAW.tooltip(p, s)
	local key = box(p, 24, -60, 78, 36, { 0.24, 0.2, 0.15 }, { 0.6, 0.48, 0.25 })
	local k = fs(key, "GameFontNormal", GOLD)
	k:SetPoint("CENTER")
	k:SetText("Shift")
	local tip = box(p, 130, -10, 270, 150, { 0.04, 0.04, 0.09, 0.95 }, { 0.47, 0.47, 0.55 })
	fs(tip, "GameFontHighlight", TEXT, 12, -10, s.name)
	fs(tip, "GameFontHighlightSmall", SCORE_GREEN, 12, -30, s.score)
	for i, l in ipairs(s.lines) do fs(tip, "GameFontHighlightSmall", TEXT, 12, -52 - (i - 1) * 17, l) end
	fs(tip, "GameFontHighlightSmall", GREEN, 12, -124, ns.L.TT_SHIFT_HINT)
end

function DRAW.filter(p, s)
	local bar = box(p, 14, -12, BOX_W - 28, 108, { 0.13, 0.11, 0.07 }, { 0.31, 0.25, 0.16 })
	fs(bar, "GameFontNormalSmall", GOLD, 12, -8, s.roles)
	local x = 12
	x = chip(bar, x, -24, ns.RoleName("TANK"), "ignore")
	x = chip(bar, x, -24, ns.RoleName("HEALER"), "need")
	chip(bar, x, -24, ns.RoleName("DAMAGER"), "pref")
	fs(bar, "GameFontNormalSmall", GOLD, 12, -56, s.abilities)
	x = 12
	for i, label in ipairs(s.cats) do x = chip(bar, x, -72, label, i == 3 and "pref" or "ignore") end
	x = chip(bar, x, -72, ns.AbilityName("loot"), "ignore")
	chip(bar, x, -72, ns.AbilityName("zone"), "pref")
	fs(p, "GameFontDisableSmall", GREY, 20, -136, s.own)
	fakeButton(p, BOX_W - 214, -130, 96, ns.L.SAVE_SHORT)
	fakeButton(p, BOX_W - 110, -130, 96, ns.L.RESET_SHORT)
end

function DRAW.templates(p, s)
	-- the "Templates" button and the menu it opens
	fakeButton(p, 18, -130, 110, ns.L.REQUEST, true)
	local menu = box(p, 150, -10, 200, 128, { 0.04, 0.035, 0.03, 0.96 }, { 0.55, 0.45, 0.28 })
	fs(menu, "GameFontHighlight", { 1, 1, 1 }, 10, -8, s.menu)
	local sep = menu:CreateTexture(nil, "ARTWORK")
	sep:SetColorTexture(0.55, 0.45, 0.28, 0.6)
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 10, -28)
	sep:SetPoint("TOPRIGHT", -10, -28)
	fs(menu, "GameFontNormal", GOLD, 10, -36, s.lang)
	local lang = ns.NewsLang()
	fs(menu, "GameFontHighlight", TEXT, 26, -56, ns.GetTemplateName(lang, "join_friendly"))
	fs(menu, "GameFontHighlight", TEXT, 26, -76, ns.GetTemplateName(lang, "join_short"))
	fs(menu, "GameFontDisableSmall", GREY, 10, -102, "...")
	-- whisper preview
	local preview = fs(p, "GameFontHighlightSmall", { 1, 0.5, 1 }, 18, -150, s.preview)
	preview:SetWidth(BOX_W - 36)
end

function DRAW.discord(p, s)
	local logo = dot(p, 40, -40, 80, 0.35, 0.4, 0.95)
	local face = box(p, 58, -64, 44, 32, { 1, 1, 1 }, { 1, 1, 1 })
	dot(face, 10, -10, 8, 0.35, 0.4, 0.95)
	dot(face, 26, -10, 8, 0.35, 0.4, 0.95)
	p.Logo = logo
	fs(p, "GameFontNormalLarge", GOLD, 150, -36, s.head)
	fs(p, "GameFontHighlight", TEXT, 150, -62, s.line)
	local edit = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
	edit:SetSize(260, 22)
	edit:SetPoint("TOPLEFT", 156, -84)
	edit:SetAutoFocus(false)
	edit:SetText(ns.DISCORD_URL)
	edit:SetCursorPosition(0)
	-- read-only like the field in the options: typing puts the link back right away
	edit:SetScript("OnTextChanged", function(self, userInput)
		if userInput and self:GetText() ~= ns.DISCORD_URL then
			self:SetText(ns.DISCORD_URL)
			self:HighlightText()
		end
	end)
	edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	edit:SetScript("OnMouseUp", function(self) self:HighlightText() end)
	edit:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
		self:SetCursorPosition(0)
	end)
	edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	p.Edit = edit
	fs(p, "GameFontDisableSmall", GREY, 150, -114, ns.TourUI().copy)
end

local function picture(i, page)
	local p = pictures[i]
	if p then return p end
	p = CreateFrame("Frame", nil, frame.Box)
	p:SetAllPoints(frame.Box)
	local draw = DRAW[page.ill]
	if draw then
		local ok, err = pcall(draw, p, page.s or {})
		if not ok then ns.Debug("tour picture " .. tostring(page.ill) .. ": " .. tostring(err)) end
	end
	pictures[i] = p
	return p
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

local function button(label, w, fn, primary)
	local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	b:SetSize(w, 26)
	b:SetText(label)
	b:SetScript("OnClick", fn)
	if primary and b.GetFontString then
		local text = b:GetFontString()
		if text and text.SetTextColor then text:SetTextColor(1, 0.82, 0) end
	end
	return b
end

local function create()
	local u = ns.TourUI()
	frame = CreateFrame("Frame", "BGFTour", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, HEIGHT)
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

	frame.Title = fs(frame, "GameFontNormalHuge", GOLD, PAD, -18, u.title)
	frame.Counter = fs(frame, "GameFontDisable", GREY)
	frame.Counter:SetPoint("TOPRIGHT", -44, -24)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	frame.Close = close

	frame.Dots = {}
	for i = 1, #ns.TourPages() do
		frame.Dots[i] = dot(frame, PAD + (i - 1) * 14, -48, 8, 1, 1, 1)
	end

	frame.Box = box(frame, PAD, BOX_Y, BOX_W, BOX_H, { 0.15, 0.11, 0.08 }, { 0.35, 0.28, 0.18 })

	local textY = BOX_Y - BOX_H - 18
	frame.PageTitle = fs(frame, "GameFontNormalLarge", GOLD, PAD, textY)
	frame.Text = fs(frame, "GameFontHighlight", TEXT, PAD, textY - 28)
	frame.Text:SetWidth(WIDTH - 2 * PAD)
	frame.Text:SetWordWrap(true)
	frame.Tip = fs(frame, "GameFontHighlightSmall", GREEN)
	frame.Tip:SetWidth(WIDTH - 2 * PAD)

	frame.Line = frame:CreateTexture(nil, "ARTWORK")
	frame.Line:SetColorTexture(0.55, 0.44, 0.24, 0.6)
	frame.Line:SetHeight(1)
	frame.Line:SetPoint("BOTTOMLEFT", PAD, 54)
	frame.Line:SetPoint("BOTTOMRIGHT", -PAD, 54)

	frame.Next = button(u.next, 100, function() Tour.Go(frame.page + 1) end, true)
	frame.Next:SetPoint("BOTTOMRIGHT", -PAD, 16)
	frame.Back = button(u.back, 100, function() Tour.Go(frame.page - 1) end)
	frame.Back:SetPoint("RIGHT", frame.Next, "LEFT", -8, 0)
	frame.WhatsNew = button(u.whatsNew, 124, function()
		frame:Hide()
		if ns.WhatsNew then ns.WhatsNew.ShowPage(ns.VERSION) end
	end)
	frame.WhatsNew:SetPoint("BOTTOMLEFT", PAD, 16)
	frame.Options = button(u.options, 124, function() Tour.OpenOptions() end)
	frame.Options:SetPoint("LEFT", frame.WhatsNew, "RIGHT", 8, 0)

	frame:SetScript("OnHide", function() if ns.Popup then ns.Popup.Close() end end)
	ns.Popup.CloseOnEscape(frame)
	frame:Hide()
end

-- Shows page i (1..6).
function Tour.Go(i)
	if not frame then create() end
	local pages = ns.TourPages()
	if i < 1 or i > #pages then
		if i > #pages then frame:Hide() end
		return
	end
	frame.page = i
	local page = pages[i]
	local u = ns.TourUI()
	local last = i == #pages
	for k, p in pairs(pictures) do p:SetShown(k == i) end
	picture(i, page):Show()
	for k, d in ipairs(frame.Dots) do
		if k == i then d:SetVertexColor(1, 0.82, 0)
		elseif k < i then d:SetVertexColor(0.59, 0.47, 0.24)
		else d:SetVertexColor(0.27, 0.23, 0.16) end
	end
	frame.Counter:SetText(i .. " / " .. #pages)
	frame.PageTitle:SetText(page.title)
	frame.Text:SetText(page.text)
	frame.Tip:ClearAllPoints()
	frame.Tip:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -6)
	frame.Tip:SetText(page.tip and ("› " .. page.tip) or "")
	frame.Tip:SetShown(page.tip ~= nil)
	frame.Back:SetShown(i > 1)
	frame.Next:SetText(last and u.done or u.next)
	frame.WhatsNew:SetShown(last)
	frame.Options:SetShown(last)
	return frame
end

-- Opens the tour on its first page (login, or "Restart tour" in the options).
function Tour.Show()
	if ns.db then ns.db.tourSeen = true end
	local f = Tour.Go(1)
	f:Show()
	if f.Raise then f:Raise() end
	return f
end

-- Last page: the options (Blizzard's settings panel cannot open in combat).
function Tour.OpenOptions()
	if InCombatLockdown and InCombatLockdown() then
		ns.Print(ns.TourUI().combat)
		return
	end
	frame:Hide()
	if ns.Options and ns.Options.Open then ns.Options.Open() end
end

-- The tour replaces "What's new" once: for new installs, and with 1.0.0 for everybody.
function Tour.Due()
	return ns.db ~= nil and not ns.db.tourSeen
end
