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
	cb:SetScript("OnShow", function(self) self:SetChecked(getter()) end)
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
	if panel and panel.LangButtons then
		for _, b in ipairs(panel.LangButtons) do
			b:SetEnabled(b.lang ~= currentLang)
		end
	end
end

local function build()
	local L = ns.L
	panel = CreateFrame("Frame", "BGFOptionsPanel")
	panel.name = L.OPT_TITLE

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L.OPT_TITLE .. "  |cff808080" .. ns.VERSION .. "|r")

	local autoSend = createCheck(panel, L.OPT_AUTOSEND,
		function() return ns.db.autoSend end, function(v) ns.db.autoSend = v end)
	autoSend:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

	local reasons = createCheck(panel, L.OPT_REASONS,
		function() return ns.db.showReasons end, function(v) ns.db.showReasons = v end)
	reasons:SetPoint("TOPLEFT", autoSend, "BOTTOMLEFT", 0, -4)

	local scores = createCheck(panel, L.OPT_SCORES,
		function() return ns.db.showScores end,
		function(v) ns.db.showScores = v ns.RequestRefresh() end)
	scores:SetPoint("TOPLEFT", reasons, "BOTTOMLEFT", 0, -4)

	local help = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	help:SetText(L.OPT_SCORE_HELP_BUTTON)
	help:SetSize(help:GetFontString():GetStringWidth() + 30, 22)
	help:SetPoint("LEFT", scores.Label, "RIGHT", 16, 0)
	help:SetScript("OnClick", function() Options.ShowScoreHelp() end)

	local enabled = createCheck(panel, L.ENABLED,
		function() return ns.db.enabled end,
		function(v) ns.db.enabled = v if ns.UI.ApplyEnabled then ns.UI.ApplyEnabled() end end)
	enabled:SetPoint("TOPLEFT", scores, "BOTTOMLEFT", 0, -4)

	-- Font and font size
	local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fontLabel:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -14)
	fontLabel:SetText(L.OPT_FONT)
	local preview = panel:CreateFontString(nil, "ARTWORK")
	local function updatePreview()
		preview:SetFontObject(ns.Fonts.Get(12))
		preview:SetText("Höhlen des Wehklagens · Aldarin Schattentanz 26 · +46")
		preview:SetTextColor(1, 0.82, 0)
	end
	local okDropdown, fontButton = pcall(CreateFrame, "DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
	if okDropdown and fontButton and fontButton.SetupMenu then
		fontButton:SetWidth(200)
		fontButton:SetupMenu(function(_, root)
			for _, f in ipairs(ns.Fonts.List()) do
				root:CreateRadio(f.name, function() return ns.db.font == f.key end, function()
					ns.Fonts.Set(f.key)
					updatePreview()
				end)
			end
		end)
	else
		-- Fallback: button that cycles through the fonts
		fontButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		fontButton:SetSize(200, 22)
		fontButton:SetScript("OnClick", function(self)
			local list = ns.Fonts.List()
			local index = 1
			for i, f in ipairs(list) do if f.key == ns.db.font then index = i end end
			ns.Fonts.Set(list[index % #list + 1].key)
			self:SetText(ns.Fonts.Name())
			updatePreview()
		end)
		fontButton:SetText(ns.Fonts.Name())
	end
	fontButton:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)

	preview:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -14)
	panel.updateFontControls = function()
		updatePreview()
	end

	local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", -4, -18)
	header:SetText(L.OPT_TEMPLATES)

	local langLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	langLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
	langLabel:SetText(L.OPT_LANGUAGE)

	panel.LangButtons = {}
	local prev
	for i, lang in ipairs(ns.TemplateLanguages()) do
		local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		b:SetText(ns.LANGUAGE_NAMES[lang] or lang)
		b:SetSize(math.max(70, b:GetFontString():GetStringWidth() + 20), 22)
		if i == 1 then
			b:SetPoint("LEFT", langLabel, "RIGHT", 8, 0)
		else
			b:SetPoint("LEFT", prev, "RIGHT", 4, 0)
		end
		b.lang = lang
		b:SetScript("OnClick", function()
			currentLang = lang
			loadTemplates()
		end)
		panel.LangButtons[i] = b
		prev = b
	end

	local previousBox
	for _, key in ipairs(ns.TEMPLATE_KEYS) do
		local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		if previousBox then
			label:SetPoint("TOPLEFT", previousBox, "BOTTOMLEFT", -6, -10)
		else
			label:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -16)
		end
		label:SetText(L["OPT_T_" .. key] .. "  |cff808080(" .. L.OPT_NAME .. " / Text)|r")
		-- Name of the template (shown in the menu) and its text.
		local nameBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
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

		local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
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
	panel.lastBox = previousBox

	local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", panel.lastBox, "BOTTOMLEFT", -6, -8)
	hint:SetWidth(580)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.OPT_PLACEHOLDERS)

	local resetTemplates = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetTemplates:SetText(L.OPT_RESET_TEMPLATES)
	resetTemplates:SetSize(resetTemplates:GetFontString():GetStringWidth() + 30, 24)
	resetTemplates:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
	resetTemplates:SetScript("OnClick", function()
		ns.db.templates[currentLang] = nil
		ns.db.templateNames[currentLang] = nil
		loadTemplates()
	end)

	local resetFilters = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetFilters:SetText(L.OPT_RESET_FILTERS)
	resetFilters:SetSize(resetFilters:GetFontString():GetStringWidth() + 30, 24)
	resetFilters:SetPoint("LEFT", resetTemplates, "RIGHT", 8, 0)
	resetFilters:SetScript("OnClick", function()
		ns.FilterBar.ResetFilters()
	end)

	panel:SetScript("OnShow", function()
		panel.updateFontControls()
		currentLang = currentLang or ns.clientLocale
		if not ns.DefaultTemplates[currentLang] then currentLang = "enUS" end
		loadTemplates()
	end)

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, L.OPT_TITLE)
		if ok and cat then
			category = cat
			pcall(Settings.RegisterAddOnCategory, cat)
			return
		end
	end
	-- Fallback: standalone window
	panel:SetParent(UIParent)
	panel:SetSize(660, 700)
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("DIALOG")
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.05, 0.04, 0.03, 0.95)
	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	tinsert(UISpecialFrames, "BGFOptionsPanel")
	panel:Hide()
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
				for _, ability in ipairs(ns.ABILITIES) do
					if not byWeight[ability.weight] then
						byWeight[ability.weight] = {}
						weights[#weights + 1] = ability.weight
					end
					table.insert(byWeight[ability.weight], ns.AbilityName(ability.id))
				end
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
		tinsert(UISpecialFrames, "BGFScoreHelp")
	end
	helpFrame:Show()
	return helpFrame
end

function Options.Open()
	if not panel then build() end
	if category and Settings and Settings.OpenToCategory then
		local id = category.GetID and category:GetID() or category.ID
		local ok = pcall(Settings.OpenToCategory, id)
		if ok then return end
	end
	panel:Show()
end

-- Register the settings category once the saved variables are ready.
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	if not panel then
		local ok, err = pcall(build)
		if not ok then ns.Debug("options build failed: " .. tostring(err)) end
	end
end)
