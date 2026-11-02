local _, ns = ...

--[[
Introduction tour (1.0.0): shown once at login instead of "What's new" for new installs.
With 1.0.0 every existing user sees it once as well (BetterGroupFinderDB.tourSeen is new).
German for German clients, English for all others (like the news pages).

Each page: title, text, optional green tip and `ill` = the illustration drawn by UI/Tour.lua.
`s` holds the words used inside the illustration; real chip, role and button names come from
the addon itself so they always match what the player sees.
]]

ns.TOUR_UI = {
	enUS = {
		title = "Welcome to BGF", back = "Back", next = "Next", done = "Done",
		whatsNew = "What's new?", options = "Open options",
		combat = "BGF: the options can only be opened out of combat.",
		copy = "Ctrl+C to copy",
	},
	deDE = {
		title = "Willkommen bei BGF", back = "Zurück", next = "Weiter", done = "Fertig",
		whatsNew = "Was ist neu?", options = "Optionen öffnen",
		combat = "BGF: Die Optionen lassen sich nur außerhalb des Kampfes öffnen.",
		copy = "Strg+C zum Kopieren",
	},
}

ns.TOUR = {
	enUS = {
		{ ill = "points", title = "Points and colours",
			text = "BGF rates every group for you: the more your role and your abilities are needed, the more points. The best groups are at the top.",
			tip = "Green from 40 points · yellow 15–39 · grey: little use for you",
			s = { rows = {
				{ "The Deadmines", "Leader: Thrall · 3/5", 52 },
				{ "Shadowfang Keep", "Leader: Jaina · 2/5", 24 },
				{ "Quests in Redridge", "Leader: Rexxar · 4/5", 8 },
			} } },
		{ ill = "chips", title = "Chips: say what matters to you",
			text = "Chips pick what the group should bring: classes, buffs, dispels, crowd control and more. A click switches through the states, \"required\" sorts out everything else.",
			tip = "Right-click makes a chip a favourite – it then always stays on top",
			s = { states = "A click switches:  ignored  ›  preferred  ›  required",
				ignored = "ignored", preferred = "preferred", required = "required",
				favorites = "Favourites (right-click a chip)" } },
		{ ill = "tooltip", title = "Short tooltip, details with Shift",
			text = "Hover a group to see why it got its points. Hold Shift for all the details.",
			tip = "Works on the chips too: Shift shows what each class brings",
			s = { name = "The Deadmines", score = "52 points · group 78 %",
				lines = { "Healer slot free  40", "Brings interrupt  12", "Same zone  6" } } },
		{ ill = "filter", title = "Filter bar and your own default",
			text = "The filter button next to \"Refresh\" opens the filter bar. Set it up the way you usually search and save that as your default.",
			tip = "\"Reset\" brings your default back any time",
			s = { roles = "Roles", abilities = "Abilities", own = "Your own default:",
				cats = { "Classes", "Buffs", "Dispels" } } },
		{ ill = "templates", title = "Message templates",
			text = "Select a group, click \"Templates\" and pick a message: BGF whispers the leader right away, with your class, role, level and the dungeon.",
			tip = "Change the texts and languages in the options",
			s = { menu = "Request to Thrall", lang = "English",
				preview = "Hi, Priest (Healer), lvl 22, for The Deadmines - room left?" } },
		{ ill = "discord", title = "Almost done!",
			text = "Everything else is in the options: display, showing and hiding chips, templates and \"What's new\". You can start this tour again there any time.",
			s = { head = "Questions, bugs, ideas?", line = "Join the BGF Discord." } },
	},
	deDE = {
		{ ill = "points", title = "Punkte und Farben",
			text = "BGF bewertet jede Gruppe für dich: Je mehr deine Rolle und deine Fähigkeiten gebraucht werden, desto mehr Punkte. Die besten Gruppen stehen oben.",
			tip = "Grün ab 40 Punkten · Gelb 15–39 · Grau: bringt dir wenig",
			s = { rows = {
				{ "Die Todesminen", "Anführer: Thrall · 3/5", 52 },
				{ "Burg Schattenfang", "Anführer: Jaina · 2/5", 24 },
				{ "Quests im Rotkammgebirge", "Anführer: Rexxar · 4/5", 8 },
			} } },
		{ ill = "chips", title = "Chips: sag, was dir wichtig ist",
			text = "Mit Chips wählst du, was die Gruppe haben soll: Klassen, Buffs, Dispells, Kontrolle und mehr. Ein Klick schaltet weiter, „benötigt“ sortiert alles andere aus.",
			tip = "Rechtsklick macht einen Chip zum Favoriten – der steht dann immer oben",
			s = { states = "Ein Klick schaltet weiter:  egal  ›  bevorzugt  ›  benötigt",
				ignored = "egal", preferred = "bevorzugt", required = "benötigt",
				favorites = "Favoriten (Rechtsklick auf einen Chip)" } },
		{ ill = "tooltip", title = "Kurzer Tooltip, Details mit Shift",
			text = "Fahr mit der Maus über eine Gruppe: Du siehst, warum sie wie viele Punkte hat. Mit gedrückter Umschalttaste kommen alle Details dazu.",
			tip = "Gilt auch für die Chips: Shift zeigt, was jede Klasse mitbringt",
			s = { name = "Die Todesminen", score = "52 Punkte · Gruppe 78 %",
				lines = { "Heiler-Platz frei  40", "Bringt Unterbrechen  12", "Gleiche Zone  6" } } },
		{ ill = "filter", title = "Filterleiste und eigener Standard",
			text = "Der Filter-Knopf neben „Aktualisieren“ klappt die Filterleiste auf. Stell sie einmal so ein, wie du meistens suchst, und speicher das als deinen Standard.",
			tip = "„Zurücksetzen“ holt jederzeit deinen Standard zurück",
			s = { roles = "Rollen", abilities = "Fähigkeiten", own = "Dein eigener Standard:",
				cats = { "Klassen", "Buffs", "Dispells" } } },
		{ ill = "templates", title = "Nachrichtenvorlagen",
			text = "Gruppe auswählen, auf „Vorlagen“ klicken, Nachricht wählen: BGF flüstert den Anführer sofort an, mit deiner Klasse, Rolle, Stufe und der Instanz.",
			tip = "Texte und Sprachen passt du in den Optionen an",
			s = { menu = "Anfrage an Thrall", lang = "Deutsch",
				preview = "Hi, Priester (Heiler), St. 22, für Die Todesminen - noch Platz?" } },
		{ ill = "discord", title = "Fast geschafft!",
			text = "Alles Weitere findest du in den Optionen: Anzeige, Chips ein- und ausblenden, Vorlagen und „Neu in BGF“. Die Tour kannst du dort jederzeit neu starten.",
			s = { head = "Fragen, Bugs, Ideen?", line = "Komm auf den BGF-Discord." } },
	},
}

function ns.TourPages()
	return ns.TOUR[ns.NewsLang()] or ns.TOUR.enUS
end

function ns.TourUI()
	return ns.TOUR_UI[ns.NewsLang()] or ns.TOUR_UI.enUS
end
