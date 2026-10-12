local _, ns = ...

--[[
Options: AddOns section of the game settings (falls back to a standalone window).
General switches, message templates per language, reset buttons.
]]

local Options = {}
ns.Options = Options

local panel, category
local editBoxes = {}
local nameBoxes = {}
local currentLang

local function createCheck(parent, text, getter, setter)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb.Label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	cb.Label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
	cb.Label:SetText(text)
	if ns.db then cb:SetChecked(getter() and true or false) end
	cb:SetScript("OnShow", function(self) self:SetChecked(getter() and true or false) end)
	cb:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) end)
	return cb
end

local function saveTemplate(lang, key, text)
	text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local default = (ns.DefaultTemplates[lang] or {})[key]
	ns.db.templates[lang] = ns.db.templates[lang] or {}
	if text == "" or text == default then
		ns.db.templates[lang][key] = nil
	else
		ns.db.templates[lang][key] = text
	end
end

local function saveName(lang, key, text)
	text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	ns.db.templateNames[lang] = ns.db.templateNames[lang] or {}
	local tone = key:match("_(%a+)$")
	if text == "" or text == ns.L["TONE_" .. (tone or "friendly")] then
		ns.db.templateNames[lang][key] = nil
	else
		ns.db.templateNames[lang][key] = text
	end
end

local function loadTemplates()
	for key, box in pairs(editBoxes) do
		box:SetText(ns.GetTemplate(currentLang, key))
		box:SetCursorPosition(0)
	end
	for key, box in pairs(nameBoxes) do
		box:SetText(ns.GetTemplateName(currentLang, key))
		box:SetCursorPosition(0)
	end
	local tp = Options.Pages and Options.Pages.templates
	if tp and tp.LangButtons then
		-- the chosen language: check mark and gold text, both buttons stay clickable
		for _, b in ipairs(tp.LangButtons) do
			local chosen = b.lang == currentLang
			b.Check:SetShown(chosen)
			local fs = b:GetFontString()
			if fs then
				if chosen then fs:SetTextColor(1, 0.82, 0) else fs:SetTextColor(0.85, 0.85, 0.85) end
			end
			if chosen and b.LockHighlight then b:LockHighlight() elseif b.UnlockHighlight then b:UnlockHighlight() end
		end
	end
end

-- Pages: main page plus three sub pages (Settings sub categories, like other addons).
local pages, pageOrder = {}, { "main", "display", "chips", "templates" }
local subcategories = {}

local function newPage(key, name)
	local p = CreateFrame("Frame", "BGFOptions_" .. key)
	p.name = name
	p.key = key
	local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(name)
	p.Title = title
	p:Hide()   -- the settings window shows it (OnShow then refreshes the values)
	pages[key] = p
	return p, title
end

local function button(parent, text, onClick, height)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetText(text)
	b:SetSize(b:GetFontString():GetStringWidth() + 30, height or 22)
	b:SetScript("OnClick", onClick)
	return b
end

-- Filter & Chips: hidden rows, categories and chips count as "ignored".
local function chipsChanged()
	if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
	ns.RequestRefresh()
	if pages.chips and pages.chips.Refresh then pages.chips.Refresh() end
end

