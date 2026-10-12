local _, ns = ...

--[[
"What's new" pages, one per release that reached CurseForge (newest first).
German clients get deDE, all other clients enUS. Icons are game icons (or the BGF logo).
]]

local ICON = {
	loot = "Interface\\Icons\\INV_Box_02",
	chips = "Interface\\Icons\\INV_Misc_Spyglass_02",
	tooltip = "Interface\\Icons\\INV_Misc_Note_01",
	score = "Interface\\Icons\\INV_Misc_Coin_02",
	save = "Interface\\Icons\\INV_Misc_Book_09",
	name = "Interface\\AddOns\\BetterGroupFinder\\Media\\Logo",
	list = "Interface\\Icons\\INV_Scroll_03",
	reason = "Interface\\Icons\\INV_Misc_Spyglass_03",
	whisper = "Interface\\Icons\\INV_Letter_01",
}

ns.NEWS_ORDER = { "0.9.0", "0.8.2", "0.8.1", "0.8.0" }
ns.NEWS_FIRST = "0.8.0"   -- welcome page for new users

ns.NEWS_UI = {
	enUS = {
		subtitle = "BGF - Better Group Finder Forever",
		show = "Show this after updates", hint = "(also in the options)",
		options = "Open options", ok = "Got it!",
		versions = "Versions", latest = "latest", first = "first release",
	},
	deDE = {
		subtitle = "BGF - Better Group Finder Forever",
		show = "Nach Updates anzeigen", hint = "(auch in den Optionen)",
		options = "Optionen", ok = "Alles klar!",
		versions = "Versionen", latest = "aktuell", first = "erste Version",
	},
}

ns.NEWS = {
	["0.9.0"] = {
		options = "chips",
		enUS = { title = "What's new in BGF", items = {
			{ icon = ICON.loot, title = "Avoid loot competition",
				text = "New \"Loot\" chip: groups with players who need the same gear (same class, or same armour and main stat) rank lower, or are sorted out when set to required.",
				tip = "Shift-click the chip to check for a friend instead of yourself" },
			{ icon = ICON.chips, title = "Show only the chips you need",
				text = "Hide the favourites row, the abilities row, whole categories or single chips. Hidden chips count as ignored.",
				tip = "Options › Filter & Chips" },
		} },
		deDE = { title = "Neu in BGF", items = {
			{ icon = ICON.loot, title = "Loot-Konkurrenz vermeiden",
				text = "Neuer Chip „Loot“: Gruppen mit Spielern, die dieselbe Ausrüstung brauchen (gleiche Klasse oder gleiche Rüstung und Hauptwert), rutschen nach unten oder fliegen bei „benötigt“ raus.",
				tip = "Umschalt-Klick auf den Chip: für einen Freund statt für dich prüfen" },
			{ icon = ICON.chips, title = "Nur die Chips, die du brauchst",
				text = "Favoriten-Zeile, Fähigkeiten-Zeile, ganze Kategorien oder einzelne Chips ausblenden. Ausgeblendete zählen als egal.",
				tip = "Optionen › Filter & Chips" },
		} },
	},
	["0.8.2"] = {
		enUS = { title = "What's new in BGF", items = {
			{ icon = ICON.tooltip, title = "Short chip tooltips",
				text = "Chips now show at a glance which classes bring what. Hold Shift for spells, levels and conditions.",
				tip = "Hover a chip and press Shift" },
			{ icon = ICON.score, title = "Coloured points",
				text = "Green = good fit, yellow = fits, grey = little benefit. The group value moved into the group tooltip." },
			{ icon = ICON.save, title = "Your own default filters",
				text = "\"Save\" stores the chips of a category as your default, \"Reset\" goes back to it.",
				tip = "Filter bar › Save · Reset" },
		} },
		deDE = { title = "Neu in BGF", items = {
			{ icon = ICON.tooltip, title = "Kurze Chip-Tooltips",
				text = "Chips zeigen auf einen Blick, welche Klassen was mitbringen. Mit gedrückter Umschalttaste: Zauber, Stufen, Bedingungen.",
				tip = "Über einen Chip fahren und Umschalt drücken" },
			{ icon = ICON.score, title = "Farbige Punkte",
				text = "Grün = passt gut, gelb = passt, grau = wenig Nutzen. Der Gruppenwert steht jetzt im Gruppen-Tooltip." },
			{ icon = ICON.save, title = "Eigene Standardfilter",
				text = "„Speichern“ legt die Chips einer Kategorie als deinen Standard fest, „Zurücksetzen“ kehrt dorthin zurück.",
				tip = "Filterleiste › Speichern · Zurücksetzen" },
		} },
	},
	["0.8.1"] = {
		enUS = { title = "What's new in BGF", items = {
			{ icon = ICON.name, title = "A new name",
				text = "Better Group Finder is now called \"BGF - Better Group Finder Forever\". Your settings and /bgf stay the same." },
		} },
		deDE = { title = "Neu in BGF", items = {
			{ icon = ICON.name, title = "Ein neuer Name",
				text = "Better Group Finder heißt jetzt „BGF - Better Group Finder Forever“. Deine Einstellungen und /bgf bleiben gleich." },
		} },
	},
	["0.8.0"] = {
		enUS = { title = "Welcome to BGF", items = {
			{ icon = ICON.list, title = "A compact group list",
				text = "Many more listings on screen, sorted by how much you or your group would fit in." },
			{ icon = ICON.chips, title = "Filters for classic-style groups",
				text = "Classes, buffs, dispels, crowd control, interrupts, battle res, summons – ignored, preferred or required.",
				tip = "Click the filter button next to refresh" },
			{ icon = ICON.reason, title = "Every score is explained",
				text = "Hover a listing to see why it ranks where it does. Nothing is hidden without a reason." },
			{ icon = ICON.whisper, title = "Invite + whisper in one click",
				text = "Message templates in your language, editable in the options.",
				tip = "Templates button below the list" },
		} },
		deDE = { title = "Willkommen bei BGF", items = {
			{ icon = ICON.list, title = "Eine kompakte Gruppenliste",
				text = "Viel mehr Einträge auf einen Blick, sortiert danach, wie gut du oder deine Gruppe dazupasst." },
			{ icon = ICON.chips, title = "Filter für Gruppen im Classic-Stil",
				text = "Klassen, Buffs, Dispells, Kontrolle, Unterbrechen, Kampfwiederbelebung, Beschwören – egal, bevorzugt, benötigt.",
				tip = "Filter-Knopf neben „Aktualisieren“" },
			{ icon = ICON.reason, title = "Jede Bewertung wird erklärt",
				text = "Fahr über einen Eintrag und sieh, warum er dort steht. Nichts wird ohne Grund ausgeblendet." },
			{ icon = ICON.whisper, title = "Einladen + Flüstern mit einem Klick",
				text = "Nachrichtenvorlagen in deiner Sprache, anpassbar in den Optionen.",
				tip = "Knopf „Vorlagen“ unter der Liste" },
		} },
	},
}

-- Page and UI texts for the client language (German or English).
function ns.NewsLang()
	return ns.clientLocale == "deDE" and "deDE" or "enUS"
end
