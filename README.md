# BGF - Better Group Finder Forever 0.8.2

Autor: **Ibona93** · Kontakt über die Projektseite · Lizenz: MIT (siehe `LICENSE`; mitgelieferte Schriften: SIL OFL 1.1). – WoW Forever

Erweiterung für den Gruppenfinder von WoW Forever:
- intelligente Filter
- Bewertung der Gruppenzusammensetzung
- Nachrichtenvorlagen mit automatischem Versand
- übersichtliche zweizeilige Liste mit farbigen Punkten

Ziel-Version: WoW Forever **1.60.1, Interface 16001** (Beta-Stand 9. Oktober 2026).

---

## 1. Installation

1. Das Spiel schließen (oder später `/reload` eingeben).
2. Das ZIP entpacken. Heraus kommt der Ordner `BetterGroupFinder`.
3. Den Ordner in den AddOns-Ordner des Forever-Clients kopieren. In der Beta ist das:
   `World of Warcraft\_classic_beta_\Interface\AddOns\BetterGroupFinder`
   Nach dem Release heißt der Client-Ordner voraussichtlich anders. Entscheidend ist der Ordner, aus dem du Forever startest.
4. Der Ordner muss direkt `BetterGroupFinder.toc` enthalten. Ein Ordner `BetterGroupFinder\BetterGroupFinder\…` funktioniert nicht.
5. Im Charakterauswahl-Bildschirm unter **AddOns** „BGF - Better Group Finder Forever“ aktivieren.
6. Empfohlen für die ersten Tests: **BugSack + BugGrabber** installieren, damit eventuelle Lua-Fehler gesammelt werden.

Falls das Spiel das Addon als „veraltet“ markiert, hat sich nach einem Patch die Interface-Nummer geändert. Prüfen mit `/dump (select(4, GetBuildInfo()))` und die Zahl in der ersten Zeile der `.toc` anpassen.

---

## 2. Funktionen im Überblick

| Bereich | Was BGF macht |
|---|---|
| Ergebnisliste | Eigene Liste im Gruppenfinder-Fenster in Blizzards Optik. Bereiche: **Gruppen**, **Spieler**, **Aussortiert** (eingeklappt, mit Begründung). Sortiert nach BGF-Punkten. |
| Fenstergröße | Das Fenster behält **Blizzards Originalbreite und -höhe**. Es wird nur höher, solange die Filterleiste offen ist (außerhalb des Kampfes). |
| Einträge | Zweizeilig: Name (+ Stufe, „Neue Spieler willkommen“) oben, Instanz darunter. Spielstil und Rollen-Icons mittig in der Zeile, jedes Rollen-Icon mit Ring in Klassenfarbe. Bei Schlachtzügen erscheinen Rollenzahlen statt Einzel-Icons. |
| Punkte | Rechts der Nutzen („30“), farbig wie die M+-Wertung in Retail: grün = passt gut (ab 40), gelb = passt (15–39), grau = wenig Nutzen; bei Quests & Zonen neutral weiß. Der **Gruppenwert** („72 %“, wie vollständig die Gruppe schon ist) steht im Tooltip direkt unter dem Urteil. Abschaltbar in den Optionen; dort erklärt „Wie entstehen die Punkte?“ die Berechnung. |
| Schrift | Feste Größen wie bei Blizzard: Namen 14, alles andere 12. Schriftart wählbar (Standard: die WoW-Schrift). |
| Eigener Eintrag | Zeigt die Mitglieder deiner Gruppe (Klassenfarbe, Rolle), die noch fehlende Rolle als blasses Symbol und in Zeile 2 „Eure Einträge · Aktivität“. Ohne Punkte. |
| Abkürzungen | Passt ein Text nicht, kürzt BGF zuerst sinnvoll: „Höhlen d. Wehklagens“, „Ruinen v. Lordaeron“, „Aldarin S.“. Erst dann wird mit „…“ abgeschnitten. Der Tooltip zeigt immer die vollen Namen. |
| Filterleiste | Filter-Button neben „Aktualisieren“ (bleibt eingedrückt, solange die Leiste offen ist). Abgerundete Chips, Punkt = benötigt, Halbkreis = bevorzugt, Häkchen = gewählte Rolle, Stern = Favorit, türkiser Rand = mit ausgewählt. Eine eigene Zeile **Favoriten**, darunter die Kategorien **Klassen**, **Buffs**, **Dispells** und **Kampf & Hilfsmittel** zum Aufklappen. Zugeklappte Kategorien stehen nebeneinander (grau), mit Zähler für aktive Chips („+ Buffs (2)“); eine geöffnete bekommt eigene Zeilen und einen goldenen Kategorie-Chip. |
| Filter aus | Haken „BGF-Filter aktiv“ entfernen: die BGF-Ansicht bleibt, aber ohne Punkte, ohne Aussortieren, in Blizzards Reihenfolge. Die Leiste bleibt offen (Filter ausgegraut). |
| Notausgang | `/bgf off` zeigt Blizzards Originalliste (ohne Filterleiste und Filter-Button), `/bgf on` holt BGF zurück. |
| Logo | Erscheint in der Addon-Liste. |
| Bewertung | Automatisch aus deiner Sicht: solo „passe ich rein?“, in einer Gruppe „passt der zu uns?“. Zwei Gruppen werden auf einen Zusammenschluss geprüft. |
| Tooltip | Blizzards Tooltip (Mitglieder, Voicechat, Aktivität) plus darunter die BGF-Begründung: grün = Vorteil, rot = Abzug, grau = Lücke, orange = Ausschlussgrund. |
| Vorlagen-Button | Im Footer zwischen „Nachricht senden“ und „Gruppeneinladung“. Öffnet das Vorlagen-Menü; ein Klick auf eine Vorlage **sendet sofort**. |
| Rechtsklick auf Eintrag | Eigenes Kontextmenü: Nachricht senden, Einladen (wenn möglich), Vorlagen …, dazu „Melden …“ als Hinweis: Melden erlaubt Blizzard Addons nicht (`C_ReportSystem.SendReport` „Not allowed to be called by addons“), es geht in Blizzards Liste nach `/bgf off`. |
| Sprachen | Oberfläche in allen 11 Clientsprachen. Vorlagen: deine Spielsprache plus Englisch. |

