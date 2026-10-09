local _, ns = ...

--[[
Abbreviation rules for instance names that do not fit the column, per client language.
Applied one after another until the text fits: "Höhlen des Wehklagens" -> "Höhlen d. Wehklagens".
Patterns use Lua frontier patterns (%f) so only whole words are replaced.
]]

local function whole(w) return "%f[%w]" .. w .. "%f[%W]" end

ns.ABBREVIATIONS = {
	deDE = {
		{ whole("des"), "d." }, { whole("der"), "d." }, { whole("den"), "d." }, { whole("dem"), "d." },
		{ whole("von"), "v." }, { whole("vom"), "v." }, { whole("und"), "u." }, { whole("im"), "i." },
	},
	enUS = {
		{ "^The ", "" }, { whole("of the"), "o.t." }, { whole("of"), "o." }, { whole("the"), "" }, { whole("and"), "&" },
	},
	frFR = {
		{ whole("des"), "d." }, { whole("du"), "d." }, { whole("de la"), "d.l." }, { whole("de"), "d." }, { whole("et"), "&" },
	},
	esES = {
		{ whole("de los"), "d.l." }, { whole("de las"), "d.l." }, { whole("del"), "d." }, { whole("de"), "d." }, { whole("y"), "&" },
	},
	ptBR = {
		{ whole("dos"), "d." }, { whole("das"), "d." }, { whole("do"), "d." }, { whole("da"), "d." }, { whole("de"), "d." }, { whole("e"), "&" },
	},
	itIT = {
		{ whole("della"), "d." }, { whole("delle"), "d." }, { whole("dei"), "d." }, { whole("del"), "d." }, { whole("di"), "d." }, { whole("e"), "&" },
	},
}
ns.ABBREVIATIONS.esMX = ns.ABBREVIATIONS.esES

-- Collapses double spaces left by removed words.
function ns.CleanSpaces(text)
	return (text:gsub("%s%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

-- Shortens a word to its first `keep` letters plus "." ("Wehklagens" -> "Wehkl.").
local function shortWord(word, keep)
	local out, n = {}, 0
	for ch in word:gmatch(UTF8_CHAR) do
		n = n + 1
		if n <= keep then out[#out + 1] = ch end
	end
	if n <= keep + 2 then return word end
	return table.concat(out) .. "."
end

-- Returns successively shorter variants of an instance name: first the language's
-- filler words, then long words after the first one ("Höhlen d. Wehkl.").
function ns.AbbreviationSteps(text, locale)
	local steps = {}
	local current = text
	for _, rule in ipairs(ns.ABBREVIATIONS[locale] or {}) do
		local nextText = ns.CleanSpaces((current:gsub(rule[1], rule[2])))
		if nextText ~= current then
			current = nextText
			steps[#steps + 1] = current
		end
	end
	if ns.ABBREVIATIONS[locale] then
		local words, changed = {}, false
		for word in current:gmatch("%S+") do
			if #words > 0 and not word:find("%.$") then
				local short = shortWord(word, 5)
				if short ~= word then changed = true end
				word = short
			end
			words[#words + 1] = word
		end
		if changed then steps[#steps + 1] = table.concat(words, " ") end
	end
	return steps
end

-- "Aldarin Schattentanz" -> "Aldarin S."; single names stay as they are.
function ns.ShortName(name)
	local first, rest = name:match("^(%S+)%s+(.+)$")
	if not first then return nil end
	local initial = rest:match("^[%z\1-\127\194-\244][\128-\191]*")
	return initial and (first .. " " .. initial .. ".") or nil
end