local function buildChipsPage(p, title)
	local L = ns.L
	local COL_W, COLS = 165, 4
	local checks = {}
	local function track(cb, get, isEnabled)
		cb.get, cb.isEnabled = get, isEnabled
		checks[#checks + 1] = cb
		return cb
	end

	local enabled = createCheck(p, L.ENABLED,
		function() return ns.db.enabled end,
		function(v) ns.db.enabled = v if ns.UI.ApplyEnabled then ns.UI.ApplyEnabled() end end)
	enabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	track(enabled, function() return ns.db.enabled end)

	local header = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -14)
	header:SetText(L.OPT_CHIPS_TITLE)
	local hint = p:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	hint:SetWidth(COL_W * COLS)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.OPT_CHIPS_HINT)

	local y = -142
	local function check(x, text, get, set, isEnabled)
		local cb = createCheck(p, text, get, function(v) set(v) chipsChanged() end)
		cb:SetPoint("TOPLEFT", x, y)
		return track(cb, get, isEnabled)
	end
	local rows = p:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	rows:SetPoint("TOPLEFT", 20, y)
	rows:SetText(L.OPT_CHIPS_ROWS)
	y = y - 18
	check(16, L.OPT_CHIPS_FAVROW, function() return ns.db.showFavRow end, function(v) ns.db.showFavRow = v end)
	check(16 + COL_W * 2, L.OPT_CHIPS_ABILITYROW, function() return ns.db.showAbilityRow end,
		function(v) ns.db.showAbilityRow = v end)
	y = y - 30
	local inline = {}
	for _, cat in ipairs(ns.CATEGORY_ORDER) do
		if ns.INLINE_CATEGORIES[cat] then
			inline[#inline + 1] = cat
		else
			check(16, "|cffffd100" .. L["CAT_" .. cat] .. "|r", function() return not ns.db.hiddenCategories[cat] end,
				function(v) ns.db.hiddenCategories[cat] = (not v) or nil end)
			y = y - 24
			local col = 0
			for _, ability in ipairs(ns.ABILITIES) do
				if ability.category == cat then
					local id = ability.id
					check(36 + col * COL_W, ns.AbilityName(id), function() return not ns.db.hiddenChips[id] end,
						function(v) ns.db.hiddenChips[id] = (not v) or nil end,
						function() return not ns.db.hiddenCategories[cat] end)
					col = col + 1
					if col == COLS then col = 0 y = y - 22 end
				end
			end
			if col > 0 then y = y - 22 end
			y = y - 4
		end
	end
	-- chips without a category toggle (loot): one check each, no category header
	for _, cat in ipairs(inline) do
		for _, ability in ipairs(ns.ABILITIES) do
			if ability.category == cat then
				local id = ability.id
				check(16, id == "loot" and L.LOOT_TITLE or ns.AbilityName(id), function() return not ns.db.hiddenChips[id] end,
					function(v) ns.db.hiddenChips[id] = (not v) or nil end)
				y = y - 24
			end
		end
	end

	local showAll = button(p, L.OPT_CHIPS_SHOWALL, function()
		ns.db.showFavRow, ns.db.showAbilityRow = true, true
		ns.db.hiddenCategories, ns.db.hiddenChips = {}, {}
		chipsChanged()
	end)
	showAll:SetPoint("TOPLEFT", 20, y - 8)
	local resetFilters = button(p, L.OPT_RESET_FILTERS, function() ns.FilterBar.ResetFilters() end)
	resetFilters:SetPoint("LEFT", showAll, "RIGHT", 8, 0)
	local restoreBuiltIn = button(p, L.OPT_RESTORE_DEFAULTS, function() ns.FilterBar.RestoreBuiltIn() end)
	restoreBuiltIn:SetPoint("LEFT", resetFilters, "RIGHT", 8, 0)
	restoreBuiltIn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L.OPT_RESTORE_DEFAULTS, 1, 0.82, 0)
		GameTooltip:AddLine(L.OPT_RESTORE_DEFAULTS_TT, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	restoreBuiltIn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	p.ShowAll, p.ResetFilters, p.RestoreBuiltIn = showAll, resetFilters, restoreBuiltIn
	p.Checks = checks

	p.Refresh = function()
		for _, cb in ipairs(checks) do
			cb:SetChecked(cb.get() and true or false)
			local on = not cb.isEnabled or cb.isEnabled()
			cb:SetEnabled(on)
			cb.Label:SetAlpha(on and 1 or 0.4)
		end
	end
	p:SetScript("OnShow", p.Refresh)
	p.Init = p.Refresh
end

local function buildTemplatesPage(p, title)
	local L = ns.L
	local autoSend = createCheck(p, L.OPT_AUTOSEND,
		function() return ns.db.autoSend end, function(v) ns.db.autoSend = v end)
	autoSend:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)

	local langLabel = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	langLabel:SetPoint("TOPLEFT", autoSend, "BOTTOMLEFT", 4, -14)
	langLabel:SetText(L.OPT_LANGUAGE)

	p.LangButtons = {}
	local prev
	for i, lang in ipairs(ns.TemplateLanguages()) do
		local b = button(p, ns.LANGUAGE_NAMES[lang] or lang, function()
			currentLang = lang
			loadTemplates()
		end)
		b:SetWidth(math.max(80, b:GetFontString():GetStringWidth() + 40))
		b.Check = b:CreateTexture(nil, "OVERLAY")
		b.Check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		b.Check:SetSize(18, 18)
		b.Check:SetPoint("LEFT", 6, 0)
		b.Check:Hide()
		if i == 1 then
			b:SetPoint("LEFT", langLabel, "RIGHT", 8, 0)
		else
			b:SetPoint("LEFT", prev, "RIGHT", 4, 0)
		end
		b.lang = lang
		p.LangButtons[i] = b
		prev = b
	end

	local previousBox
	for _, key in ipairs(ns.TEMPLATE_KEYS) do
		local label = p:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		if previousBox then
			label:SetPoint("TOPLEFT", previousBox, "BOTTOMLEFT", -6, -10)
		else
			label:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -16)
		end
		label:SetText(L["OPT_T_" .. key] .. "  |cff808080(" .. L.OPT_NAME .. " / Text)|r")
		-- Name of the template (shown in the menu) and its text.
		local nameBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
		nameBox:SetSize(130, 22)
		nameBox:SetAutoFocus(false)
		nameBox:SetMaxLetters(40)
		nameBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 6, -2)
		nameBox:SetScript("OnEnterPressed", function(self)
			saveName(currentLang, key, self:GetText())
			self:ClearFocus()
		end)
		nameBox:SetScript("OnEditFocusLost", function(self)
			saveName(currentLang, key, self:GetText())
		end)
		nameBox:SetScript("OnEscapePressed", function(self)
			self:SetText(ns.GetTemplateName(currentLang, key))
			self:ClearFocus()
		end)
		nameBoxes[key] = nameBox

		local box = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
		box:SetSize(440, 22)
		box:SetAutoFocus(false)
		box:SetMaxLetters(255)
		box:SetPoint("LEFT", nameBox, "RIGHT", 12, 0)
		box:SetScript("OnEnterPressed", function(self)
			saveTemplate(currentLang, key, self:GetText())
			self:ClearFocus()
		end)
		box:SetScript("OnEditFocusLost", function(self)
			saveTemplate(currentLang, key, self:GetText())
		end)
		box:SetScript("OnEscapePressed", function(self)
			self:SetText(ns.GetTemplate(currentLang, key))
			self:ClearFocus()
		end)
		editBoxes[key] = box
		previousBox = nameBox
	end

	local hint = p:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", previousBox, "BOTTOMLEFT", -6, -8)
	hint:SetWidth(580)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.OPT_PLACEHOLDERS)

	local resetTemplates = button(p, L.OPT_RESET_TEMPLATES, function()
		ns.db.templates[currentLang] = nil
		ns.db.templateNames[currentLang] = nil
		loadTemplates()
	end, 24)
	resetTemplates:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)

	local function show()
		currentLang = currentLang or ns.clientLocale
		if not ns.DefaultTemplates[currentLang] then currentLang = "enUS" end
		loadTemplates()
	end
	p:SetScript("OnShow", show)
	p.Init = show
