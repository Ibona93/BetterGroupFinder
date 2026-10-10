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

local INDENT = "    "

local function addTemplateButtons(root, entry, lang, prefix)
	for _, tone in ipairs({ "friendly", "short" }) do
		local key = prefix .. "_" .. tone
		local label = ns.GetTemplateName(lang, key)
		local button = root:CreateButton(INDENT .. label, function() Contact.Execute(entry, lang, key) end)
		if button and button.SetTooltip then
			button:SetTooltip(function(tooltip)
				local preview = Contact.Fill(ns.GetTemplate(lang, key), entry, lang)
				if GameTooltip_SetTitle then
					GameTooltip_SetTitle(tooltip, label)
					GameTooltip_AddNormalLine(tooltip, preview, true)
				else
					tooltip:SetText(preview, 1, 1, 1, 1, true)
				end
			end)
		end
	end
end

function Contact.OpenMenu(owner, entry)
	if not entry or not entry.info then
		ns.Print(ns.L.NO_SELECTION)
		return
	end
	if not MenuUtil or not MenuUtil.CreateContextMenu then
		-- No menu API: use the default template directly.
		Contact.Execute(entry, ns.TemplateLanguages()[1], Contact.Mode(entry) .. "_friendly")
		return
	end
	local L = ns.L
	local mode = Contact.Mode(entry)
	local target = entry.info.leaderName or "?"
	local short = Ambiguate and Ambiguate(target, "short") or target
	local titleKey = mode == "invite" and "MENU_INVITE" or (mode == "group" and "MENU_GROUP" or "MENU_JOIN")

	MenuUtil.CreateContextMenu(owner, function(_, root)
		-- Main heading in white, languages as gold sub-headings, templates indented.
		root:CreateTitle("|cffffffff" .. L[titleKey]:format(short) .. "|r")
		root:CreateDivider()
		for _, lang in ipairs(ns.TemplateLanguages()) do
			root:CreateTitle(ns.LANGUAGE_NAMES[lang] or lang)
			addTemplateButtons(root, entry, lang, mode)
		end
		root:CreateDivider()
		root:CreateButton(L.MENU_EMPTY_WHISPER, function()
			if mode == "invite" and C_PartyInfo and C_PartyInfo.InviteUnit then pcall(C_PartyInfo.InviteUnit, target) end
			if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(target) end
		end)
		root:CreateButton(L.MENU_EDIT, function()
			if ns.Options and ns.Options.Open then ns.Options.Open() end
		end)
	end)
end
