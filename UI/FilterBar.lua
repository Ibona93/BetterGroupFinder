local ADDON_NAME, ns = ...

--[[
Filter bar under the Group Finder header (style of the approved mockup): rounded "pill"
chips, a dot for "required", a half dot for "preferred", a check mark on selected roles,
a favourites row (right click on a chip) and four categories that open in their own rows,
linked chips with a teal border. Opens with the filter button next to Refresh; the
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
	open   = { bg = { 0.07, 0.055, 0.04, 1 }, border = { 0.55, 0.45, 0.26, 1 }, text = C.gold },
}
local NEXT_STATE = { ignore = "pref", pref = "need", need = "ignore" }
local LINKED_BORDER = { 0.25, 0.62, 0.66, 1 }
local OVERRIDDEN_BORDER = { 0.20, 0.42, 0.45, 1 }
local STAR = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"

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
	chip.Star = chip:CreateTexture(nil, "ARTWORK")
	chip.Star:SetTexture(STAR)
	chip.Star:SetSize(10, 10)
	chip.Star:Hide()
	-- strike-through for chips switched off despite a link (the font cannot strike through)
	chip.Strike = chip:CreateTexture(nil, "OVERLAY")
	chip.Strike:SetColorTexture(LINKED_BORDER[1], LINKED_BORDER[2], LINKED_BORDER[3], 0.9)
	chip.Strike:SetHeight(1)
	chip.Strike:Hide()
	chip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	chip:SetScript("OnClick", function(self, button)
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		onClick(self, button)
	end)
	chip:SetScript("OnEnter", function(self)
		self.hover = true
		Bar.StyleChip(self)
		if self.ability then
			Bar.ShowAbilityTooltip(self)
		elseif self.role then
			Bar.ShowRoleTooltip(self)
		end
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
	local starW = chip.favorite and 12 or 0
	chip:SetWidth(textW + 20 + extra + starW)
	chip.Star:ClearAllPoints()
	chip.Star:SetPoint("RIGHT", -7, 0)
	chip.Star:SetShown(chip.favorite and true or false)
	chip.Text:ClearAllPoints()
	chip.Text:SetPoint("LEFT", 10, 0)
	chip.Check:ClearAllPoints()
	chip.Check:SetPoint("LEFT", chip.Text, "RIGHT", 0, 0)
	chip.Marker:ClearAllPoints()
	chip.Marker:SetPoint("LEFT", chip.Text, "RIGHT", 4, 0)
	layoutPill(chip.Border, chip, 0)
	layoutPill(chip.Fill, chip, 1)
	chip.Strike:ClearAllPoints()
	chip.Strike:SetPoint("LEFT", chip.Text, "LEFT", -1, 0)
	chip.Strike:SetPoint("RIGHT", chip.Text, "RIGHT", 1, 0)
	chip.Strike:SetShown(chip.overridden and true or false)
	local border = (chip.linked and LINKED_BORDER) or (chip.overridden and OVERRIDDEN_BORDER) or s.border
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

-- Tooltip colours: name white, level grey, condition orange, effect light blue, chip light grey.
local TT = { name = "ffffffff", level = "ff9d9d9d", cond = "ffff9933", fx = "ff66ccff", chip = "ffb4b4b4", link = "ff5fc8cc" }
local function col(key, str) return "|c" .. TT[key] .. str .. "|r" end

local function levelText(level)
	-- "%s ab Stufe %d" -> "ab Stufe %d" (works for all locales: the name comes first)
	local fmt = ns.L.CHIP_TT_SPELL:gsub("^%%s%s*", "")
	return fmt:format(level)
end

-- One spell: "Schildhieb  ab Stufe 12  nur mit Schild  · Effekt" (or "  – Chip").
local function spellLine(entry, suffix)
	local L = ns.L
	local line = col("name", ns.SpellName(entry.sp)) .. "  " .. col("level", levelText(entry.level))
	local cond = ns.ConditionText(entry)
	if not cond and entry.possible then cond = (L.CHIP_TT_POSSIBLE:gsub("[%(%)]", "")) end
	if cond then line = line .. "  " .. col("cond", cond) end
	if entry.fx then
		line = line .. "  " .. col("fx", "· " .. L["FX_" .. entry.fx])
	elseif suffix then
		line = line .. "  " .. col("chip", "– " .. suffix)
	end
	return line
end
Bar.SpellLine = spellLine

local function sortedEntries(class, filter)
	local entries = {}
	for _, e in ipairs(ns.CLASS_ABILITIES[class] or {}) do
		if filter(e) then entries[#entries + 1] = e end
	end
	table.sort(entries, function(x, y) return x.level < y.level end)
	return entries
end

local function classColorCode(class)
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not c then return "ffffffff" end
	return ("ff%02x%02x%02x"):format(math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
end

local function coloredClass(class)
	return "|c" .. classColorCode(class) .. ns.ClassName(class) .. "|r"
end

-- Ability chip tooltip: one line per spell, the class in its colour first.
function Bar.AbilitySources(id)
	local lines = {}
	for _, class in ipairs(ns.CLASS_ORDER) do
		for _, e in ipairs(sortedEntries(class, function(e) return e.a == id end)) do
			lines[#lines + 1] = { text = coloredClass(class) .. "  " .. spellLine(e), class = class, level = e.level }
		end
	end
	return lines
end

-- Class chip tooltip: sections like the filter bar (combat & utility, dispels, buffs), one
-- spell per line sorted by level, with the chip it counts for or its effect.
local SECTION_ORDER = { "combat", "dispel", "buff" }
function Bar.ClassSources(class)
	local L = ns.L
	local lines = {}
	for _, cat in ipairs(SECTION_ORDER) do
		local items, bySpell = {}, {}
		for _, chip in ipairs(ns.ABILITIES) do
			if chip.category == cat and not chip.class then
				for _, e in ipairs(ns.CLASS_ABILITIES[class] or {}) do
					if e.a == chip.id then
						local suffix = cat == "dispel" and L["SHORT_" .. chip.id] or (cat == "combat" and ns.AbilityName(chip.id)) or nil
						local item = bySpell[e.sp]
						if item then
							if suffix then item.suffix = item.suffix and (item.suffix .. ", " .. suffix) or suffix end
						else
							item = { entry = e, suffix = suffix, n = #items }
							bySpell[e.sp] = item
							items[#items + 1] = item
						end
					end
				end
			end
		end
		if #items > 0 then
			table.sort(items, function(x, y)
				if x.entry.level ~= y.entry.level then return x.entry.level < y.entry.level end
				return x.n < y.n
			end)
			lines[#lines + 1] = { header = L["CAT_" .. cat], category = cat }
			for _, item in ipairs(items) do
				lines[#lines + 1] = { text = "  " .. spellLine(item.entry, item.suffix), category = cat, sp = item.entry.sp }
			end
		end
	end
	return lines
end

-- "Wählt mit aus: Mal der Wildnis" for chips that select others.
function Bar.LinksText(id)
	local targets = ns.LINKS[id]
	if not targets then return nil end
	local names = {}
	for i, t in ipairs(targets) do names[i] = ns.AbilityName(t) end
	return ns.L.LINKS_TO:format(table.concat(names, ", "))
end

-- Short tooltips (default): ability chip = classes that bring it ("maybe:" = only with talent,
-- pet, form ...); class chip = what it brings per section, without levels and conditions.
-- Holding Shift shows the full version (live, see the modifier watcher below).
function Bar.AbilityShort(id)
	local sure, maybe = {}, {}
	for _, class in ipairs(ns.CLASS_ORDER) do
		local s, p
		for _, e in ipairs(ns.CLASS_ABILITIES[class] or {}) do
			if e.a == id then
				if e.possible then p = true else s = true end
			end
		end
		if s then
			sure[#sure + 1] = coloredClass(class)
		elseif p then
			maybe[#maybe + 1] = coloredClass(class)
		end
	end
	return sure, maybe
end

function Bar.ClassShort(class)
	local L = ns.L
	local lines = {}
	for _, cat in ipairs(SECTION_ORDER) do
		local names, seen = {}, {}
		for _, chip in ipairs(ns.ABILITIES) do
			if chip.category == cat and not chip.class then
				local sure, any = false, false
				for _, e in ipairs(ns.CLASS_ABILITIES[class] or {}) do
					if e.a == chip.id then
						any = true
						if not e.possible then sure = true end
					end
				end
				if any then
					local name = cat == "dispel" and L["SHORT_" .. chip.id] or L["AB_" .. chip.id]
					if not seen[name] then
						seen[name] = true
						-- only possible (talent, condition): grey
						names[#names + 1] = sure and name or col("level", name)
					end
				end
			end
		end
		if #names > 0 then
			lines[#lines + 1] = "|cffffd100" .. L["CAT_" .. cat] .. ":|r " .. col("name", table.concat(names, ", "))
		end
	end
	return lines
end

-- Loot competition chip -----------------------------------------------------

local function lootTargets()
	return ns.Engine.LootTargets(ns.Engine.GetMySide())
end

-- "Loot (me)", "Loot (Thoradin)", "Loot (2)", "Loot (nobody)"
function Bar.LootLabel()
	local L = ns.L
	local names = {}
	for _, t in ipairs(lootTargets()) do names[#names + 1] = t.isSelf and L.LOOT_ME or (t.name or "?") end
	local suffix = (#names == 0 and L.LOOT_NOBODY) or (#names == 1 and names[1]) or tostring(#names)
	return L.AB_loot .. " (" .. suffix .. ")"
end

local function memberText(m)
	return ("%s %s"):format(coloredClass(m.class), tostring(m.level or "?"))
end

-- Classes that compete with a player: sure (in at least one role) and only maybe.
function Bar.LootClasses(t)
	local sure, maybe = {}, {}
	for _, class in ipairs(ns.CLASS_ORDER) do
		local best
		for role in pairs(ns.LOOT_STATS[class] or {}) do
			local r = ns.Scoring.LootCompetes(t, { class = class, level = t.level, role = role })
			if r == "sure" then best = "sure" elseif r == "maybe" and not best then best = "maybe" end
		end
		if best == "sure" then sure[#sure + 1] = coloredClass(class)
		elseif best == "maybe" then maybe[#maybe + 1] = coloredClass(class) end
	end
	return sure, maybe
end

function Bar.ShowLootTooltip(chip, detail)
	local L = ns.L
	GameTooltip:SetText(L.LOOT_TITLE, 1, 0.82, 0)
	local targets = lootTargets()
	if #targets == 0 then
		GameTooltip:AddLine(L.LOOT_NONE_SELECTED, 1, 0.6, 0.2, true)
	end
	for _, t in ipairs(targets) do
		local who = t.isSelf and (L.LOOT_ME_CAP .. " (" .. memberText(t) .. ")") or ((t.name or "?") .. " (" .. memberText(t) .. ")")
		GameTooltip:AddLine(who, 1, 1, 1, false)
		local sure, maybe = Bar.LootClasses(t)
		GameTooltip:AddLine("  " .. col("chip", L.LOOT_COMPETITORS) .. " " .. (#sure > 0 and table.concat(sure, ", ") or "-"), 1, 1, 1, true)
		if #maybe > 0 then
			GameTooltip:AddLine("  " .. col("level", L.TT_MAYBE) .. " " .. table.concat(maybe, ", "), 1, 1, 1, true)
		end
		if detail then
			local armor = ns.Scoring.LootArmor(t)
			local stats = {}
			for i, st in ipairs(ns.Scoring.LootStats(t)) do stats[i] = L["STAT_" .. st] end
			GameTooltip:AddLine("  " .. col("fx", (armor and L["ARMOR_" .. armor] or "?") .. ", " .. table.concat(stats, "/")), 1, 1, 1, false)
		end
	end
	if detail then
		GameTooltip:AddLine(L.LOOT_RULE, 0.85, 0.85, 0.85, true)
		GameTooltip:AddLine(L.LOOT_EFFECT, 0.85, 0.85, 0.85, true)
	else
		GameTooltip:AddLine(L.TT_SHIFT_HINT, 0.5, 0.82, 0.5, true)
	end
	GameTooltip:AddLine(L.LOOT_SHIFT_CLICK, 0.5, 0.82, 0.5, true)
end

-- Shift-click: choose who loot competition is checked for (you and your group members).
function Bar.OpenLootMenu(chip)
	local L = ns.L
	local items = { { kind = "title", text = L.LOOT_MENU_TITLE } }
	for _, m in ipairs(ns.Engine.GetMySide()) do
		if m.class then
			local checked = ns.Engine.LootChecked(m)
			local label = (m.isSelf and L.LOOT_ME_CAP or (m.name or "?")) .. " (" .. memberText(m) .. ")"
			items[#items + 1] = {
				kind = "button", text = label, checked = checked,
				fn = function()
					if m.isSelf then
						ns.db.lootFor["@self"] = not checked
					elseif m.name then
						ns.db.lootFor[m.name] = (not checked) or nil
					end
					if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
					ns.RequestRefresh()
				end,
			}
		end
	end
	if GameTooltip:GetOwner() == chip then GameTooltip:Hide() end
	ns.Popup.Open(chip, items)
end

local tooltipChip
function Bar.ShowAbilityTooltip(chip)
	local L = ns.L
	local ability = ns.ABILITY_BY_ID[chip.ability]
	local detail = IsShiftKeyDown and IsShiftKeyDown() or false
	tooltipChip = chip
	GameTooltip:SetOwner(chip, "ANCHOR_TOP")
	if chip.ability == "loot" then
		Bar.ShowLootTooltip(chip, detail)
		GameTooltip:AddLine(L.CHIP_TT_CLICK, 0.6, 0.6, 0.6, true)
		GameTooltip:AddLine(ns.db.favorites[chip.ability] and L.FAV_REMOVE or L.FAV_ADD, 0.6, 0.6, 0.6, true)
		GameTooltip:Show()
		return
	end
	if ability and ability.class then
		local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[ability.class]
		GameTooltip:SetText(ns.AbilityName(chip.ability), c and c.r or 1, c and c.g or 0.82, c and c.b or 0)
	else
		GameTooltip:SetText(ns.AbilityName(chip.ability), 1, 0.82, 0)
	end
	if detail then
		local lines = ability and ability.class and Bar.ClassSources(ability.class) or Bar.AbilitySources(chip.ability)
		for _, line in ipairs(lines) do
			if line.header then
				GameTooltip:AddLine(line.header, 1, 0.82, 0)
			else
				GameTooltip:AddLine(line.text, 1, 1, 1, false)
			end
		end
	elseif ability and ability.class then
		for _, line in ipairs(Bar.ClassShort(ability.class)) do
			GameTooltip:AddLine(line, 1, 1, 1, false)
		end
	else
		local sure, maybe = Bar.AbilityShort(chip.ability)
		if #sure > 0 then GameTooltip:AddLine(table.concat(sure, ", "), 1, 1, 1, true) end
		if #maybe > 0 then GameTooltip:AddLine(col("level", L.TT_MAYBE) .. " " .. table.concat(maybe, ", "), 1, 1, 1, true) end
	end
	local links = Bar.LinksText(chip.ability)
	if links then GameTooltip:AddLine(col("link", links), 1, 1, 1, false) end
	if chip.linked then
		GameTooltip:AddLine(col("link", L.LINKED_BY:format(ns.AbilityName(chip.linked))), 1, 1, 1, true)
	elseif chip.overridden then
		GameTooltip:AddLine(col("link", L.OVERRIDDEN:format(ns.AbilityName(chip.overridden))), 1, 1, 1, true)
	end
	if not detail then GameTooltip:AddLine(L.TT_SHIFT_HINT, 0.5, 0.82, 0.5, true) end
	GameTooltip:AddLine(L.CHIP_TT_CLICK, 0.6, 0.6, 0.6, true)
	GameTooltip:AddLine(ns.db.favorites[chip.ability] and L.FAV_REMOVE or L.FAV_ADD, 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

-- Shift pressed or released while a chip tooltip is open: switch between short and full.
local modWatcher = CreateFrame("Frame")
modWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
modWatcher:SetScript("OnEvent", function(_, _, key)
	if key ~= "LSHIFT" and key ~= "RSHIFT" then return end
	local chip = tooltipChip
	if chip and chip.hover and chip.ability and GameTooltip:IsShown() and GameTooltip:GetOwner() == chip then
		Bar.ShowAbilityTooltip(chip)
	end
end)

function Bar.ShowRoleTooltip(chip)
	local L = ns.L
	GameTooltip:SetOwner(chip, "ANCHOR_TOP")
	GameTooltip:SetText(chip.label or "", 1, 0.82, 0)
	local manual = next(ns.db.roleChips) ~= nil
	if Bar.CurrentProfile() == "other" then
		GameTooltip:AddLine(L.ROLE_TT_NONE, 1, 0.6, 0.2, true)
	end
	GameTooltip:AddLine(manual and L.ROLE_TT_MANUAL or L.ROLE_TT_AUTO, 1, 1, 1, true)
	GameTooltip:AddLine(L.ROLE_TT_CLICK:format(L.OPT_RESET_FILTERS), 0.6, 0.6, 0.6, true)
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
	-- "Reset" (current Group Finder category only), right in the first row
	f.Reset = CreateFrame("Button", nil, f)
	f.Reset.Text = text(f.Reset, C.grey)
	f.Reset.Text:SetPoint("RIGHT")
	f.Reset.Text:SetText(L.RESET_SHORT)
	f.Reset:SetScript("OnEnter", function(self)
		self.Text:SetTextColor(C.white[1], C.white[2], C.white[3])
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L.RESET_SHORT, 1, 0.82, 0)
		GameTooltip:AddLine(L.RESET_TT, 1, 1, 1, true)
		local own = ns.db.userDefaults[Bar.CurrentProfile()]
		GameTooltip:AddLine(own and L.RESET_TT_OWN or L.RESET_TT_BUILTIN, 0.5, 0.82, 0.5, true)
		GameTooltip:Show()
	end)
	f.Reset:SetScript("OnLeave", function(self)
		self.Text:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
		GameTooltip:Hide()
	end)
	f.Reset:SetScript("OnClick", function()
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		Bar.ResetCurrent()
	end)
	-- "Save": the chips of this category become your own default for "Reset"
	f.Save = CreateFrame("Button", nil, f)
	f.Save.Text = text(f.Save, C.grey)
	f.Save.Text:SetPoint("RIGHT")
	f.Save.Text:SetText(L.SAVE_SHORT)
	f.Save:SetScript("OnEnter", function(self)
		self.Text:SetTextColor(C.white[1], C.white[2], C.white[3])
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L.SAVE_SHORT, 1, 0.82, 0)
		GameTooltip:AddLine(L.SAVE_TT, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	f.Save:SetScript("OnLeave", function(self)
		self.Text:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
		GameTooltip:Hide()
	end)
	f.Save:SetScript("OnClick", function()
		if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
		Bar.SaveCurrent()
	end)
	f.SaveDot = text(f, C.dim)
	f.SaveDot:SetText("·")

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

	-- Row 3: abilities
	f.AbilitiesLabel = text(f, C.white)
	f.AbilitiesLabel:SetText(L.ABILITIES)
	f.AbilityChips = {}
	local function onAbilityClick(id)
		return function(chip, button)
			if button == "RightButton" then
				Bar.ToggleFavorite(id)
			elseif id == "loot" and IsShiftKeyDown and IsShiftKeyDown() then
				Bar.OpenLootMenu(chip)
			else
				Bar.CycleAbility(id)
			end
		end
	end
	f.FavChips = {}
	for _, ability in ipairs(ns.ABILITIES) do
		local chip = createChip(f, onAbilityClick(ability.id))
		chip.ability = ability.id
		chip.label = ns.AbilityName(ability.id)
		f.AbilityChips[#f.AbilityChips + 1] = chip
		local fav = createChip(f, onAbilityClick(ability.id))
		fav.ability = ability.id
		fav.label = chip.label
		fav.inFavorites = true
		fav:Hide()
		f.FavChips[ability.id] = fav
	end
	f.FavLabel = text(f, C.white)
	f.FavLabel:SetText(L.CAT_favorites)
	f.FavEmpty = text(f, C.dim)
	f.FavEmpty:SetText(L.FAV_EMPTY)
	f.CategoryToggles = {}
	for _, cat in ipairs(ns.CATEGORY_ORDER) do
		local toggle = createChip(f, function()
			ns.db.openCategories[cat] = not ns.db.openCategories[cat]
			ns.UI.ApplyLayout()
		end)
		toggle.state = "more"
		toggle.category = cat
		f.CategoryToggles[cat] = toggle
	end

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
	for _, fs in ipairs({ f.EnableText, f.Separator, f.RatingLabel, f.RatingValue,
		f.RolesLabel, f.AbilitiesLabel, f.FavLabel, f.FavEmpty, f.Reset.Text, f.Save.Text, f.SaveDot, f.LegendNeedText, f.LegendDot, f.LegendPrefText }) do
		fs:SetFontObject(font())
	end
end

-- Collapsed categories are hidden completely; the toggle chip shows how many are active.
local function chipCategory(chip)
	local ability = ns.ABILITY_BY_ID[chip.ability]
	return ability and ability.category
end

function Bar.ActiveCount(category, states)
	local n = 0
	for _, ability in ipairs(ns.ABILITIES) do
		if ability.category == category and ns.ChipVisible(ability.id)
			and (states[ability.id] or "ignore") ~= "ignore" then n = n + 1 end
	end
	return n
end

-- Lays out all rows for the current width; returns the bar height.
function Bar.Layout()
	local f = Bar.frame
	if not f then return 0 end
	updateSizes()
	Bar.ApplyFonts()
	Bar.Update()
	LABEL_WIDTH = PADDING + 12 + math.ceil(math.max(f.RolesLabel:GetStringWidth(), f.AbilitiesLabel:GetStringWidth(),
		f.FavLabel:GetStringWidth()))
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
	-- Not enough room (large font, long translation): drop the "Rating for:" label first.
	local leftW = 24 + f.EnableText:GetStringWidth() + 14 + f.Separator:GetStringWidth()
		+ f.RatingLabel:GetStringWidth() + 4 + f.RatingValue:GetStringWidth()
	local resetW = math.ceil(f.Reset.Text:GetStringWidth())
	f.Reset:SetSize(resetW + 4, 18)
	f.Reset:ClearAllPoints()
	f.Reset:SetPoint("RIGHT", f, "TOPRIGHT", -PADDING, y - 9)
	f.SaveDot:ClearAllPoints()
	f.SaveDot:SetPoint("RIGHT", f.Reset, "LEFT", -5, 0)
	local saveW = math.ceil(f.Save.Text:GetStringWidth())
	f.Save:SetSize(saveW + 4, 18)
	f.Save:ClearAllPoints()
	f.Save:SetPoint("RIGHT", f.SaveDot, "LEFT", -5, 0)
	resetW = resetW + saveW + math.ceil(f.SaveDot:GetStringWidth()) + 18
	local tight = leftW + resetW + 12 + 2 * PADDING + 12 > width
	-- Still too wide without the label (long translations): "Save · Reset" move to the
	-- bottom row, left of the legend.
	local bottomButtons = leftW - f.RatingLabel:GetStringWidth() - 4 + resetW + 12 + 2 * PADDING + 12 > width
	Bar.buttonsBottom = bottomButtons
	if bottomButtons then tight = leftW + 12 + 2 * PADDING + 12 > width end
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
	y = y - CHIP_HEIGHT - ROW_GAP

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

	-- row 3: favourites, a row of their own (can be switched off in the options)
	f.FavLabel:SetShown(ns.db.showFavRow)
	if ns.db.showFavRow then
		placeLabel(f.FavLabel)
		x = LABEL_WIDTH
		local anyFavorite = false
		for _, ability in ipairs(ns.ABILITIES) do
			local fav = f.FavChips[ability.id]
			if ns.db.favorites[ability.id] and ns.ChipVisible(ability.id) then
				place(fav)
				anyFavorite = true
			else
				fav:Hide()
			end
		end
		f.FavEmpty:ClearAllPoints()
		f.FavEmpty:SetPoint("LEFT", f, "TOPLEFT", LABEL_WIDTH + 2, y - CHIP_HEIGHT / 2)
		f.FavEmpty:SetShown(not anyFavorite)
		y = y - CHIP_HEIGHT - ROW_GAP
	else
		for _, fav in pairs(f.FavChips) do fav:Hide() end
		f.FavEmpty:Hide()
	end

	-- rows 4+: categories; closed ones side by side, an open one gets rows of its own.
	-- Hidden categories / chips (options) are left out; the whole row can be switched off.
	local function newLine()
		if x > LABEL_WIDTH then
			x = LABEL_WIDTH
			y = y - CHIP_HEIGHT - CHIP_GAP
		end
	end
	for _, chip in ipairs(f.AbilityChips) do chip:Hide() end
	for _, toggle in pairs(f.CategoryToggles) do toggle:Hide() end
	local anyCategory = false
	if ns.db.showAbilityRow then
		for _, cat in ipairs(ns.CATEGORY_ORDER) do
			local visible = false
			for _, chip in ipairs(f.AbilityChips) do
				if chipCategory(chip) == cat and ns.ChipVisible(chip.ability) then visible = true end
			end
			if visible then
				if not anyCategory then
					placeLabel(f.AbilitiesLabel)
					x = LABEL_WIDTH
					anyCategory = true
				end
				local toggle = f.CategoryToggles[cat]
				if ns.INLINE_CATEGORIES[cat] then
					-- no toggle: the chip(s) stand directly in the row
					for _, chip in ipairs(f.AbilityChips) do
						if chipCategory(chip) == cat and ns.ChipVisible(chip.ability) then place(chip) end
					end
				elseif ns.db.openCategories[cat] then
					newLine()
					place(toggle)
					for _, chip in ipairs(f.AbilityChips) do
						if chipCategory(chip) == cat and ns.ChipVisible(chip.ability) then place(chip) end
					end
					newLine()
				else
					place(toggle)
				end
			end
		end
	end
	f.AbilitiesLabel:SetShown(anyCategory)
	if anyCategory then
		if x == LABEL_WIDTH then y = y + CHIP_HEIGHT + CHIP_GAP end -- undo the last line break
		y = y - CHIP_HEIGHT - 6
	else
		y = y + ROW_GAP - 6
	end

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
	if Bar.buttonsBottom then
		f.Save:ClearAllPoints()
		f.Save:SetPoint("TOPLEFT", PADDING - 2, y + 2)
		f.SaveDot:ClearAllPoints()
		f.SaveDot:SetPoint("LEFT", f.Save, "RIGHT", 5, 0)
		f.Reset:ClearAllPoints()
		f.Reset:SetPoint("LEFT", f.SaveDot, "RIGHT", 5, 0)
	end
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

-- Left click: cycle ignore -> preferred -> required. On a chip that is only selected through
-- a link, the click switches it off anyway (until the linking chip is switched off).
function Bar.CycleAbility(id)
	local profile = Bar.CurrentProfile()
	local own = ns.db.abilityStates[profile]
	ns.db.linkOverrides[profile] = ns.db.linkOverrides[profile] or {}
	local overrides = ns.db.linkOverrides[profile]
	local _, info = ns.Engine.ProfileStates(profile)
	if info.linked[id] then
		overrides[id] = true
	else
		own[id] = NEXT_STATE[own[id] or "ignore"]
	end
	local _, after = ns.Engine.ProfileStates(profile)
	for chip in pairs(overrides) do
		if not after.implied[chip] then overrides[chip] = nil end
	end
	ns.UI.ApplyLayout()
	ns.RequestRefresh()
end

-- Right click: add to or remove from the favourites row (false, not nil, so the saved
-- variables do not bring a removed default favourite back).
function Bar.ToggleFavorite(id)
	ns.db.favorites[id] = not ns.db.favorites[id]
	ns.UI.ApplyLayout()
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
	local auto, inGroup = autoRoles()
	f.RolesLabel:SetText(inGroup and L.ROLES_GROUP or L.ROLES_SOLO)
	local manual = next(ns.db.roleChips) ~= nil
	for _, chip in ipairs(f.RoleChips) do
		local on
		if manual then on = ns.db.roleChips[chip.role] else on = auto[chip.role] end
		chip.state = on and "need" or "ignore"
		Bar.StyleChip(chip)
	end

	local states, info = ns.Engine.ProfileStates(profile)
	local function styleAbility(chip)
		local id = chip.ability
		chip.state = states[id] or "ignore"
		chip.markerState = (chip.state == "need" or chip.state == "pref") and chip.state or nil
		chip.linked = info.linked[id]
		chip.overridden = info.overridden[id]
		chip.favorite = not chip.inFavorites and ns.db.favorites[id] and true or false
		if id == "loot" then chip.label = Bar.LootLabel() end
		Bar.StyleChip(chip)
	end
	for _, chip in ipairs(f.AbilityChips) do styleAbility(chip) end
	for _, chip in pairs(f.FavChips) do styleAbility(chip) end
	for _, cat in ipairs(ns.CATEGORY_ORDER) do
		local toggle = f.CategoryToggles[cat]
		local name = L["CAT_" .. cat]
		toggle.state = ns.db.openCategories[cat] and "open" or "more"
		if ns.db.openCategories[cat] then
			toggle.label = "- " .. name
		else
			local n = Bar.ActiveCount(cat, states)
			toggle.label = "+ " .. name .. (n > 0 and (" (" .. n .. ")") or "")
		end
		Bar.StyleChip(toggle)
	end

	setMarker(f.LegendNeed, "need", C.dim, { 0.045, 0.035, 0.025 })
	setMarker(f.LegendPref, "pref", C.dim, { 0.045, 0.035, 0.025 })

	-- Filter switched off: the bar stays open, everything except the switch is greyed out.
	local enabled = ns.db.enabled
	local alpha = enabled and 1 or 0.4
	local favList, toggles = {}, {}
	for _, chip in pairs(f.FavChips) do favList[#favList + 1] = chip end
	for _, chip in pairs(f.CategoryToggles) do toggles[#toggles + 1] = chip end
	for _, list in ipairs({ f.RoleChips, f.AbilityChips, favList, toggles }) do
		for _, chip in ipairs(list) do
			chip:SetAlpha(alpha)
			chip:SetEnabled(enabled)
		end
	end
	for _, region in ipairs({ f.Separator, f.RatingLabel, f.RatingValue, f.RolesLabel,
		f.AbilitiesLabel, f.FavLabel, f.FavEmpty, f.LegendNeed, f.LegendNeedText, f.LegendDot, f.LegendPref, f.LegendPrefText }) do
		region:SetAlpha(alpha)
	end
	-- Quests & zones / custom: no role distribution, the role chips do nothing there
	if profile == "other" then
		for _, chip in ipairs(f.RoleChips) do chip:SetAlpha(0.4) end
		f.RolesLabel:SetAlpha(0.4)
	end
end

-- Own defaults: "Save" stores the chips (and lifted links) of the current category; "Reset"
-- and "Reset filters" go back to them, or to the built-in defaults when nothing is saved.
local function defaultsFor(profile)
	local own = ns.db.userDefaults[profile]
	if own and own.states then
		return ns.CopyTable(own.states), own.overrides and ns.CopyTable(own.overrides) or nil
	end
	return ns.CopyTable(ns.DEFAULT_ABILITY_STATES[profile]), nil
end
Bar.DefaultsFor = defaultsFor

function Bar.SaveCurrent()
	local profile = Bar.CurrentProfile()
	local overrides = ns.db.linkOverrides[profile]
	ns.db.userDefaults[profile] = {
		states = ns.CopyTable(ns.db.abilityStates[profile] or {}),
		overrides = overrides and next(overrides) and ns.CopyTable(overrides) or nil,
	}
	ns.Print(ns.L.SAVED_MSG)
end

-- Reset in the filter bar: chips of the current category, roles back to automatic;
-- favourites and the other categories stay.
function Bar.ResetCurrent()
	local profile = Bar.CurrentProfile()
	ns.db.abilityStates[profile], ns.db.linkOverrides[profile] = defaultsFor(profile)
	ns.db.roleChips = {}
	if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
	ns.RequestRefresh()
end

function Bar.ResetFilters()
	ns.db.roleChips = {}
	ns.db.linkOverrides = {}
	for profile in pairs(ns.DEFAULT_ABILITY_STATES) do
		ns.db.abilityStates[profile], ns.db.linkOverrides[profile] = defaultsFor(profile)
	end
	Bar.Update()
	if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
	ns.RequestRefresh()
end

-- Options: forget your own defaults and go back to the built-in ones.
function Bar.RestoreBuiltIn()
	ns.db.userDefaults = {}
	Bar.ResetFilters()
	ns.Print(ns.L.RESTORED_MSG)
end