end

local function buildDisplayPage(p, title)
	local L = ns.L
	local scores = createCheck(p, L.OPT_SCORES,
		function() return ns.db.showScores end,
		function(v) ns.db.showScores = v ns.RequestRefresh() end)
	scores:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	local help = button(p, L.OPT_SCORE_HELP_BUTTON, function() Options.ShowScoreHelp() end)
	help:SetPoint("LEFT", scores.Label, "RIGHT", 16, 0)

	local reasons = createCheck(p, L.OPT_REASONS,
		function() return ns.db.showReasons end, function(v) ns.db.showReasons = v end)
	reasons:SetPoint("TOPLEFT", scores, "BOTTOMLEFT", 0, -4)

	-- Font
	local fontLabel = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fontLabel:SetPoint("TOPLEFT", reasons, "BOTTOMLEFT", 4, -16)
	fontLabel:SetText(L.OPT_FONT)
	local preview = p:CreateFontString(nil, "ARTWORK")
	local fontButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	fontButton:SetSize(200, 22)
	local function updatePreview()
		preview:SetFontObject(ns.Fonts.Get(12))
		-- the button shows the chosen font's name in that font
		if fontButton.SetNormalFontObject then
			pcall(fontButton.SetNormalFontObject, fontButton, ns.Fonts.Get(12))
			pcall(fontButton.SetHighlightFontObject, fontButton, ns.Fonts.Get(12))
		end
		preview:SetText("Höhlen des Wehklagens · Aldarin Schattentanz 26 · 46")
		preview:SetTextColor(1, 0.82, 0)
	end
	-- Own font list (not Blizzard's dropdown menu, see UI/Popup.lua); every entry is written
	-- in its own font.
	local function fontItems()
		local items = {}
		for _, f in ipairs(ns.Fonts.List()) do
			items[#items + 1] = {
				kind = "button", text = f.name, checked = ns.db.font == f.key, fontObject = ns.Fonts.GetFor(f.key, 12),
				fn = function()
					ns.Fonts.Set(f.key)
					fontButton:SetText(ns.Fonts.Name())
					updatePreview()
				end,
			}
		end
		return items
	end
	fontButton:SetScript("OnClick", function(self) ns.Popup.Open(self, fontItems()) end)
	fontButton:SetText(ns.Fonts.Name())
	fontButton:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)
	Options.FontItems = fontItems
	preview:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -14)
	p:SetScript("OnShow", updatePreview)
	p.Init = updatePreview
