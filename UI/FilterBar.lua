local ADDON_NAME, ns = ...

--[[
Filter bar under the Group Finder header (style of the approved mockup): rounded "pill"
chips, a dot for "required", a half dot for "preferred", a check mark on selected roles,
rarely used abilities behind "+ more". Opens with the filter button next to Refresh; the
window grows by the bar's height so the list keeps its size.
]]

local Bar = {}
ns.FilterBar = Bar

local CIRCLE = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Circle"
local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
-- Sizes follow the font size (default 12); the label column fits the longest label.
local LABEL_WIDTH = 96
local CHIP_HEIGHT = 20
local function updateSizes()
	CHIP_HEIGHT = 12 + 9
end
local CHIP_GAP = 5
local ROW_GAP = 7
local PADDING = 9

local CORE_ABILITIES = { cc = true, interrupt = true, curse = true, magic = true, poison = true, battleres = true, summon = true }

local C = {
	gold = { 1, 0.82, 0 },
	white = { 0.95, 0.92, 0.85 },
	grey = { 0.6, 0.57, 0.52 },
	dim = { 0.45, 0.42, 0.38 },
	green = { 0.67, 0.83, 0.45 },
}
local STYLES = {
	need   = { bg = { 0.17, 0.13, 0.05, 1 }, border = { 0.79, 0.64, 0.29, 1 }, text = C.gold },
	pref   = { bg = { 0.10, 0.08, 0.05, 1 }, border = { 0.42, 0.34, 0.22, 1 }, text = C.white },
	ignore = { bg = { 0.07, 0.055, 0.04, 1 }, border = { 0.26, 0.21, 0.15, 1 }, text = C.grey },
	more   = { bg = { 0.07, 0.055, 0.04, 1 }, border = { 0.30, 0.25, 0.18, 0.7 }, text = C.grey },
}
local NEXT_STATE = { ignore = "pref", pref = "need", need = "ignore" }

local function font(sizeOffset)
	return ns.Fonts.Get(12 + (sizeOffset or 0))
end

-------------------------------------------------------------------------------
-- Drawing helpers: pill shape and state markers from one circle texture
-------------------------------------------------------------------------------

local function pillLayer(frame, layer, sublevel)
	local l = frame:CreateTexture(nil, layer, nil, sublevel)
	l:SetTexture(CIRCLE)
	l:SetTexCoord(0, 0.5, 0, 1)
	local m = frame:CreateTexture(nil, layer, nil, sublevel)
	m:SetTexture(CIRCLE)
	m:SetTexCoord(0.49, 0.51, 0, 1)
	local r = frame:CreateTexture(nil, layer, nil, sublevel)
	r:SetTexture(CIRCLE)
	r:SetTexCoord(0.5, 1, 0, 1)
	return { l, m, r }
end

local function layoutPill(parts, frame, inset)
	local h = frame:GetHeight() - 2 * inset
	local l, m, r = parts[1], parts[2], parts[3]
	l:ClearAllPoints(); m:ClearAllPoints(); r:ClearAllPoints()
	l:SetSize(h / 2, h)
	r:SetSize(h / 2, h)
	l:SetPoint("LEFT", inset, 0)
	r:SetPoint("RIGHT", -inset, 0)
	m:SetPoint("TOPLEFT", l, "TOPRIGHT")
	m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
end

local function colorPill(parts, rgba)
	for _, t in ipairs(parts) do t:SetVertexColor(rgba[1], rgba[2], rgba[3], rgba[4] or 1) end
end

