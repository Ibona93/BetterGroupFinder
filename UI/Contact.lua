local _, ns = ...

--[[
"Request" button in the footer. Context:
  * selected group, you are solo        -> join request to the leader
  * selected group, you are in a group  -> request as a group (merge)
  * selected player, you may invite     -> invite + invitation message
Choosing a template sends the whisper right away (option, default on). If the chat is
locked or sending fails, the text is put into the chat box instead, nothing is lost.
]]

local Contact = {}
ns.Contact = Contact

local function canInvite()
	if not IsInGroup() then return true end
	return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

-- Returns "join", "group" or "invite" for an entry.
function Contact.Mode(entry)
	if entry.isSolo and canInvite() then return "invite" end
	if IsInGroup() then return "group" end
	return "join"
end

local function wordsFor(lang)
	return ns.Words[lang] or ns.Words.enUS
end

local function className(class, lang)
	if not class then return "" end
	if lang == ns.clientLocale then return ns.ClassName(class) end
	return wordsFor(lang).classes[class] or ns.Words.enUS.classes[class] or class
end

local function roleWord(role, lang)
	return wordsFor(lang).roles[role or "DAMAGER"] or ns.Words.enUS.roles[role or "DAMAGER"]
end

local function myRole(entry)
	if entry and entry.myRole then return entry.myRole end
	local assigned = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
	if assigned == "TANK" or assigned == "HEALER" or assigned == "DAMAGER" then return assigned end
	local r = ns.Engine.GetMyRoles()
	if r.healer then return "HEALER" end
	if r.tank then return "TANK" end
	return "DAMAGER"
end

-- Fills the placeholders of a template for one entry.
function Contact.Fill(template, entry, lang)
	local mySide = ns.Engine.GetMySide()
	local me = mySide[1] or {}
	local groupParts = {}
	for i, m in ipairs(mySide) do
		local role = (i == 1) and myRole(entry) or (m.role or "DAMAGER")
		groupParts[#groupParts + 1] = ("%s (%s)"):format(className(m.class, lang), roleWord(role, lang))
	end
	local target = entry.info and entry.info.leaderName or ""
	local values = {
		name = Ambiguate and Ambiguate(target, "short") or target,
		me = UnitName("player") or "",
		class = className(me.class, lang),
		role = roleWord(myRole(entry), lang),
		level = tostring(me.level or ""),
		instance = ns.InstanceName(entry, lang),
		group = table.concat(groupParts, wordsFor(lang).listJoin or ", "),
	}
	local text = template:gsub("{(%w+)}", function(key)
		return values[key] or ("{" .. key .. "}")
	end)
	return text
end

local function sendWhisper(target, text)
	if ns.db.autoSend and not ns.Engine.IsLockedDown() then
		local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or _G.SendChatMessage
		if send then
			local ok, err = pcall(send, text, "WHISPER", nil, target)
			if ok then
				ns.Print(ns.L.SENT:format(Ambiguate and Ambiguate(target, "short") or target))
				return
			end
			ns.Debug("send failed: " .. tostring(err))
		end
		ns.Print(ns.L.SEND_FALLBACK)
	end
	if ChatFrameUtil and ChatFrameUtil.SendTellWithMessage then
		ChatFrameUtil.SendTellWithMessage(target, text)
	elseif ChatFrame_SendTell then
		ChatFrame_SendTell(target)
	end
end

function Contact.Execute(entry, lang, key)
	local target = entry.info and entry.info.leaderName
	if not target then return end
	local mode = Contact.Mode(entry)
	if mode == "invite" and C_PartyInfo and C_PartyInfo.InviteUnit then
		pcall(C_PartyInfo.InviteUnit, target)
	end
	local text = Contact.Fill(ns.GetTemplate(lang, key), entry, lang)
	sendWhisper(target, text)
end

-- Menu items for the template popup (own popup, not Blizzard's menu system: see UI/Popup.lua).
function Contact.MenuItems(entry)
	local L = ns.L
	local mode = Contact.Mode(entry)
	local target = entry.info.leaderName or "?"
	local short = Ambiguate and Ambiguate(target, "short") or target
	local titleKey = mode == "invite" and "MENU_INVITE" or (mode == "group" and "MENU_GROUP" or "MENU_JOIN")
	local items = {
		{ kind = "title", text = "|cffffffff" .. L[titleKey]:format(short) .. "|r" },
		{ kind = "divider" },
	}
	for _, lang in ipairs(ns.TemplateLanguages()) do
		items[#items + 1] = { kind = "header", text = ns.LANGUAGE_NAMES[lang] or lang }
		for _, tone in ipairs({ "friendly", "short" }) do
			local key = mode .. "_" .. tone
			local label = ns.GetTemplateName(lang, key)
			items[#items + 1] = {
				kind = "button", indent = true, text = label,
				fn = function() Contact.Execute(entry, lang, key) end,
				tooltip = function(tooltip)
					tooltip:SetText(label, 1, 0.82, 0)
					tooltip:AddLine(Contact.Fill(ns.GetTemplate(lang, key), entry, lang), 1, 1, 1, true)
				end,
			}
		end
	end
	items[#items + 1] = { kind = "divider" }
	items[#items + 1] = { kind = "button", text = L.MENU_EMPTY_WHISPER, fn = function()
		if mode == "invite" and C_PartyInfo and C_PartyInfo.InviteUnit then pcall(C_PartyInfo.InviteUnit, target) end
		if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(target) end
	end }
	items[#items + 1] = { kind = "button", text = L.MENU_EDIT, fn = function()
		if ns.Options and ns.Options.Open then ns.Options.Open("templates") end
	end }
	return items
end

function Contact.OpenMenu(owner, entry)
	if not entry or not entry.info then
		ns.Print(ns.L.NO_SELECTION)
		return
	end
	ns.Popup.Open(owner, Contact.MenuItems(entry))
end

-- Right click on a list entry: message, invite, templates, and a hint how to report.
function Contact.EntryMenuItems(entry, owner)
	local L = ns.L
	local target = entry.info and entry.info.leaderName or "?"
	local short = Ambiguate and Ambiguate(target, "short") or target
	local inviteOk = entry.isSolo and Contact.Mode(entry) == "invite"
	local items = {
		{ kind = "title", text = "|cffffffff" .. short .. "|r" },
		{ kind = "divider" },
		{ kind = "button", text = SEND_MESSAGE or L.MENU_EMPTY_WHISPER, fn = function()
			if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(target) end
		end },
	}
	if inviteOk then
		items[#items + 1] = { kind = "button", text = INVITE or "Invite", fn = function()
			if C_PartyInfo and C_PartyInfo.InviteUnit then pcall(C_PartyInfo.InviteUnit, target) end
		end }
	end
	items[#items + 1] = { kind = "button", text = L.REQUEST .. " ...", fn = function()
		if C_Timer then C_Timer.After(0, function() Contact.OpenMenu(owner, entry) end) else Contact.OpenMenu(owner, entry) end
	end }
	items[#items + 1] = { kind = "divider" }
	items[#items + 1] = { kind = "button", text = "|cff9d9d9d" .. L.MENU_REPORT .. "|r", fn = function() ns.Print(L.REPORT_HINT) end,
		tooltip = function(tooltip)
			tooltip:SetText(L.MENU_REPORT, 1, 0.82, 0)
			tooltip:AddLine(L.REPORT_HINT, 1, 1, 1, true)
		end }
	return items
end

function Contact.OpenEntryMenu(owner, entry)
	if not entry or not entry.info then return end
	ns.Popup.Open(owner, Contact.EntryMenuItems(entry, owner))
end
