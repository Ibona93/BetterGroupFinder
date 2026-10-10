local ADDON_NAME, ns = ...

--[[
Font choice for BGF (list, filter bar, tooltip reasons).
  * Game fonts: Friz Quadrata (default), Arial Narrow, Morpheus, Skurri
  * Shipped (SIL OFL): Philosopher, PT Sans Narrow, Roboto Condensed, Noto Sans
  * Every font registered in LibSharedMedia-3.0 (if another addon provides it)
Korean and Chinese clients always use the game font; fonts without Cyrillic letters
fall back to the game font on Russian clients.
]]

local Fonts = {}
ns.Fonts = Fonts

local MEDIA = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Fonts\\"

Fonts.BUILTIN = {
	{ key = "friz",       name = "Friz Quadrata",    path = "Fonts\\FRIZQT__.TTF", cyrillic = false, game = true },
	{ key = "arialn",     name = "Arial Narrow",     path = "Fonts\\ARIALN.TTF",   cyrillic = false, game = true },
	{ key = "morpheus",   name = "Morpheus",         path = "Fonts\\MORPHEUS.TTF", cyrillic = false, game = true },
	{ key = "skurri",     name = "Skurri",           path = "Fonts\\SKURRI.TTF",   cyrillic = false, game = true },
	{ key = "philosopher", name = "Philosopher",     path = MEDIA .. "Philosopher-Regular.ttf",     cyrillic = true },
	{ key = "ptsansn",    name = "PT Sans Narrow",   path = MEDIA .. "PTSansNarrow-Regular.ttf",    cyrillic = true },
	{ key = "robotoc",    name = "Roboto Condensed", path = MEDIA .. "RobotoCondensed-Regular.ttf", cyrillic = true },
	{ key = "noto",       name = "Noto Sans",        path = MEDIA .. "NotoSans-Regular.ttf",        cyrillic = true },
}

local CJK = { koKR = true, zhCN = true, zhTW = true }

local function sharedMedia()
	local stub = _G.LibStub
	if not stub then return nil end
	local ok, lsm = pcall(stub, "LibSharedMedia-3.0", true)
	return ok and lsm or nil
end

-- Registers the shipped fonts in LibSharedMedia so other addons can use them too.
function Fonts.RegisterShared()
	local lsm = sharedMedia()
	if not lsm then return end
	for _, f in ipairs(Fonts.BUILTIN) do
		if not f.game then
			pcall(lsm.Register, lsm, "font", f.name, f.path, lsm.LOCALE_BIT_western + lsm.LOCALE_BIT_ruRU)
		end
	end
end

-- All selectable fonts: { key, name, path }.
function Fonts.List()
	local list, seen = {}, {}
	for _, f in ipairs(Fonts.BUILTIN) do
		list[#list + 1] = f
		seen[f.name] = true
	end
	local lsm = sharedMedia()
	if lsm then
		local ok, names = pcall(lsm.List, lsm, "font")
		if ok and type(names) == "table" then
			for _, name in ipairs(names) do
				if not seen[name] then
					seen[name] = true
					list[#list + 1] = { key = "lsm:" .. name, name = name, lsm = true }
				end
			end
		end
	end
	return list
end

local function gameFont()
	if _G.STANDARD_TEXT_FONT then return _G.STANDARD_TEXT_FONT end
	if GameFontNormal and GameFontNormal.GetFont then
		local path = GameFontNormal:GetFont()
		if path then return path end
	end
	return "Fonts\\FRIZQT__.TTF"
end

-- Path of the selected font, respecting the client's alphabet.
function Fonts.Path()
	return Fonts.PathFor(ns.db and ns.db.font or "friz")
end

-- Path of any font key (used to write each font's name in its own font).
function Fonts.PathFor(key)
	key = key or "friz"
	if CJK[ns.clientLocale] then return gameFont() end
	if key == "friz" then return gameFont() end
	if key:sub(1, 4) == "lsm:" then
		local lsm = sharedMedia()
		if lsm then
			local ok, path = pcall(lsm.Fetch, lsm, "font", key:sub(5), true)
			if ok and path then return path end
		end
		return gameFont()
	end
	for _, f in ipairs(Fonts.BUILTIN) do
		if f.key == key then
			if ns.clientLocale == "ruRU" and not f.cyrillic and f.game then return gameFont() end
			return f.path
		end
	end
	return gameFont()
end

function Fonts.Name()
	local key = ns.db and ns.db.font or "friz"
	for _, f in ipairs(Fonts.List()) do
		if f.key == key then return f.name end
	end
	return "Friz Quadrata"
end

local cache = {}

-- Font object for a size (and optional flags), rebuilt when the font changes.
function Fonts.Get(size, flags)
	local path = Fonts.Path()
	local id = path .. "|" .. size .. "|" .. (flags or "")
	if cache[id] then return cache[id] end
	local font = CreateFont("BGFFont" .. (#Fonts.objects + 1))
	font:CopyFontObject(GameFontHighlightSmall)
	pcall(font.SetFont, font, path, size, flags or "")
	if not font:GetFont() then
		font:SetFont(gameFont(), size, flags or "")
	end
	cache[id] = font
	Fonts.objects[#Fonts.objects + 1] = font
	return font
end
Fonts.objects = {}

function Fonts.Set(key)
	ns.db.font = key
	if ns.FilterBar and ns.FilterBar.ApplyFonts then ns.FilterBar.ApplyFonts() end
	if ns.UI and ns.UI.ApplyLayout then ns.UI.ApplyLayout() end
	ns.RequestRefresh()
end