-- Marker: "need" = filled dot, "pref" = ring with left half filled.
local function createMarker(parent)
	local m = CreateFrame("Frame", nil, parent)
	m:SetSize(8, 8)
	m.Outer = m:CreateTexture(nil, "ARTWORK", nil, 1)
	m.Outer:SetTexture(CIRCLE)
	m.Outer:SetAllPoints()
	m.Inner = m:CreateTexture(nil, "ARTWORK", nil, 2)
	m.Inner:SetTexture(CIRCLE)
	m.Inner:SetPoint("CENTER")
	m.Inner:SetSize(5, 5)
	m.Half = m:CreateTexture(nil, "ARTWORK", nil, 3)
	m.Half:SetTexture(CIRCLE)
	m.Half:SetTexCoord(0, 0.5, 0, 1)
	m.Half:SetSize(2.5, 5)
	m.Half:SetPoint("RIGHT", m, "CENTER")
	return m
end

local function setMarker(m, state, color, bg)
	if state ~= "need" and state ~= "pref" then m:Hide() return end
	m.Outer:SetVertexColor(color[1], color[2], color[3])
	m.Inner:SetVertexColor(bg[1], bg[2], bg[3])
	m.Half:SetVertexColor(color[1], color[2], color[3])
	m.Inner:SetShown(state == "pref")
	m.Half:SetShown(state == "pref")
	m:Show()
end

-------------------------------------------------------------------------------
-- Chips
-------------------------------------------------------------------------------

local function createChip(parent, onClick)
	local chip = CreateFrame("Button", nil, parent)
	chip:SetHeight(CHIP_HEIGHT)
	chip.Border = pillLayer(chip, "BACKGROUND", 1)
	chip.Fill = pillLayer(chip, "BACKGROUND", 2)
	chip.Text = chip:CreateFontString(nil, "ARTWORK")
	chip.Text:SetFontObject(font())
	chip.Marker = createMarker(chip)
	chip.Check = chip:CreateTexture(nil, "ARTWORK")
	chip.Check:SetTexture(CHECK)
	chip.Check:SetSize(14, 14)
	chip.Check:Hide()
	chip:SetScript("OnClick", function(self)
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		onClick(self)
	end)
	chip:SetScript("OnEnter", function(self)
		self.hover = true
		Bar.StyleChip(self)
		if self.ability then Bar.ShowAbilityTooltip(self) end
	end)
	chip:SetScript("OnLeave", function(self)
		self.hover = false
		Bar.StyleChip(self)
		GameTooltip:Hide()
	end)
	return chip
end

-- Sizes and colors one chip from its text, state and marker/check.
function Bar.StyleChip(chip)
	local s = STYLES[chip.state or "ignore"] or STYLES.ignore
	chip:SetHeight(CHIP_HEIGHT)
	chip.Text:SetFontObject(font())
	chip.Text:SetText(chip.label or "")
	local textW = math.ceil(chip.Text:GetStringWidth())
	local extra = 0
	chip.Check:Hide()
	if chip.showCheck and chip.state == "need" then
		extra = 12
		chip.Check:Show()
	end
	if chip.markerState then extra = 12 end
	chip:SetWidth(textW + 20 + extra)
	chip.Text:ClearAllPoints()
	chip.Text:SetPoint("LEFT", 10, 0)
	chip.Check:ClearAllPoints()
	chip.Check:SetPoint("LEFT", chip.Text, "RIGHT", 0, 0)
	chip.Marker:ClearAllPoints()
	chip.Marker:SetPoint("LEFT", chip.Text, "RIGHT", 4, 0)
	layoutPill(chip.Border, chip, 0)
	layoutPill(chip.Fill, chip, 1)
	local border = s.border
	if chip.hover and chip:IsEnabled() then
		border = { math.min(border[1] + 0.15, 1), math.min(border[2] + 0.13, 1), math.min(border[3] + 0.08, 1), 1 }
	end
	colorPill(chip.Border, border)
	colorPill(chip.Fill, s.bg)
	chip.Text:SetTextColor(s.text[1], s.text[2], s.text[3])
	chip.Check:SetVertexColor(s.text[1], s.text[2], s.text[3])
	setMarker(chip.Marker, chip.markerState, s.text, s.bg)
end

local function text(parent, color, sizeOffset)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	fs:SetFontObject(font(sizeOffset))
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(false)
	fs.color = color
	fs:SetTextColor(color[1], color[2], color[3])
	return fs