end

-- Main page: short description, the "What's new" switch and the release notes right on the
-- page (version badge to look at earlier releases), the slash commands at the bottom.
local function buildMainPage(p, title)
	local L = ns.L
	local WIDTH = 600
	title:SetText(L.OPT_TITLE .. "  |cff808080" .. ns.VERSION .. "|r")
	local desc = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	desc:SetWidth(WIDTH)
	desc:SetJustifyH("LEFT")
	desc:SetText(L.OPT_MAIN_DESC)

	local whatsNew = createCheck(p, L.OPT_WHATSNEW,
		function() return ns.db.showWhatsNew ~= false end, function(v) ns.db.showWhatsNew = v end)
	whatsNew:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -2, -12)

	local newsTitle = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	newsTitle:SetPoint("TOPLEFT", whatsNew, "BOTTOMLEFT", 2, -22)
	local items = {}
	local holder = CreateFrame("Frame", nil, p)
	holder:SetPoint("TOPLEFT", newsTitle, "BOTTOMLEFT", -20, -14)
	holder:SetSize(WIDTH + 20, 10)
	local slash = p:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	slash:SetWidth(WIDTH)
	slash:SetJustifyH("LEFT")
	slash:SetText(L.SLASH_HELP)

	local badge
	local function render(version)
		local page = ns.NEWS[version] or ns.NEWS[ns.NEWS_ORDER[1]]
		local texts = page[ns.NewsLang()] or page.enUS
		newsTitle:SetText(texts.title)
		badge:SetVersion(version)
		local y = 0
		for i, item in ipairs(texts.items) do
			local it = items[i] or ns.WhatsNew.NewItem(holder, WIDTH + 20)
			items[i] = it
			it:ClearAllPoints()
			it:SetPoint("TOPLEFT", 0, y)
			it:SetPoint("TOPRIGHT", 0, y)
			local h = ns.WhatsNew.FillItem(it, item, i == #texts.items)
			y = y - h - 26
		end
		for i = #texts.items + 1, #items do items[i]:Hide() end
		holder:SetHeight(-y)
		slash:ClearAllPoints()
		slash:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 20, -4)
		p.newsVersion = version
	end
	badge = ns.WhatsNew.NewBadge(p, render)
	badge:SetPoint("LEFT", newsTitle, "RIGHT", 14, 0)
	p.Badge = badge
	p.RenderNews = render
	p.Init = function() render(p.newsVersion or ns.VERSION) end
end