---

## 3. Bedienung

### Filterleiste
- **Speichern · Zurücksetzen** (rechts in der ersten Zeile): „Speichern“ legt die Chips der gerade angezeigten Gruppenfinder-Kategorie als deinen eigenen Standard fest. „Zurücksetzen“ stellt die Chips dieser Kategorie auf deinen Standard zurück (ohne gespeicherten Standard: auf den eingebauten) und die Rollen auf automatisch; Favoriten und die anderen Kategorien bleiben. „Filter zurücksetzen“ in den Optionen setzt alle Kategorien zurück, „Standards wiederherstellen“ löscht deine eigenen Standards.
- **BGF-Filter aktiv:** schaltet Bewertung, Sortierung und Aussortieren ein oder aus. Die BGF-Ansicht und die Leiste bleiben.
- **Bewertung für:** deine Perspektive, z. B. „Jäger 22 · DPS“ oder „Deine Gruppe (3)“. Bei wenig Platz entfällt das Wort „Bewertung für:“.
- **Profil:** wird nicht angezeigt, folgt aber der Kategorie oben im Fenster (Dungeons, Schlachtzüge, sonstige). Jede Kategorie hat eigene Chip-Einstellungen.
- **Freier Platz für / Gesucht:** automatisch gesetzt (solo deine Rollen aus dem Gruppenfinder, in einer Gruppe die fehlenden Rollen). Ein Klick wechselt auf manuelle Auswahl; „Filter zurücksetzen“ in den Optionen stellt wieder auf automatisch. Das erklärt auch der Tooltip der Rollen-Chips. Solo gelten die Chips für dich: bei Gruppen als die Rolle, mit der du beitrittst; bei anderen Einzelspielern (ihr würdet eine Gruppe aufmachen) schränken sie den anderen nicht ein.
- **Chips:** Linksklick wechselt zwischen *egal* (grau), *bevorzugt* (weiß, Halbkreis) und *benötigt* (gold, Punkt). **Rechtsklick** macht einen Chip zum Favoriten (Stern) oder entfernt ihn wieder; Favoriten stehen zusätzlich in der Favoriten-Zeile, es ist derselbe Chip. Start-Favoriten: Kontrolle, Unterbrechen, Kampfwiederbelebung, Angriffskraft, Mana. Der Tooltip eines Chips ist kurz: welche Klassen die Fähigkeit mitbringen, darunter „evtl.:“ für Klassen, die sie nur mit Talent, Begleiter, Form o. ä. haben, und der Hinweis „Umschalt gedrückt halten: Details“. Mit gedrückter Umschalttaste (live) zeigt er Klasse, Zauber und Lernstufe, bei Bedingungen mit Hinweis (z. B. „Krieger – Schildhieb ab Stufe 12 (nur mit Schild)“, „Priester – Stille ab Stufe 30 (Talent)“). Die Zaubernamen kommen aus dem Spiel, also in deiner Clientsprache.
- **Kategorien:** *Klassen* (9 Chips, „diese Klasse in der Gruppe“, von Haus aus *egal*), *Buffs* (Angriffskraft, Mana, Seelenstärke, Arkane Intelligenz, Mal der Wildnis, Segen der Könige, Segen der Rettung, Göttlicher Willen, Furchtzauberschutz), *Dispells* (Fluch, Magie, Gift, Krankheit), *Kampf & Hilfsmittel* (Kontrolle, Unterbrechen, Kampfwiederbelebung, Gesundheitsstein, Beschwören). Der Tooltip eines Klassen-Chips zeigt kurz eine Zeile pro Bereich (nur bedingt verfügbare Fähigkeiten grau); mit Umschalt die Vollansicht mit allem, was die Klasse der Gruppe bringt: Bereiche Kampf & Hilfsmittel, Dispells, Buffs (goldene Überschriften), ein Zauber pro Zeile, Name weiß, Stufe grau, Bedingung orange, dahinter der Chip („– Kontrolle“) oder bei Buffs der Effekt in Hellblau („· Ausdauer +“). Am Ende steht türkis, was die Klasse mit auswählt.
- **Verknüpfung:** Ein Klassen-Chip wählt die Buffs seiner Klasse im gleichen Zustand mit aus (Krieger *benötigt* → Angriffskraft *benötigt*; Hexenmeister → Gesundheitsstein und Beschwören). Ein Chip, den nur eine Klasse bringt, wählt die Klasse mit aus (Seelenstärke → Priester). Keine Kettenreaktion. Mit ausgewählte Chips haben einen türkisen Rand; ein Klick darauf schaltet sie trotzdem ab („abgewählt trotz …“, gedämpft türkiser Rand und durchgestrichen), bis der auslösende Chip wieder aus ist. Mit ausgewählte Chips geben Punkte und Abzüge, sortieren aber nicht allein aus.
- **Vorrang:** Einträge, die alle Chips erfüllen, die du selbst auf *benötigt* gestellt hast, stehen in Gruppen und Spielern immer oben; die übrigen folgen mit dem Hinweis „Nachrangig“.

