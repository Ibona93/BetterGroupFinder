local _, ns = ...

--[[
Tooltip: Blizzard's own listing tooltip (members, roles, voice chat, activity) plus a
small BGF box underneath with the rating and its reasons.
]]

local Tooltip = {}
ns.Tooltip = Tooltip

local COLORS = {
	plus = { 0.37, 0.89, 0.37 },
	minus = { 1, 0.45, 0.35 },
	note = { 0.62, 0.62, 0.62 },
	info = { 0.5, 0.8, 1 },
	exclude = { 0.88, 0.63, 0.25 },
}

local box, lines

local function ensureBox()
	if box then return box end
	box = CreateFrame("Frame", "BGFReasonTooltip", UIParent, "TooltipBackdropTemplate")
	box:SetFrameStrata("TOOLTIP")
	box:SetClampedToScreen(true)
	box:Hide()
	box.Title = box:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	box.Title:SetPoint("TOPLEFT", 10, -9)
	box.Title:SetJustifyH("LEFT")
	lines = {}
	return box
end

local function getLine(i)
	if not lines[i] then
		local fs = box:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(true)
		if i == 1 then
			fs:SetPoint("TOPLEFT", box.Title, "BOTTOMLEFT", 0, -5)
		else
			fs:SetPoint("TOPLEFT", lines[i - 1], "BOTTOMLEFT", 0, -3)
		end
		lines[i] = fs
	end
	return lines[i]
end

local function showBlizzardTooltip(owner, resultID)
	local tip = _G.LFGBrowseSearchEntryTooltip
	if tip and type(_G.LFGBrowseSearchEntryTooltip_UpdateAndShow) == "function" then
		local ok = pcall(_G.LFGBrowseSearchEntryTooltip_UpdateAndShow, tip, resultID)
		if ok then
			tip:ClearAllPoints()
			tip:SetPoint("TOPLEFT", owner, "TOPRIGHT", 26, 0)
			return tip
		end
	end
	return nil
end

function Tooltip.Show(owner, entry)
	local anchor = showBlizzardTooltip(owner, entry.resultID)
	local result = entry.result
	if not ns.db.showReasons or not result or entry.own then
		if box then box:Hide() end
		return
	end
	ensureBox()
	box.Title:SetFontObject(ns.Fonts.Get(13))
	local verdict = ns.L[result.verdict or "VERDICT_LOW"]
	if ns.db.showScores then
		box.Title:SetText(verdict:format(result.score))
	else
		-- without points: "BGF: good fit"
		local plain = verdict:gsub("%%s", ""):gsub("%s*%(%)", ""):gsub("%s*（）", "")
		box.Title:SetText(plain)
	end
	if result.excluded then
		box.Title:SetText(ns.L.EXCLUDED)
		box.Title:SetTextColor(COLORS.exclude[1], COLORS.exclude[2], COLORS.exclude[3])
	else
		local c = ns.ScoreColor(result)
		box.Title:SetTextColor(c[1], c[2], c[3])
	end

	local width = 220
	if anchor then width = math.max(width, anchor:GetWidth() - 20) end
	local n = 0
	local seen = {}
	-- group value first, right below the verdict
	local value = not entry.isSolo and entry.groupValue
	if value and ns.db.showScores and not result.excluded then
		n = n + 1
		local fs = getLine(n)
		fs:SetFontObject(ns.Fonts.Get(12))
		fs:SetWidth(width)
		fs:SetText(ns.L.GROUP_VALUE:format(value.percent, value.rolesFilled, value.rolesTotal,
			value.abilitiesCovered, value.abilitiesTotal))
		fs:SetTextColor(1, 1, 1)
		fs:Show()
	end
	for _, reason in ipairs(result.reasons or {}) do
		local text = ns.FormatReason(reason)
		if not seen[text] then
			seen[text] = true
			n = n + 1
			local fs = getLine(n)
			fs:SetFontObject(ns.Fonts.Get(12))
			fs:SetWidth(width)
			fs:SetText(text)
			local c = COLORS[reason[1]] or COLORS.note
			fs:SetTextColor(c[1], c[2], c[3])
			fs:Show()
		end
	end
	local hints = entry.activityInfo and ns.Engine.VisibleHints(ns.INSTANCE_HINTS[entry.activityInfo.mapID])
	if hints and #hints > 0 then
		local names = {}
		for _, id in ipairs(hints) do names[#names + 1] = ns.AbilityName(id) end
		n = n + 1
		local fs = getLine(n)
		fs:SetFontObject(ns.Fonts.Get(12))
		fs:SetWidth(width)
		fs:SetText(ns.L.R_HINT:format(table.concat(names, ", ")))
		fs:SetTextColor(COLORS.info[1], COLORS.info[2], COLORS.info[3])
		fs:Show()
	end
	for i = n + 1, #lines do lines[i]:Hide() end

	local height = 18 + box.Title:GetStringHeight()
	for i = 1, n do height = height + lines[i]:GetStringHeight() + 3 end
	box:SetSize(width + 20, height + 6)
	box:ClearAllPoints()
	if anchor and anchor:IsShown() then
		box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	else
		box:SetPoint("TOPLEFT", owner, "TOPRIGHT", 26, 0)
	end
	box:Show()
end

function Tooltip.Hide()
	local tip = _G.LFGBrowseSearchEntryTooltip
	if tip then tip:Hide() end
	if box then box:Hide() end
end
