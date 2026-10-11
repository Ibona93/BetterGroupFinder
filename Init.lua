-- BGF - Better Group Finder Forever: namespace and shared helpers.
-- Loaded first; every other file receives the same private namespace table `ns`.
local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.VERSION = "0.8.1"

-- Locale registries, filled by Locales/*.lua.
ns.Locales = {}           -- [locale] = { KEY = "UI string" }
ns.Words = {}             -- [locale] = { classes = {...}, roles = {...} } for message templates
ns.DefaultTemplates = {}  -- [locale] = { join_friendly = "...", ... }

function ns.RegisterLocale(locale, strings, words, templates)
	ns.Locales[locale] = strings
	ns.Words[locale] = words
	ns.DefaultTemplates[locale] = templates
end

-- The template keys every locale provides, in menu order.
ns.TEMPLATE_KEYS = {
	"join_friendly", "join_short",
	"group_friendly", "group_short",
	"invite_friendly", "invite_short",
}

-- All client languages WoW offers. enGB clients report "enGB" but use enUS texts.
ns.ALL_LANGUAGES = { "enUS", "deDE", "frFR", "esES", "esMX", "ptBR", "itIT", "ruRU", "koKR", "zhCN", "zhTW" }

ns.LANGUAGE_NAMES = {
	enUS = "English", deDE = "Deutsch", frFR = "Français", esES = "Español (España)",
	esMX = "Español (América Latina)", ptBR = "Português", itIT = "Italiano",
	ruRU = "Русский", koKR = "한국어", zhCN = "简体中文", zhTW = "繁體中文",
}

function ns.NormalizeLocale(locale)
	if locale == "enGB" then return "enUS" end
	if locale == "ptPT" then return "ptBR" end
	return locale
end

-- Calls a function only if it exists; never raises. Returns the function's results or nil.
function ns.TryCall(fn, ...)
	if type(fn) ~= "function" then return nil end
	local results = { pcall(fn, ...) }
	if not results[1] then
		ns.Debug("call failed: " .. tostring(results[2]))
		return nil
	end
	return select(2, unpack(results))
end

-- True when a value is a "secret" value (Midnight-era restriction during chat lockdown).
function ns.IsSecret(value)
	local check = _G.issecretvalue
	if type(check) == "function" then
		local ok, secret = pcall(check, value)
		return ok and secret or false
	end
	return false
end

local debugLog = {}
ns.debugLog = debugLog

function ns.Debug(msg)
	debugLog[#debugLog + 1] = msg
	if #debugLog > 200 then table.remove(debugLog, 1) end
	if ns.db and ns.db.debug and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fbfffBGF debug:|r " .. tostring(msg))
	end
end

function ns.Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd100BGF:|r " .. tostring(msg))
	end
end

function ns.CopyTable(src)
	if type(src) ~= "table" then return src end
	local out = {}
	for k, v in pairs(src) do out[k] = ns.CopyTable(v) end
	return out
end

-- Fills missing keys of `target` from `defaults` (recursively), keeps user values.
function ns.MergeDefaults(target, defaults)
	for k, v in pairs(defaults) do
		if target[k] == nil then
			target[k] = ns.CopyTable(v)
		elseif type(v) == "table" and type(target[k]) == "table" then
			ns.MergeDefaults(target[k], v)
		end
	end
	return target
end