### Vorlagen-Button
| Auswahl | Was passiert | Menü-Überschrift |
|---|---|---|
| Gruppe, du bist solo | Beitrittsanfrage an den Gruppenleiter | „Beitrittsanfrage an …“ |
| Gruppe, du bist in einer Gruppe | Anfrage als Gruppe (Zusammenschluss) | „Anfrage als Gruppe an …“ |
| Einzelspieler, du darfst einladen | Einladung **und** Einladungsnachricht | „Einladen + Nachricht an …“ |

Aufbau des Menüs: weiße Überschrift (was passiert), darunter die Sprachen in Gold (deine Spielsprache, dann Englisch), darunter eingerückt die Vorlagen. Wer mit der Maus über eine Vorlage fährt, sieht den fertigen Text. Ist der Chat gerade gesperrt (Kampf in Instanzen) oder schlägt das Senden fehl, steht der Text fertig im Chatfenster; dann genügt Enter.

### Befehle
| Befehl | Wirkung |
|---|---|
| `/bgf` | Optionen öffnen |
| `/bgf off` / `/bgf on` | Notausgang: Blizzards Originalliste / BGF wieder an |
| `/bgf debug` | Debug-Ausgabe an/aus. Beim Hovern über einen Eintrag werden dessen Rohdaten (inkl. `mapID`, Spezialisierung) in den Chat geschrieben. |

### Optionen (`/bgf` oder Optionen → AddOns → BGF - Better Group Finder Forever)
- Sofort senden, BGF-Bewertung im Tooltip, **Punkte anzeigen** (mit Button „Wie entstehen die Punkte?“), BGF-Filter aktiv
- **Schriftart** mit Vorschau:
  - im Spiel enthalten: Friz Quadrata (Standard), Arial Narrow, Morpheus, Skurri
  - mitgeliefert: Philosopher, PT Sans Narrow, Roboto Condensed, Noto Sans
  - zusätzlich alle Schriften aus **LibSharedMedia**, falls ein anderes Addon (z. B. Details, WeakAuras, ElvUI) sie mitbringt. Umgekehrt stellt BGF seine Schriften dort auch anderen Addons bereit.
  - Koreanische und chinesische Clients verwenden immer die Spielschrift.
- **Vorlagen** je Sprache (Spielsprache und Englisch): pro Vorlage ein **Name** (erscheint im Menü) und der **Text**. Leeres Feld = Standard. „Vorlagen dieser Sprache zurücksetzen“ setzt Namen und Texte zurück.

Platzhalter in Vorlagen:

| Platzhalter | Wird ersetzt durch |
|---|---|
| `{name}` | Empfänger |
| `{me}` | deinen Namen |
| `{class}` | deine Klasse (in der Sprache der Vorlage) |
| `{role}` | deine Rolle |
| `{level}` | deine Stufe |
| `{instance}` | die Aktivität; im englischen Text mit englischem Namen (eigene Namenstabelle nach Karten-ID, z. B. „Shadowfang Keep“ statt „Burg Shadowfang“) |
| `{group}` | deine Gruppe, z. B. „Krieger (Tank), Priester (Heiler)“ |

---

## 4. Filter- und Bewertungslogik

Die Logik liegt in `Logic/Scoring.lua` und ist reines Lua ohne Spiel-API (offline getestet).

**Wer ist Gastgeber, wer Gast?** Die größere Seite ist der Gastgeber, bei Gleichstand deine.
- Solo vs. Gruppe: Die Gruppe nimmt dich auf.
- Deine Gruppe vs. Einzelspieler: Ihr nehmt ihn auf.
- Gruppe vs. Gruppe: Zusammenschluss.

**Rollenziele:**
- Dungeon (5er): 1 Tank / 1 Heiler / 3 DPS, **streng**. Überzählige Rollen werden aussortiert.
- Schlachtzug:
  - 10er: 2 / 3 / 5
  - 20er: 3 / 5 / 12
  - 40er: 4 / 10 / 26
  - Andere Größen werden anteilig skaliert. Überzählige Rollen geben nur Abzug.
- Quests & Zonen / Benutzerdefiniert: keine Rollenziele, keine Rollenprüfung (Rollen-Chips ausgegraut), keine Abzüge für gleiche Klasse oder fehlenden Nutzen, kein Aussortieren wegen 0 Punkten.

Spieler mit mehreren angebotenen Rollen bekommen zuerst einen freien Tank- oder Heilerplatz (knappe Rollen), dann DPS.

**Punkte:**

| Faktor | Punkte |
|---|---|
| Füllt fehlenden Tank / Heiler | +40 |
| Füllt fehlenden DPS-Platz | +20 |
| Bringt fehlende Fähigkeit | + Gewicht (×1,5 bei „benötigt“, ×1,5 bei Instanz-Hinweis) |
| Fähigkeit nur „möglich“ (Talent/Begleiter/Schild/Kreaturtyp) | + halbes Gewicht; im Tooltip mit der echten Bedingung, z. B. „bringt evtl. Unterbrechen (Talent)“ |
| Gruppe wäre vollständig | +10 |
| Zusammenschluss möglich | +5 |
| Weitere gleiche Klasse ohne neuen Nutzen | −10 (Schlachtzug −5) |
| Kein neuer Nutzen | −5 (Schlachtzug −2) |
| Stufe außerhalb der Empfehlung | −8 |
| Überzählige Rolle im Schlachtzug | −8 |
| „Benötigt“ fehlt noch oder ist nur „möglich“, aber es sind Plätze frei | − halbes Gewicht |

**Gewichte der Fähigkeiten:**