local container, containerTabs
local function build()
	local L = ns.L
	local main, mainTitle = newPage("main", L.OPT_TITLE)
	panel = main
	buildMainPage(main, mainTitle)
	buildDisplayPage(newPage("display", L.OPT_PAGE_display))
	buildChipsPage(newPage("chips", L.OPT_PAGE_chips))
	buildTemplatesPage(newPage("templates", L.OPT_PAGE_templates))
	for _, key in ipairs(pageOrder) do
		if pages[key].Init then pcall(pages[key].Init) end
	end

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, main, L.OPT_TITLE)
		if ok and cat then
			category = cat
			if Settings.RegisterCanvasLayoutSubcategory then
				for _, key in ipairs({ "display", "chips", "templates" }) do
					local okSub, subcat = pcall(Settings.RegisterCanvasLayoutSubcategory, cat, pages[key], pages[key].name)
					if okSub then subcategories[key] = subcat end
				end
			end
			pcall(Settings.RegisterAddOnCategory, cat)
			if Settings.RegisterCanvasLayoutSubcategory then return end
		end
	end
	-- Fallback: standalone window with one tab per page
	container = CreateFrame("Frame", "BGFOptionsWindow", UIParent, "BackdropTemplate")
	container:SetSize(700, 640)
	container:SetPoint("CENTER")
	container:SetFrameStrata("DIALOG")
	container:EnableMouse(true)
	container:SetMovable(true)
	container:RegisterForDrag("LeftButton")
	container:SetScript("OnDragStart", container.StartMoving)
	container:SetScript("OnDragStop", container.StopMovingOrSizing)
	local bg = container:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.05, 0.04, 0.03, 0.95)
	local close = CreateFrame("Button", nil, container, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	ns.Popup.CloseOnEscape(container)
	containerTabs = {}
	local prev
	for _, key in ipairs(pageOrder) do
		local p = pages[key]
		p:SetParent(container)
		p:ClearAllPoints()
		p:SetPoint("TOPLEFT", 0, -34)
		p:SetPoint("BOTTOMRIGHT")
		p:Hide()
		local tab = button(container, key == "main" and "BGF" or p.name, function() Options.Open(key) end)
		if prev then tab:SetPoint("LEFT", prev, "RIGHT", 4, 0) else tab:SetPoint("TOPLEFT", 10, -8) end
		containerTabs[key] = tab
		prev = tab
	end
	container:Hide()
end

-- Window explaining how the points are calculated.
-- OPT_SCORE_HELP uses a small line markup: "#tag Header" starts a section, "value|text" is
-- a row with a value column, other lines are paragraphs. The ability weights are generated.
local HELP_COLORS = {
	read   = { value = { 0.9, 0.9, 0.9 }, text = { 0.9, 0.9, 0.9 } },
	plus   = { value = { 0.3, 0.9, 0.3 }, text = { 0.9, 0.9, 0.9 } },
	weights = { value = { 1, 0.82, 0 }, text = { 0.9, 0.9, 0.9 } },
	minus  = { value = { 1, 0.35, 0.35 }, text = { 0.9, 0.9, 0.9 } },
	out    = { value = { 1, 0.6, 0.2 }, text = { 1, 0.6, 0.2 } },
	value  = { value = { 0.75, 0.75, 0.75 }, text = { 0.9, 0.9, 0.9 } },
	off    = { value = { 0.6, 0.6, 0.6 }, text = { 0.6, 0.6, 0.6 } },
}
Options.HELP_COLORS = HELP_COLORS

function Options.ParseHelp(text)
	local items, tag = {}, "read"
	for line in (text or ""):gmatch("[^\n]+") do
		local t, header = line:match("^#(%a+)%s+(.*)$")
		if t then
			tag = t
			items[#items + 1] = { kind = "header", tag = t, text = header }
			if t == "weights" then
				-- one row per weight, highest first: "10 | Kontrolle", "6 | Fluch entfernen, ..."
				local byWeight, weights = {}, {}
				local function add(weight, name)
					if not byWeight[weight] then
						byWeight[weight] = {}
						weights[#weights + 1] = weight
					end
					table.insert(byWeight[weight], name)
				end
				for _, ability in ipairs(ns.ABILITIES) do
					if not ability.class and not ability.special then add(ability.weight, ns.AbilityName(ability.id)) end
				end
				add(ns.CLASS_WEIGHT, ns.L.CLASS_WEIGHT_ROW)
				table.sort(weights, function(x, y) return x > y end)
				for _, w in ipairs(weights) do
					items[#items + 1] = { kind = "row", tag = t, value = tostring(w), text = table.concat(byWeight[w], ", ") }
				end
			end
		else
			local value, rest = line:match("^([^|]*)|(.*)$")
			if value then
				items[#items + 1] = { kind = "row", tag = tag, value = value, text = rest }
			else
				items[#items + 1] = { kind = "para", tag = tag, text = line }
			end
		end
	end
	return items
end

local helpFrame
function Options.ShowScoreHelp()
	if not helpFrame then
		local L = ns.L
		local WIDTH, VALUE_W, GAP = 520, 44, 8
		helpFrame = CreateFrame("Frame", "BGFScoreHelp", UIParent, "BackdropTemplate")
		helpFrame:SetSize(WIDTH + 52, 470)
		helpFrame:SetPoint("CENTER")
		helpFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		helpFrame:EnableMouse(true)
		helpFrame:SetMovable(true)
		helpFrame:RegisterForDrag("LeftButton")
		helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
		helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
		helpFrame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
		})
		helpFrame:SetBackdropColor(0.05, 0.04, 0.03, 0.97)
		helpFrame:SetBackdropBorderColor(0.6, 0.48, 0.25, 1)
		local title = helpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -14)
		title:SetText(L.OPT_SCORE_HELP_TITLE)

		local okScroll, scroll = pcall(CreateFrame, "ScrollFrame", nil, helpFrame, "UIPanelScrollFrameTemplate")
		if not okScroll or not scroll then
			scroll = CreateFrame("ScrollFrame", nil, helpFrame)
			scroll:EnableMouseWheel(true)
			scroll:SetScript("OnMouseWheel", function(self, delta)
				local max = self:GetVerticalScrollRange() or 0
				self:SetVerticalScroll(math.max(0, math.min(max, (self:GetVerticalScroll() or 0) - delta * 40)))
			end)
		end
		scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
		scroll:SetPoint("BOTTOMRIGHT", -30, 12)
		local content = CreateFrame("Frame", nil, scroll)
		content:SetWidth(WIDTH)
		scroll:SetScrollChild(content)
		helpFrame.Items = {}

		local y = 0
		local function height(fs) return math.max(fs:GetStringHeight() or 0, 14) end
		for i, item in ipairs(Options.ParseHelp(L.OPT_SCORE_HELP)) do
			local colors = HELP_COLORS[item.tag] or HELP_COLORS.read
			if item.kind == "header" then
				if i > 1 then y = y + 12 end
				local fs = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				fs:SetPoint("TOPLEFT", 0, -y)
				fs:SetWidth(WIDTH)
				fs:SetJustifyH("LEFT")
				fs:SetText(item.text)
				y = y + height(fs) + 4
				item.fs = fs
			elseif item.kind == "row" then
				local v = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				v:SetPoint("TOPLEFT", 0, -y)
				v:SetWidth(VALUE_W)
				v:SetJustifyH("RIGHT")
				v:SetText(item.value)
				v:SetTextColor(unpack(colors.value))
				local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				fs:SetPoint("TOPLEFT", VALUE_W + GAP, -y)
				fs:SetWidth(WIDTH - VALUE_W - GAP)
				fs:SetJustifyH("LEFT")
				fs:SetText(item.text)
				fs:SetTextColor(unpack(item.value == "" and HELP_COLORS.off.text or colors.text))
				y = y + math.max(height(fs), height(v)) + 3
				item.fs, item.valueFS = fs, v
			else
				local fs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				fs:SetPoint("TOPLEFT", 0, -y)
				fs:SetWidth(WIDTH)
				fs:SetJustifyH("LEFT")
				fs:SetSpacing(2)
				fs:SetText(item.text)
				fs:SetTextColor(unpack(colors.text))
				y = y + height(fs) + 3
				item.fs = fs
			end
			helpFrame.Items[#helpFrame.Items + 1] = item
		end
		content:SetHeight(y)
		local maxH = ((UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768) - 120
		helpFrame:SetHeight(math.max(200, math.min(y + 60, maxH)))

		local close = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)
		ns.Popup.CloseOnEscape(helpFrame)
	end
	helpFrame:Show()
	return helpFrame
end

-- Opens the options, optionally on a sub page ("display", "chips", "templates").
function Options.Open(key)
	if not panel then build() end
	key = (key and pages[key]) and key or "main"
	local target = (key ~= "main" and subcategories[key]) or category
	if target and Settings and Settings.OpenToCategory then
		local id = target.GetID and target:GetID() or target.ID
		local ok = pcall(Settings.OpenToCategory, id)
		if ok then return end
	end
	if container then
		for k, p in pairs(pages) do
			p:SetShown(k == key)
			if containerTabs[k] then containerTabs[k]:SetEnabled(k ~= key) end
		end
		container:Show()
	end
end
Options.Pages = pages

-- Register the settings category once the saved variables are ready.
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	if not panel then
		local ok, err = pcall(build)
		if not ok then ns.Debug("options build failed: " .. tostring(err)) end
	end
end)
