std = "lua51"
max_line_length = false
self = false
unused_args = false
globals = {
	"BetterGroupFinderDB", "SlashCmdList", "SLASH_BETTERGROUPFINDER1",
	"BGFRowMixin", "BGFHeaderMixin", "BGFMessageMixin",
}
read_globals = {
	"C_LFGList", "C_LFGListRoles", "C_ChatInfo", "C_PartyInfo", "C_SpellBook", "C_AddOns", "C_Timer",
	"CreateFrame", "UIParent", "GameTooltip", "DEFAULT_CHAT_FRAME", "GetLocale", "GetCurrentRegion",
	"IsBetaBuild", "InCombatLockdown", "IsInGroup", "IsInRaid", "GetNumGroupMembers", "GetNumSubgroupMembers",
	"UnitExists", "UnitClass", "UnitLevel", "UnitName", "UnitIsUnit", "UnitGroupRolesAssigned",
	"UnitIsGroupLeader", "UnitIsGroupAssistant", "IsPlayerSpell", "GetCursorPosition", "Ambiguate",
	"RAID_CLASS_COLORS", "LOCALIZED_CLASS_NAMES_MALE", "LEVEL_ABBR", "LFG_SELF_LISTING", "LFGBROWSE_ACTIVITY_COUNT",
	"SEND_MESSAGE", "GROUP_INVITE", "SOUNDKIT", "PlaySound", "GetGeneralPlaystyleString", "CreateAtlasMarkup",
	"CreateScrollBoxListLinearView", "ScrollUtil", "CreateDataProvider", "ScrollBoxConstants",
	"LFGBrowseFrame", "LFGParentFrame", "MenuUtil", "ChatFrameUtil", "ChatFrame_SendTell",
	"GameTooltip_SetTitle", "GameTooltip_AddNormalLine", "Settings", "UISpecialFrames", "tinsert",
	"tContains", "hooksecurefunc", "geterrorhandler", "unpack", "CreateFont", "GameFontHighlightSmall", "GameFontNormal", "GameFontHighlight", "LibStub", "STANDARD_TEXT_FONT",
}

-- Test files mock the WoW API and set globals on purpose.
files["tests/"] = { std = "lua51", allow_defined_top = true, globals = { "_G" }, ignore = { "111", "112", "113", "121", "122", "142", "143", "211", "212", "213", "311", "411", "421", "431", "432" } }