| Fähigkeit | Gewicht |
|---|---|
| Kontrolle | 10 |
| Unterbrechen | 8 |
| Beschwören | 7 |
| Fluch entfernen, Magie bannen, Kampfwiederbelebung, jede Klasse (Klassen-Chips) | 6 |
| Gift heilen, Krankheit heilen | 5 |
| Seelenstärke, Furchtzauberschutz | 4 |
| Mal der Wildnis, Segen der Könige, Gesundheitsstein | 3 |
| Angriffskraft, Mana, Arkane Intelligenz, Segen der Rettung, Göttlicher Willen | 2 |

Im Schlachtzug zählt eine Klasse nur einmal: Ist schon ein Druide dabei, bringt ein zweiter für den Druiden-Chip nichts mehr.

**Aussortiert** (in den Bereich „Aussortiert“, nie unsichtbar) werden:
- zu viele Spieler zusammen
- kein Platz für die Rolle (mit Angabe, welche Rolle noch gesucht wird)
- Rolle nicht gesucht (manuelle Rollen-Auswahl)
- eine selbst auf *benötigt* gestellte Fähigkeit oder Klasse fehlt (oder ist nur „möglich“) und kann nicht mehr dazukommen: kein Platz frei, oder keine Klasse, die sie mitbringt, kann eine der noch offenen Rollen spielen („Benötigt: Magier passt auf keinen freien Platz mehr“)
- Stufe unter der Mindeststufe der Aktivität
- passt nicht zum Aktivitätsfilter, nicht mehr gelistet
- **0 Punkte oder weniger** („Kein echter Mehrwert“)

**Gruppenwert** (nur bei Gruppen, nur mit Rollenzielen, also nicht bei Quests & Zonen):
- 60 % Rollen: besetzte Plätze im Verhältnis zum Ziel, Tank- und Heilerplätze zählen doppelt.
- 40 % Fähigkeiten: alle Fähigkeiten, die nicht auf „egal“ stehen (plus Instanz-Hinweise), gewichtet wie oben; „möglich“ zählt halb.
- Der Tooltip zeigt die Details: „Gruppenwert 72 %: Rollen 3/5, Fähigkeiten 2/3“.

Werden alle Treffer aussortiert, erscheint oben der Hinweis „Alle X Treffer wurden aussortiert – Filter lockern?“.

**Fähigkeiten:**
- Eigener Charakter: BGF prüft dein Zauberbuch. Das gilt aber nur, wenn die Klassik-Spell-IDs in Forever erkannt werden. Sonst fällt BGF auf Klasse + Stufe zurück, siehe `/bgf debug` → „spellbook check“.
- Andere Spieler: Klasse + Stufe. Talente, Begleiter, Schild oder Kreaturtyp machen eine Fähigkeit nur „möglich“.
- Talente stammen aus den Talentbäumen der Forever-Beta (Build 1.60.1.70291): frühestens ab Stufe 10 + 5 × (Reihe − 1). Hast du selbst das Talent gelernt, zählt es bei dir als sicher.
- Aufgenommene Talente: Erschütternder Schlag (Krieger), Buße (Paladin), Streuschuss, Einschüchterung und Aura des Volltreffers (Jäger), Stille (Priester), Totem der Manaflut (Schamane), Wilde Attacke (Druide).
- Eine vorhandene Fähigkeit wird nicht noch einmal als fehlend oder als Vorteil gezählt.

**Instanz-Hinweise** (`Data/Profiles.lua`): Für bekannte Instanzen werden bestimmte Fähigkeiten höher gewichtet und auch dann berücksichtigt, wenn sie auf „egal“ stehen. Beispiele sind Gift und Magie in den Höhlen des Wehklagens oder Krankheit und Fluch in Stratholme. Für Furcht-Instanzen (Schwarzfelstiefen, Geschmolzener Kern, Onyxias Hort, Pechschwingenhort) wird Furchtzauberschutz berücksichtigt. Neue Forever-Instanzen kannst du dort ergänzen. Die `mapID` liefert `/bgf debug`.

**Unbekannte Daten:**
- Fehlen Klasse oder Rolle, wird das als „? …“ gekennzeichnet und nicht geraten.
- Sind die Mitgliederdaten gesperrt (Chat-Sperre im Kampf in Instanzen), zeigt BGF das als Hinweis an und bewertet erst danach wieder.

---

## 5. Bekannte Einschränkungen