end

-- Tooltip: "Class – Spell from level N (condition)" per spell, sorted by class and level.
-- Chips named after a class leave out the class prefix.
function Bar.AbilitySources(id)
	local L = ns.L
	local ability = ns.ABILITY_BY_ID[id]
	local lines = {}
	for _, class in ipairs(ns.CLASS_ORDER) do
		if not (ability and ability.class and ability.class ~= class) then
			local entries = {}
			for _, e in ipairs(ns.CLASS_ABILITIES[class] or {}) do
				if e.a == id then entries[#entries + 1] = e end
			end
			table.sort(entries, function(x, y) return x.level < y.level end)
			for _, e in ipairs(entries) do
				local spell = ns.SpellName(e.sp)
				local line
				if ability and ability.class then
					line = L.CHIP_TT_SPELL:format(spell, e.level)
				else
					local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
					local name = ns.ClassName(class)
					if c then
						name = ("|cff%02x%02x%02x%s|r"):format(math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255), name)
					end
					line = L.CHIP_TT_LINE:format(name, spell, e.level)
				end
				if e.cond then
					line = line .. " (" .. L["COND_" .. e.cond] .. ")"
				elseif e.possible and not e.partial then
					line = line .. " " .. L.CHIP_TT_POSSIBLE
				end
				lines[#lines + 1] = { text = line, class = class, level = e.level }
			end
		end
	end
	return lines
end

function Bar.ShowAbilityTooltip(chip)
	GameTooltip:SetOwner(chip, "ANCHOR_TOP")
	GameTooltip:SetText(ns.AbilityName(chip.ability), 1, 0.82, 0)
	for _, line in ipairs(Bar.AbilitySources(chip.ability)) do
		GameTooltip:AddLine(line.text, 1, 1, 1)
	end
	GameTooltip:AddLine(ns.L.CHIP_TT_CLICK, 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

-- Profile currently edited by the ability chips: follows the category dropdown.
function Bar.CurrentProfile()
	local cat
	local dropdown = LFGBrowseFrame and LFGBrowseFrame.CategoryDropdown
	if dropdown and dropdown.GetValue then
		local ok, value = pcall(dropdown.GetValue, dropdown)
		if ok then cat = value end
	end
	if cat == 114 then return "raid" end
	if cat == 2 or cat == nil then return "dungeon" end
	return "other"
end

-------------------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------------------

function Bar.Create(parent)
	local L = ns.L
	local f = CreateFrame("Frame", "BGFFilterBar", parent)
	Bar.frame = f
	f:Hide()

	f.Bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
	f.Bg:SetPoint("TOPLEFT", 1, -1)
	f.Bg:SetPoint("BOTTOMRIGHT", -1, 1)
	f.Bg:SetColorTexture(0.045, 0.035, 0.025, 0.94)
	f.Edge = f:CreateTexture(nil, "BACKGROUND", nil, -3)
	f.Edge:SetAllPoints()
	f.Edge:SetColorTexture(0.24, 0.19, 0.13, 1)

	-- Row 1
	f.Enable = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	f.Enable:SetSize(22, 22)
	f.Enable:SetScript("OnClick", function(self)
		ns.db.enabled = self:GetChecked() and true or false
		ns.UI.ApplyEnabled()
	end)
	f.EnableText = text(f, C.gold)
	f.EnableText:SetText(L.ENABLED)
	f.Separator = text(f, C.dim)
	f.Separator:SetText("|")
	f.RatingLabel = text(f, C.grey)
	f.RatingLabel:SetText(L.RATING_FOR)
	f.RatingValue = text(f, C.green)
	f.ProfileValue = text(f, C.white)
	f.ProfileValue:SetJustifyH("RIGHT")
	f.ProfileLabel = text(f, C.grey)
	f.ProfileLabel:SetText(L.PROFILE)

	-- Row 2: roles
	f.RolesLabel = text(f, C.white)
	f.RoleChips = {}
	for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
		local chip = createChip(f, function() Bar.ToggleRole(role) end)
		chip.role = role
		chip.showCheck = true
		local words = ns.Words[ns.clientLocale] or ns.Words.enUS
		chip.label = words.roles[role]:gsub("^%l", string.upper)
		f.RoleChips[#f.RoleChips + 1] = chip
	end
	f.RolesHint = text(f, C.dim)
	f.RolesHint:SetJustifyH("RIGHT")
	f.RolesHint:SetText(L.ROLES_HINT)

	-- Row 3: abilities
	f.AbilitiesLabel = text(f, C.white)
	f.AbilitiesLabel:SetText(L.ABILITIES)
	f.AbilityChips = {}
	for _, ability in ipairs(ns.ABILITIES) do
		local chip = createChip(f, function() Bar.CycleAbility(ability.id) end)
		chip.ability = ability.id
		chip.label = ns.AbilityName(ability.id)
		f.AbilityChips[#f.AbilityChips + 1] = chip
	end
	f.More = createChip(f, function()
		ns.db.showAllAbilities = not ns.db.showAllAbilities
		ns.UI.ApplyLayout()
	end)
	f.More.state = "more"

	-- Legend
	f.LegendNeed = createMarker(f)
	f.LegendNeedText = text(f, C.dim)
	f.LegendNeedText:SetText(L.LEGEND_NEED)
	f.LegendDot = text(f, C.dim)
	f.LegendDot:SetText("·")
	f.LegendPref = createMarker(f)
	f.LegendPrefText = text(f, C.dim)
	f.LegendPrefText:SetText(L.LEGEND_PREF)

	return f
end

function Bar.ApplyFonts()
	local f = Bar.frame
	if not f then return end
	for _, fs in ipairs({ f.EnableText, f.Separator, f.RatingLabel, f.RatingValue, f.ProfileLabel, f.ProfileValue,
		f.RolesLabel, f.RolesHint, f.AbilitiesLabel, f.LegendNeedText, f.LegendDot, f.LegendPrefText }) do
		fs:SetFontObject(font())
	end
end

local function visibleAbility(chip, states)
	if ns.db.showAllAbilities then return true end
	return CORE_ABILITIES[chip.ability] or (states[chip.ability] or "ignore") ~= "ignore"
end

-- Lays out all rows for the current width; returns the bar height.
function Bar.Layout()
	local f = Bar.frame
	if not f then return 0 end
	updateSizes()
	Bar.ApplyFonts()
	Bar.Update()
	LABEL_WIDTH = PADDING + 12 + math.ceil(math.max(f.RolesLabel:GetStringWidth(), f.AbilitiesLabel:GetStringWidth()))
	local width = f:GetWidth()
	if not width or width < 100 then width = 442 end
	local y = -PADDING + 1

	-- row 1
	f.Enable:ClearAllPoints()
	f.Enable:SetPoint("TOPLEFT", PADDING - 4, y + 2)
	f.EnableText:ClearAllPoints()
	f.EnableText:SetPoint("LEFT", f.Enable, "RIGHT", 1, 0)
	f.Separator:ClearAllPoints()
	f.Separator:SetPoint("LEFT", f.EnableText, "RIGHT", 7, 0)
	f.RatingLabel:ClearAllPoints()
	f.RatingLabel:SetPoint("LEFT", f.Separator, "RIGHT", 7, 0)
	f.ProfileValue:ClearAllPoints()
	f.ProfileValue:SetPoint("RIGHT", f, "TOPRIGHT", -PADDING, y - 9)
	f.ProfileLabel:ClearAllPoints()
	f.ProfileLabel:SetPoint("RIGHT", f.ProfileValue, "LEFT", -4, 0)
	-- Not enough room (large font, long translation): drop the "Rating for:" label first.
	local leftW = 24 + f.EnableText:GetStringWidth() + 14 + f.Separator:GetStringWidth()
		+ f.RatingLabel:GetStringWidth() + 4 + f.RatingValue:GetStringWidth()
	local rightW = f.ProfileLabel:GetStringWidth() + 4 + f.ProfileValue:GetStringWidth()
	local tight = leftW + rightW + 2 * PADDING + 12 > width
	f.RatingLabel:SetShown(not tight)
	f.RatingValue:ClearAllPoints()
	if tight then
		f.RatingValue:SetPoint("LEFT", f.Separator, "RIGHT", 7, 0)
	else
		f.RatingValue:SetPoint("LEFT", f.RatingLabel, "RIGHT", 4, 0)
	end
	y = y - 26

	local function placeLabel(fs)
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", PADDING, y - 4)
	end

	-- row 2: roles
	placeLabel(f.RolesLabel)
	local x = LABEL_WIDTH
	for _, chip in ipairs(f.RoleChips) do
		chip:ClearAllPoints()
		chip:SetPoint("TOPLEFT", x, y)
		x = x + chip:GetWidth() + CHIP_GAP
	end
	f.RolesHint:ClearAllPoints()
	f.RolesHint:SetPoint("LEFT", f, "TOPLEFT", x + 4, y - CHIP_HEIGHT / 2)
	f.RolesHint:SetPoint("RIGHT", f, "TOPRIGHT", -PADDING, y - CHIP_HEIGHT / 2)
	y = y - CHIP_HEIGHT - ROW_GAP

	-- row 3: abilities, wrapping, with "+ more"
	placeLabel(f.AbilitiesLabel)
	local states = ns.db.abilityStates[Bar.CurrentProfile()] or {}
	x = LABEL_WIDTH
	local function place(chip)
		local w = chip:GetWidth()
		if x + w > width - PADDING and x > LABEL_WIDTH then
			x = LABEL_WIDTH
			y = y - CHIP_HEIGHT - CHIP_GAP
		end
		chip:ClearAllPoints()
		chip:SetPoint("TOPLEFT", x, y)
		chip:Show()
		x = x + w + CHIP_GAP
	end
	for _, chip in ipairs(f.AbilityChips) do
		if visibleAbility(chip, states) then place(chip) else chip:Hide() end
	end
	place(f.More)
	y = y - CHIP_HEIGHT - 6

	-- legend, right aligned
	f.LegendPrefText:ClearAllPoints()
	f.LegendPrefText:SetPoint("TOPRIGHT", -PADDING, y)
	f.LegendPref:ClearAllPoints()
	f.LegendPref:SetPoint("RIGHT", f.LegendPrefText, "LEFT", -4, 0)
	f.LegendDot:ClearAllPoints()
	f.LegendDot:SetPoint("RIGHT", f.LegendPref, "LEFT", -6, 0)
	f.LegendNeedText:ClearAllPoints()
	f.LegendNeedText:SetPoint("RIGHT", f.LegendDot, "LEFT", -6, 0)
	f.LegendNeed:ClearAllPoints()
	f.LegendNeed:SetPoint("RIGHT", f.LegendNeedText, "LEFT", -4, 0)
	y = y - 14 - PADDING

	Bar.height = -y
	return Bar.height
end

-- Automatic role state: solo = your roles, in a group = roles your group still needs.
local function autoRoles()
	local mySide = ns.Engine.GetMySide()
	local out = {}
	if #mySide <= 1 then
		local r = ns.Engine.GetMyRoles()
		out.TANK, out.HEALER, out.DAMAGER = r.tank, r.healer, r.dps
	else
		local targets = ns.GetRoleTargets("dungeon", 5)
		local counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
		for _, m in ipairs(mySide) do
			local role = m.role or "DAMAGER"
			counts[role] = counts[role] + 1
		end
		for role, target in pairs(targets) do out[role] = counts[role] < target end
	end
	return out, #mySide > 1
end

function Bar.ToggleRole(role)
	local chips = ns.db.roleChips
	if next(chips) == nil then
		local auto = autoRoles()
		for r, on in pairs(auto) do chips[r] = on and true or false end
	end
	chips[role] = not chips[role]
	ns.UI.ApplyLayout()
	ns.RequestRefresh()
end

function Bar.CycleAbility(id)
	local profile = Bar.CurrentProfile()
	local states = ns.db.abilityStates[profile]
	states[id] = NEXT_STATE[states[id] or "ignore"]
	ns.UI.ApplyLayout()
	ns.RequestRefresh()
end

function Bar.Update()
	local f = Bar.frame
	if not f then return end
	local L = ns.L
	f.Enable:SetChecked(ns.db.enabled)

	local mySide = ns.Engine.GetMySide()
	if #mySide > 1 then
		f.RatingValue:SetText(L.YOUR_GROUP .. " (" .. #mySide .. ")")
	else
		local me = mySide[1]
		local words = ns.Words[ns.clientLocale] or ns.Words.enUS
		local roles = {}
		local r = me.lfgRoles or {}
		if r.tank then roles[#roles + 1] = words.roles.TANK end
		if r.healer then roles[#roles + 1] = words.roles.HEALER end
		if r.dps then roles[#roles + 1] = words.roles.DAMAGER end
		f.RatingValue:SetText(("%s %s · %s"):format(ns.ClassName(me.class or ""), tostring(me.level or "?"),
			table.concat(roles, "/")))
	end

	local profile = Bar.CurrentProfile()
	local profileText
	if profile == "dungeon" then
		profileText = L.PROFILE_DUNGEON
	elseif profile == "raid" then
		profileText = _G.RAID or "Raid"
	else
		profileText = _G.GROUP or "Group"
	end
	f.ProfileLabel:SetText(L.PROFILE)
	f.ProfileValue:SetText(profileText)

	local auto, inGroup = autoRoles()
	f.RolesLabel:SetText(inGroup and L.ROLES_GROUP or L.ROLES_SOLO)
	local manual = next(ns.db.roleChips) ~= nil
	for _, chip in ipairs(f.RoleChips) do
		local on
		if manual then on = ns.db.roleChips[chip.role] else on = auto[chip.role] end
		chip.state = on and "need" or "ignore"
		Bar.StyleChip(chip)
	end
	f.RolesHint:SetShown(not manual)

	local states = ns.db.abilityStates[profile] or {}
	for _, chip in ipairs(f.AbilityChips) do
		chip.state = states[chip.ability] or "ignore"
		chip.markerState = (chip.state == "need" or chip.state == "pref") and chip.state or nil
		Bar.StyleChip(chip)
	end
	f.More.label = ns.db.showAllAbilities and L.LESS or L.MORE
	Bar.StyleChip(f.More)


	setMarker(f.LegendNeed, "need", C.dim, { 0.045, 0.035, 0.025 })
	setMarker(f.LegendPref, "pref", C.dim, { 0.045, 0.035, 0.025 })

	-- Filter switched off: the bar stays open, everything except the switch is greyed out.
	local enabled = ns.db.enabled
	local alpha = enabled and 1 or 0.4
	for _, list in ipairs({ f.RoleChips, f.AbilityChips, { f.More } }) do
		for _, chip in ipairs(list) do
			chip:SetAlpha(alpha)
			chip:SetEnabled(enabled)
		end
	end
	for _, region in ipairs({ f.Separator, f.RatingLabel, f.RatingValue, f.ProfileLabel, f.ProfileValue, f.RolesLabel,
		f.RolesHint, f.AbilitiesLabel, f.LegendNeed, f.LegendNeedText, f.LegendDot, f.LegendPref, f.LegendPrefText }) do
		region:SetAlpha(alpha)
	end
end

function Bar.ResetFilters()
	ns.db.roleChips = {}
	ns.db.abilityStates = ns.CopyTable(ns.DEFAULT_ABILITY_STATES)
	Bar.Update()
	if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
	ns.RequestRefresh()
end