- **Nicht im Spiel getestet.** BGF wurde gegen Blizzards veröffentlichten Forever-UI-Code (1.60.1) und die offizielle API-Dokumentation gebaut, aber ohne Client. Siehe Abschnitt 6.
- **Sprache des Gegenübers** liefert die API nicht. Darum wählst du im Menü zwischen deiner Sprache und Englisch.
- **Spezialisierung und Talente** fremder Spieler sind nicht verfügbar: Das Feld `specName` enthält in der Beta nur den Klassennamen. Talentabhängige Fähigkeiten zählen deshalb nur als „möglich“.
- **Talentdaten** stammen aus [talentsforever.com](https://talentsforever.com/) (Daten aus dem Beta-Client, Build 1.60.1.70291, Lizenz CC BY 4.0), geprüft an einzelnen Wowhead-Forever-Zauberseiten. Bis zum Release (4. November 2026) können sich Talente noch ändern. Die Lernstufe von Hieb (Druide) ist aus Classic übernommen und nicht für Forever bestätigt.
- **Fähigkeitentabelle** (`Data/Abilities.lua`): Lernstufen und Spell-IDs stammen aus WoW Classic.
  - Zaubernamen im Tooltip liefert das Spiel (`C_Spell.GetSpellName`). Kennt Forever eine ID nicht, zeigt BGF den Namen aus der Tabelle: auf Deutsch, in allen anderen Sprachen auf Englisch.
  - Für Forever bestätigt: kein Kampfrausch/Heldentum, Furchtzauberschutz für alle Priester ab 20, Segen der Könige (20) und der Rettung (26) sowie Göttlicher Willen (30) ohne Talent, kein Stich des Flügeldrachen.
  - Nach Klassenpatches muss die Tabelle eventuell angepasst werden.
- **Schlachtzüge** gibt es in der Beta noch nicht; die Schlachtzug-Logik ist nur offline getestet.
- **Karten-IDs:** Forever nutzt die Classic-IDs (geprüft: Burg Shadowfang 33, Todesminen 36, Höhlen des Wehklagens 43); Ruinen von Lordaeron hat 2999. Instanz-Hinweise und Namenstabelle bauen darauf auf. Flügel werden nur aus dem Deutschen übersetzt.
- **Eigene Menüs:** Vorlagen-Menü und Schriftarten-Liste sind eigene, einfache Fenster (`UI/Popup.lua`), nicht Blizzards Menüsystem. Mit `/console taintLog 1` stürzte der Beta-Client (1.60.1.70291) ab, wenn ein Addon-Knopf ein Blizzard-Menü öffnete (Assertion in `ldebug.c`). Auch das Rechtsklick-Menü auf Einträgen ist ein eigenes Menü. Escape schließt BGF-Fenster über eine eigene Tastenabfrage (außerhalb des Kampfes), nicht über Blizzards Liste `UISpecialFrames`.
- **Keine Kategorie vorausgewählt:** Blizzard startet ohne Kategorie, BGF zeigt dann den Hinweis „Wähle oben links eine Kategorie“. Vorauswählen kann BGF sie nicht: Die Suche ist geschützt und würde durch einen Addon-Wert blockiert.
- **Keine Hooks auf Blizzard-Funktionen:** BGF folgt dem Gruppenfinder über dessen Ereignisse (Suchergebnisse empfangen, Suche fehlgeschlagen, Eintrag geändert) und hängt sich nur an Fenster-Skripte (Öffnen, Schließen, Aktualisieren-Knopf). Mit eingeschaltetem Taint-Log brach der Beta-Client sonst Blizzards Aufrufkette beim Öffnen des Reiters ab.
- **Sprachen außer Deutsch/Englisch** sind von mir übersetzt und sollten vor einer Veröffentlichung von Muttersprachlern geprüft werden.
- **Fensterhöhe:** Mit offener Filterleiste ändert BGF die Höhe von Blizzards Fenster, nur außerhalb des Kampfes, um Taint zu vermeiden. Siehe Taint-Test unten.
- **Spaltenbreiten und Abkürzungen** sind gegen geschätzte Schriftbreiten getestet, nicht im Client gemessen.
- **Die Suche** selbst startet BGF nie. Sie bleibt geschützt und läuft über Blizzards Aktualisieren-Button.
- **Einladen** ist wie bei Blizzard nur für Einzelspieler möglich. Gruppen erreicht man über die Anfrage an den Leiter.

---

## 6. Tests

### Durchgeführt (ohne Spielclient)

| Test | Umfang | Ergebnis |
|---|---|---|
| `luacheck` (Lua 5.1) | alle 26 Lua-Dateien | 0 Warnungen, 0 Fehler |
| `tests/run.lua` | Bewertungslogik, Szenarien 1–7 und 12, Pflicht-Fähigkeiten, Stufen, Rollenwahl, Instanz-Hinweise, fehlende/gesperrte API, Gruppenwert, zusammengefasste Fähigkeiten und Umstellung alter Einstellungen, Mana-Buffs, Zauber je Klasse vollständig, Klassen-Chips, Talente als „möglich“ (eigene gelernte sicher), strengeres „benötigt“, Bedingung in der Begründung, Verknüpfungen und Überstimmen, offene Rollen bei „benötigt“, Instanznamen für englische Vorlagen, Abkürzungen, Vorlagensprachen und -namen; Vollständigkeit aller 11 Sprachdateien | 118/118 bestanden |
| `tests/smoke.lua` | komplettes Addon in TOC-Reihenfolge mit nachgebildeter WoW-Oberfläche: Laden, Events, Liste mit Daten wie in den Beta-Screenshots, Spaltenbreiten und Abkürzungen bei Originalbreite (Schrift 12/14), Aussortieren, Filterleiste (Fenster nur höher, nicht breiter), Chips, „+ mehr“, Haken aus/an (BGF-Ansicht bleibt, keine Punkte, nichts aussortiert), Gruppenwert nur bei Gruppen, Chip-Tooltips (Klasse – Zauber ab Stufe, Bedingungen, Talente, Zaubernamen aus dem Spiel), Klassen-Tooltips nach Bereichen, Favoriten per Rechtsklick, Kategorien mit Zähler und eigenen Zeilen, Verknüpfung Krieger → Angriffskraft mit Überstimmen, Tooltip-Zeilen mit Farben und Effekten, goldener Chip für geöffnete Kategorien, Vorrang für „benötigt“ in der Liste, englischer Instanzname in der Vorlage, Rollen-Tooltip, keine Profilanzeige, Erklärungsfenster mit Abschnitten, Option „Punkte anzeigen“, Erklärungsfenster, `/bgf off` ohne Leiste und Button, Schriftarten inkl. LibSharedMedia, Vorlagen-Menü (Überschrift, nur zwei Sprachen, eigene Namen), Platzhalter, automatisches Senden, Fallback bei Chat-Sperre, Einladen + Nachricht, Tooltip, `/bgf`-Befehle | alle bestanden |

Die Tests lassen sich mit Lua 5.1 erneut ausführen: `lua tests/run.lua` und `lua tests/smoke.lua` aus dem Addon-Ordner.

### Nur konzeptionell geprüft, bitte im Spiel testen

Vorher `/console taintLog 1` eingeben. Nach dem Test liegt die Datei `Logs\taint.log` im Client-Ordner.

| # | Test | Erwartung |
|---|---|---|
| 1 | Gruppenfinder öffnen → Suche → Dungeons | BGF-Liste in Blizzard-Optik, Fenster in Originalgröße, +/- in den Bereichsköpfen korrekt |
| 2 | Filter-Button | Filterleiste klappt auf, Fenster wird länger, Liste gleich hoch, Button bleibt eingedrückt, Zahnrad frei |
| 3 | Fähigkeit auf „benötigt“ stellen | Punkt im Chip; Treffer ohne diese Fähigkeit rutschen nach unten bzw. zu „Aussortiert“ |
| 4 | Liste ansehen | Spielstil auf Höhe der Rollen-Icons; rechts nur die Punkte ohne „+“, grün/gelb/grau; nichts überlappt |
| 5 | Über Fähigkeiten-Chips fahren | kurzer Tooltip mit Klassen und Hinweis; Umschalt gedrückt: „Klasse – Zauber ab Stufe …“, Talente mit „(Talent)“; Loslassen wieder kurz |
| 5a | Kategorien auf- und zuklappen, Rechtsklick auf Chips | geöffnete Kategorie in eigenen Zeilen; Stern und Favoriten-Zeile; Krieger *benötigt* → Angriffskraft mit türkisem Rand |
| 5c | Optionen → Schriftart aufklappen | jeder Eintrag in seiner eigenen Schrift |
| 5d | Englische Vorlage an eine Gruppe in Burg Shadowfang | Text nennt „Shadowfang Keep“ |
| 5b | Optionen → „Wie entstehen die Punkte?“ | Abschnitte mit goldenen Überschriften, Plus grün, Abzüge rot, Aussortiert orange; scrollbar, falls zu lang |
| 6 | Optionen → Schriftart wechseln | Liste, Filterleiste und Tooltip übernehmen die Schrift |
| 7 | Eintrag hovern | Blizzard-Tooltip + BGF-Begründung darunter, Urteil farbig, bei Gruppen der Gruppenwert direkt darunter |
| 8 | Gruppe wählen → Vorlagen → Freundlich | Flüsternachricht wird gesendet, Platzhalter korrekt |
| 9 | Als Gruppenleiter Einzelspieler → Vorlagen | Einladung + Nachricht |
| 10 | Haken „BGF-Filter aktiv“ aus/an | BGF-Ansicht bleibt, ohne Punkte/Aussortieren; nichts verschwindet hinter der Leiste. `/bgf off` → Originalliste |
| 11 | Nach dem Test: Dungeon betreten, kämpfen, Aktionsleisten benutzen | **Bestanden (0.7.8, 10.10.2026):** Dungeon mit Kampf, Taint-Log Stufe 1 ohne einen Eintrag zu BetterGroupFinder. Einladen + Nachricht über die Vorlagen im echten Einsatz bestätigt. |
| 12 | `/bgf debug`, über Einträge fahren | Rohdaten erscheinen. Bitte prüfen, ob `spec` gefüllt ist und welche `mapID` die Forever-Instanzen haben |

Fehlermeldungen (BugSack) und Auffälligkeiten bitte mit Screenshot melden.

---

## 7. Dateien

```
BetterGroupFinder.toc   Interface 16001, SavedVariables BetterGroupFinderDB
Init.lua                Namensraum, Hilfsfunktionen, Sprachlisten
Locales/*.lua           11 Sprachen: Oberfläche, Klassen-/Rollenwörter, Standardvorlagen
Data/Abilities.lua      Fähigkeiten je Klasse (Stufe, Spell-IDs, sicher/möglich)
Data/Profiles.lua       Rollenziele, Standard-Filter je Profil, Instanz-Hinweise
Data/Abbreviations.lua  Abkürzungsregeln je Sprache (des -> d., von -> v. ...)
Data/Instances.lua      Instanznamen Englisch/Deutsch nach Karten-ID (für {instance})
Logic/Scoring.lua       Bewertung (ohne Spiel-API)
Logic/Engine.lua        Liest Gruppenfinder-Daten, Perspektive, Zauberbuchprüfung
Core.lua                Einstellungen, Events, /bgf, Sprache, Vorlagen
UI/Fonts.lua            Schriftarten (Spiel, mitgeliefert, LibSharedMedia)
UI/List.lua             BGF-Liste, Zeilen, Bereiche, Spaltenbreiten, Abkürzen
UI/Templates.xml        Zeilen-/Kopf-Vorlagen
UI/Tooltip.lua          Tooltip mit Begründung
UI/FilterBar.lua        Filterleiste
UI/Popup.lua            eigenes kleines Menü (Vorlagen, Schriftarten)
UI/Contact.lua          Vorlagen-Button und -Menü, Platzhalter, Versand
UI/Options.lua          Optionen und Vorlagen-Editor
UI/Main.lua             Einbindung in Blizzards Fenster, Header-Buttons, Fensterhöhe
Media/Circle.tga        Kreis-Textur für Chips und Symbole
Media/Logo.tga          Logo für die Addon-Liste (64x64), Quelle: Media/bgf_logo.svg
Media/Fonts/            mitgelieferte Schriften + Lizenzen (SIL OFL, siehe FONTS.txt)
tests/                  Offline-Tests (vom Spiel nicht geladen)
```

Alle Einstellungen werden accountweit in `WTF\Account\<Account>\SavedVariables\BetterGroupFinder.lua` gespeichert.

---

## 8. Änderungen

**0.8.2**
- Chip-Tooltips kurz: Fähigkeiten zeigen die Klassen (darunter „evtl.:“ für Talent, Begleiter, Form), Klassen eine Zeile pro Bereich. Umschalt gedrückt halten zeigt die Details (Zauber, Stufe, Bedingungen), live; ein Hinweis steht im Tooltip.
- Punkte ohne „+“ und farbig: grün ab 40, gelb 15–39, grau darunter (Quests neutral). Der Gruppenwert in Prozent steht jetzt im Tooltip statt in der Liste.
- Eigener Standard: „Speichern“ in der Filterleiste legt die Chips einer Kategorie als deinen Standard fest, „Zurücksetzen“ kehrt dorthin zurück. In den Optionen: „Standards wiederherstellen“.

**0.8.1**
- Neuer Name: „BGF - Better Group Finder Forever“ (Addon-Liste, Optionen); Chat-Präfix und Filter-Tooltip heißen jetzt „BGF“. Ordner, Einstellungen und `/bgf` bleiben gleich.

**0.8.0** – erste öffentliche Beta
- MIT-Lizenz (`LICENSE`), Release-ZIP ohne Testdateien.

**0.7.9**
- Eigener Eintrag zeigt die Mitglieder deiner Gruppe, die fehlende Rolle blass und die Aktivität („Eure Einträge · Todesminen“).

**0.7.8**
- Rollenanzeige: bis 5 Mitglieder Icons (auch bei Quests, die 40 melden), Zahlen erst ab 6; „/40“ nur bei Schlachtzügen; Spielstil überlappt die Zahlen nicht mehr.
- Eigenes Kontextmenü beim Rechtsklick auf Einträge (Nachricht, Einladen, Vorlagen, Hinweis zum Melden) statt Blizzards Menü.
- Escape ohne Blizzards `UISpecialFrames`-Liste: BGF erscheint im Taint-Log nur noch beim Slash-Befehl und beim Öffnen der Optionen.

**0.7.7**
- Hinweis in der leeren Liste, solange keine Kategorie gewählt ist.
- Filterleiste wird bei jeder Aktualisierung neu angeordnet: keine zu großen oder zu kleinen Abstände zwischen Chips mehr nach einem Kategoriewechsel.

**0.7.6**
- Ereignisse statt Hooks auf Blizzards Listen- und Knopf-Funktionen: kein Fehler mehr beim Öffnen des Reiters mit eingeschaltetem Taint-Log.

**0.7.5**
- „Zurücksetzen“ direkt in der Filterleiste (nur die angezeigte Kategorie).
- Vorlagen-Menü und Schriftarten-Liste als eigene Menüs statt Blizzards Menüsystem: behebt den Spielabsturz mit eingeschaltetem Taint-Log.

**0.7.4**
- Quests & Zonen / Benutzerdefiniert: keine Rollenprüfung (Rollen-Chips ausgegraut), keine Abzüge für gleiche Klasse, nichts wird wegen 0 Punkten aussortiert.
- Rollen-Chips je nach Blickrichtung: Solo gegenüber anderen Einzelspielern schränken sie deren Rolle nicht mehr ein (Heiler wurden fälschlich aussortiert).
- Autor: Ibona93.

**0.7.3**
- Schriftarten-Auswahl zeigt jeden Eintrag jetzt wirklich in seiner eigenen Schrift (0.7.0 nutzte eine Funktion, die Blizzards Menü verbietet).

**0.7.2**
- Chips, die trotz Verknüpfung abgewählt sind, haben einen gedämpft türkisen Rand und sind durchgestrichen.

**0.7.1**
- Geöffnete Kategorie-Chips sind golden statt grau.
- Tooltips ohne Fließtext: ein Zauber pro Zeile, farbig (Name weiß, Stufe grau, Bedingung orange, Effekt hellblau). Klassen-Tooltips in Bereichen wie die Filterleiste, mit dem Chip, für den der Zauber zählt, und „Wählt mit aus: …“.
- Kurze Effekte bei Buffs und Hilfsmitteln („Ausdauer +“, „Alle Werte +10 %“, „Bedrohung −30 %“ …) in allen 11 Sprachen.

**0.7.0**
- Chips in Kategorien: Favoriten (eigene Zeile), Klassen, Buffs, Dispells, Kampf & Hilfsmittel. Kategorien klappen auf; eine geöffnete bekommt eigene Zeilen, zugeklappte zeigen die Zahl aktiver Chips.
- Favoriten per Rechtsklick (Stern), Start: Kontrolle, Unterbrechen, Kampfwiederbelebung, Angriffskraft, Mana.
- Wieder da: Gesundheitsstein, Beschwören; neue Buff-Chips Seelenstärke, Arkane Intelligenz, Mal der Wildnis, Segen der Könige, Segen der Rettung, Göttlicher Willen, Furchtzauberschutz.
- Verknüpfung: Klasse → ihre Buffs, Buff einer einzigen Klasse → Klasse; mit ausgewählte Chips türkis, per Klick trotzdem abwählbar.
- „Benötigt“ prüft die offenen Rollen: Ein Magier passt nicht auf einen Heilerplatz.
- Vorrang: Einträge, die alles Benötigte bringen, stehen oben.
- Englische Vorlagen nennen den englischen Instanznamen.
- Schriftarten-Auswahl zeigt jede Schrift in ihrer eigenen Schrift.

**0.6.0**
- Filterleiste: sichtbar sind nur noch Kontrolle, Unterbrechen, Kampfwiederbelebung, Angriffskraft und Mana. „+ mehr“ (Fluch, Magie, Gift, Krankheit) und neu „+ Klassen“ klappen auf; zugeklappt ist alles versteckt, die Zahl am Klappchip zeigt aktive Chips.
- Neue Klassen-Chips für alle 9 Klassen („diese Klasse in der Gruppe“, Gewicht 6, Standard *egal*). Der Tooltip zeigt, was die Klasse bringt. Die bisherigen Chips Priester/Magier/Druide (Buffs) und „Beschwören & Gesundheitssteine“ gehen darin auf; ihre alten Einstellungen werden nicht übernommen.
- Paladin: Segen der Könige und der Rettung; Priester: Göttlicher Willen ergänzt.
- Talente der Forever-Beta als „möglich (Talent)“: Erschütternder Schlag, Buße, Streuschuss, Einschüchterung, Aura des Volltreffers, Stille, Totem der Manaflut, Wilde Attacke. Dazu Zaubersperre und Verführung (Begleiter), Hieb (Bärform), Winterschlaf (Wildtiere/Drachkin).
- Begründung im Tooltip nennt die echte Bedingung statt „Talent oder Begleiter“.
- „Benötigt“ ist strenger: „möglich“ reicht nicht mehr.
- Grauer Rollen-Hinweis und Profilanzeige aus der Filterleiste entfernt; der Hinweis steht jetzt im Tooltip der Rollen-Chips.
- Quelle der Talentdaten: talentsforever.com (CC BY 4.0).

**0.5.0**
- Buff-Chips, die nur eine Klasse bringt, heißen wie die Klasse: Priester, Magier, Druide. Buffs mehrerer Klassen nach dem Zweck: Angriffskraft und neu **Mana** (Segen der Weisheit, Totem der Manaquelle; in Schlachtzügen bevorzugt, sonst egal).
- Alle Chip-Tooltips im Format „Klasse – Zauber ab Stufe N“, mit Bedingung (nur mit Schild, nur Untote, Teufelsjäger …). Zaubernamen aus dem Spiel.
- Priester-Chip: Furchtzauberschutz als eigener Zauber ab Stufe 20 aufgeführt.
- Erklärung „Wie entstehen die Punkte?“ neu gegliedert: Abschnitte mit Überschriften, Werte in eigener Spalte, Farben (Plus grün, Abzüge rot, Aussortiert orange), Gewichtstabelle aus den aktuellen Chip-Namen. Alle 11 Sprachen.

**0.4.0**
- Kompaktansicht entfernt; nur noch die zweizeilige Ansicht. Zeile „Ansicht“ aus der Filterleiste entfernt.
- Gruppenwert in Prozent unter dem Nutzen (nur bei Gruppen), Details im Tooltip. Bei Einzelspielern steht der Nutzen mittig. „Punkte anzeigen: aus“ blendet beides aus.
- Spielstil vertikal mittig auf Höhe der Rollen-Icons.
- Filter zusammengefasst: „Beschwören & Gesundheitssteine“ und „Ausdauer & Furchtschutz“. Alte Einstellungen werden übernommen (die stärkere gewinnt).
- Tooltip auf den Fähigkeiten-Chips: welche Klassen, ab welcher Stufe, was nur „möglich“ ist.
- Schriftgröße fest (Namen 14, Rest 12): Einstellung und `/bgf font` entfernt. Schriftart bleibt wählbar.
- Erklärung „Wie entstehen die Punkte?“ in allen 11 Sprachen angepasst.

**0.3.0**
- Logo in der Addon-Liste.
- Schrift wie Blizzard: Namen 14, Rest 12; Grundgröße 9–14 einstellbar. Bestehende Einstellungen werden einmalig auf 12 gesetzt.
- Zusätzliche Abkürzungsstufe für lange Wörter („Höhlen d. Wehkl.“).
- Filter-Button kleiner (Zahnrad frei) und eingedrückt statt umrahmt; Ansichts-Button entfernt, Ansicht wieder als Zeile in der Filterleiste.
- „BGF-Filter aktiv“ aus: BGF-Ansicht bleibt (ohne Punkte, ohne Aussortieren, Blizzards Reihenfolge). Blizzards Liste erscheint nie mehr unter der Filterleiste.
- `/bgf off` als Notausgang zu Blizzards Originalliste.
- Option „Punkte anzeigen“ und Erklärung „Wie entstehen die Punkte?“ (11 Sprachen).

**0.2.0**
- Fenster bleibt in Originalbreite; kein Greifpunkt/Skalieren mehr. Höher wird es nur mit offener Filterleiste.
- Einheitliche Schriftgröße (9–11), `/bgf font`; Spalten neu verteilt; Abkürzungen für Instanzen und Namen.
- Schriftart wählbar (Spiel, mitgeliefert, LibSharedMedia), Standard: WoW-Schrift.
- Filterleiste im Stil des Mockups: Pillen-Chips, Symbole, „+ mehr“.
- Filter-Button ohne Doppelrahmen, neuer Ansichts-Button; Zeile „Ansicht“ entfernt.
- „BGF-Filter aktiv“ abwählen lässt die Leiste offen (ausgegraut); gelber Rahmen zeigt den echten Zustand.
- +/- in den Bereichsköpfen korrigiert; Murloc-Symbol direkt hinter dem Namen; Spielstil in der Normalansicht in Zeile 1.
- Button „Anfrage“ heißt jetzt „Vorlagen“; Menü mit weißer Überschrift, Sprachen als Zwischenüberschriften, eingerückten Vorlagen; nur Spielsprache + Englisch.
- Vorlagen-Namen in den Optionen editierbar.
- Fehler behoben: LibSharedMedia wurde falsch angesprochen (vom Rauchtest gefunden).

**0.1.0** – erste Version.
