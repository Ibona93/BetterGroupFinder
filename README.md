# Better Group Finder (BGF) 0.5.0 – WoW Forever

Erweiterung für den Gruppenfinder von WoW Forever:
- intelligente Filter
- Bewertung der Gruppenzusammensetzung
- Nachrichtenvorlagen mit automatischem Versand
- übersichtliche zweizeilige Liste mit Punkten und Gruppenwert

Ziel-Version: WoW Forever **1.60.1, Interface 16001** (Beta-Stand 9. Oktober 2026).

---

## 1. Installation

1. Das Spiel schließen (oder später `/reload` eingeben).
2. Das ZIP entpacken. Heraus kommt der Ordner `BetterGroupFinder`.
3. Den Ordner in den AddOns-Ordner des Forever-Clients kopieren. In der Beta ist das:
   `World of Warcraft\_classic_beta_\Interface\AddOns\BetterGroupFinder`
   Nach dem Release heißt der Client-Ordner voraussichtlich anders. Entscheidend ist der Ordner, aus dem du Forever startest.
4. Der Ordner muss direkt `BetterGroupFinder.toc` enthalten. Ein Ordner `BetterGroupFinder\BetterGroupFinder\…` funktioniert nicht.
5. Im Charakterauswahl-Bildschirm unter **AddOns** „Better Group Finder“ aktivieren.
6. Empfohlen für die ersten Tests: **BugSack + BugGrabber** installieren, damit eventuelle Lua-Fehler gesammelt werden.

Falls das Spiel das Addon als „veraltet“ markiert, hat sich nach einem Patch die Interface-Nummer geändert. Prüfen mit `/dump (select(4, GetBuildInfo()))` und die Zahl in der ersten Zeile der `.toc` anpassen.

---

## 2. Funktionen im Überblick

| Bereich | Was BGF macht |
|---|---|
| Ergebnisliste | Eigene Liste im Gruppenfinder-Fenster in Blizzards Optik. Bereiche: **Gruppen**, **Spieler**, **Aussortiert** (eingeklappt, mit Begründung). Sortiert nach BGF-Punkten. |
| Fenstergröße | Das Fenster behält **Blizzards Originalbreite und -höhe**. Es wird nur höher, solange die Filterleiste offen ist (außerhalb des Kampfes). |
| Einträge | Zweizeilig: Name (+ Stufe, „Neue Spieler willkommen“) oben, Instanz darunter. Spielstil und Rollen-Icons mittig in der Zeile, jedes Rollen-Icon mit Ring in Klassenfarbe. Bei Schlachtzügen erscheinen Rollenzahlen statt Einzel-Icons. |
| Punkte und Gruppenwert | Rechts der Nutzen („+30“). Bei Gruppen steht darunter in Grau der **Gruppenwert** („72 %“): wie vollständig die Gruppe schon ist. Bei Einzelspielern steht nur der Nutzen, mittig. Beides abschaltbar in den Optionen; dort erklärt „Wie entstehen die Punkte?“ die Berechnung. |
| Schrift | Feste Größen wie bei Blizzard: Namen 14, alles andere 12. Schriftart wählbar (Standard: die WoW-Schrift). |
| Abkürzungen | Passt ein Text nicht, kürzt BGF zuerst sinnvoll: „Höhlen d. Wehklagens“, „Ruinen v. Lordaeron“, „Aldarin S.“. Erst dann wird mit „…“ abgeschnitten. Der Tooltip zeigt immer die vollen Namen. |
| Filterleiste | Filter-Button neben „Aktualisieren“ (bleibt eingedrückt, solange die Leiste offen ist). Abgerundete Chips, Punkt = benötigt, Halbkreis = bevorzugt, Häkchen = gewählte Rolle. Sieben übliche Fähigkeiten sind sichtbar (plus alle, die nicht auf „egal“ stehen), der Rest hinter „+ mehr“. |
| Filter aus | Haken „BGF-Filter aktiv“ entfernen: die BGF-Ansicht bleibt, aber ohne Punkte, ohne Aussortieren, in Blizzards Reihenfolge. Die Leiste bleibt offen (Filter ausgegraut). |
| Notausgang | `/bgf off` zeigt Blizzards Originalliste (ohne Filterleiste und Filter-Button), `/bgf on` holt BGF zurück. |
| Logo | Erscheint in der Addon-Liste. |
| Bewertung | Automatisch aus deiner Sicht: solo „passe ich rein?“, in einer Gruppe „passt der zu uns?“. Zwei Gruppen werden auf einen Zusammenschluss geprüft. |
| Tooltip | Blizzards Tooltip (Mitglieder, Voicechat, Aktivität) plus darunter die BGF-Begründung: grün = Vorteil, rot = Abzug, grau = Lücke, orange = Ausschlussgrund. |
| Vorlagen-Button | Im Footer zwischen „Nachricht senden“ und „Gruppeneinladung“. Öffnet das Vorlagen-Menü; ein Klick auf eine Vorlage **sendet sofort**. |
| Rechtsklick auf Eintrag | Blizzards eigenes Kontextmenü (Nachricht, Einladen, Melden). |
| Sprachen | Oberfläche in allen 11 Clientsprachen. Vorlagen: deine Spielsprache plus Englisch. |

---

## 3. Bedienung

### Filterleiste
- **BGF-Filter aktiv:** schaltet Bewertung, Sortierung und Aussortieren ein oder aus. Die BGF-Ansicht und die Leiste bleiben.
- **Bewertung für:** deine Perspektive, z. B. „Jäger 22 · DPS“ oder „Deine Gruppe (3)“. Bei wenig Platz entfällt das Wort „Bewertung für:“.
- **Profil:** folgt der Kategorie (Dungeons, Schlachtzüge, sonstige). Jedes Profil hat eigene Fähigkeiten-Einstellungen.
- **Freier Platz für / Gesucht:** automatisch gesetzt (solo deine Rollen aus dem Gruppenfinder, in einer Gruppe die fehlenden Rollen). Ein Klick wechselt auf manuelle Auswahl; „Filter zurücksetzen“ in den Optionen stellt wieder auf automatisch.
- **Fähigkeiten:** ein Klick wechselt zwischen *egal* (grau), *bevorzugt* (weiß, Halbkreis) und *benötigt* (gold, Punkt). „+ mehr“ / „- weniger“ blendet die seltener genutzten ein und aus. Der Tooltip eines Chips zeigt Klasse, Zauber und Lernstufe, bei Bedingungen mit Hinweis (z. B. „Krieger – Schildhieb ab Stufe 12 (nur mit Schild)“). Die Zaubernamen kommen aus dem Spiel, also in deiner Clientsprache.
- **Buffs:** Bringt nur eine Klasse den Buff, heißt der Chip wie die Klasse (**Priester**, **Magier**, **Druide**); der Tooltip listet deren Buffs („Machtwort: Seelenstärke ab Stufe 1“, „Furchtzauberschutz ab Stufe 20“). Buffs mehrerer Klassen heißen nach dem Zweck: **Angriffskraft** (Krieger, Paladin, Schamane) und **Mana** (Segen der Weisheit ab 14, Totem der Manaquelle ab 26).

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

### Optionen (`/bgf` oder Optionen → AddOns → Better Group Finder)
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
| `{instance}` | die Aktivität (Name aus dem Spiel, also in deiner Clientsprache) |
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
- Quests & Zonen / Benutzerdefiniert: keine Rollenziele.

Spieler mit mehreren angebotenen Rollen bekommen zuerst einen freien Tank- oder Heilerplatz (knappe Rollen), dann DPS.

**Punkte:**

| Faktor | Punkte |
|---|---|
| Füllt fehlenden Tank / Heiler | +40 |
| Füllt fehlenden DPS-Platz | +20 |
| Bringt fehlende Fähigkeit | + Gewicht (×1,5 bei „benötigt“, ×1,5 bei Instanz-Hinweis) |
| Fähigkeit nur „möglich“ (Talent/Begleiter/Schild/Kreaturtyp) | + halbes Gewicht |
| Gruppe wäre vollständig | +10 |
| Zusammenschluss möglich | +5 |
| Weitere gleiche Klasse ohne neuen Nutzen | −10 (Schlachtzug −5) |
| Kein neuer Nutzen | −5 (Schlachtzug −2) |
| Stufe außerhalb der Empfehlung | −8 |
| Überzählige Rolle im Schlachtzug | −8 |
| „Benötigt“ fehlt noch, aber es sind Plätze frei | − halbes Gewicht |

**Gewichte der Fähigkeiten:**

| Fähigkeit | Gewicht |
|---|---|
| Kontrolle | 10 |
| Unterbrechen | 8 |
| Beschwören & Gesundheitssteine (Hexenmeister: ab 10 „möglich“, ab 20 voll) | 7 (keine Versammlungssteine in Forever) |
| Fluch entfernen, Magie bannen, Kampfwiederbelebung | 6 |
| Gift heilen, Krankheit heilen | 5 |
| Priester (Machtwort: Seelenstärke, Furchtzauberschutz) | 4 |
| Druide (Mal der Wildnis) | 3 |
| Magier (Arkane Intelligenz), Angriffskraft, Mana | 2 |

**Aussortiert** (in den Bereich „Aussortiert“, nie unsichtbar) werden:
- zu viele Spieler zusammen
- kein Platz für die Rolle (mit Angabe, welche Rolle noch gesucht wird)
- Rolle nicht gesucht (manuelle Rollen-Auswahl)
- eine *benötigte* Fähigkeit fehlt, und es ist kein Platz mehr frei
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
- Andere Spieler: Klasse + Stufe. Talentabhängiges gilt als „möglich“.
- Eine vorhandene Fähigkeit wird nicht noch einmal als fehlend oder als Vorteil gezählt.

**Instanz-Hinweise** (`Data/Profiles.lua`): Für bekannte Instanzen werden bestimmte Fähigkeiten höher gewichtet und auch dann berücksichtigt, wenn sie auf „egal“ stehen. Beispiele sind Gift und Magie in den Höhlen des Wehklagens oder Krankheit und Fluch in Stratholme. Neue Forever-Instanzen kannst du dort ergänzen. Die `mapID` liefert `/bgf debug`.

**Unbekannte Daten:**
- Fehlen Klasse oder Rolle, wird das als „? …“ gekennzeichnet und nicht geraten.
- Sind die Mitgliederdaten gesperrt (Chat-Sperre im Kampf in Instanzen), zeigt BGF das als Hinweis an und bewertet erst danach wieder.

---

## 5. Bekannte Einschränkungen

- **Nicht im Spiel getestet.** BGF wurde gegen Blizzards veröffentlichten Forever-UI-Code (1.60.1) und die offizielle API-Dokumentation gebaut, aber ohne Client. Siehe Abschnitt 6.
- **Sprache des Gegenübers** liefert die API nicht. Darum wählst du im Menü zwischen deiner Sprache und Englisch.
- **Spezialisierung und Talente** fremder Spieler sind nicht verfügbar. Talentabhängige Fähigkeiten zählen deshalb nur als „möglich“.
- **Fähigkeitentabelle** (`Data/Abilities.lua`): Lernstufen und Spell-IDs stammen aus WoW Classic.
  - Zaubernamen im Tooltip liefert das Spiel (`C_Spell.GetSpellName`). Kennt Forever eine ID nicht, zeigt BGF den Namen aus der Tabelle: auf Deutsch, in allen anderen Sprachen auf Englisch.
  - Verifiziert für Forever ist nur: kein Kampfrausch/Heldentum, Furchtschutz für alle Priester ab 20. Weil nur Priester Seelenstärke und Furchtzauberschutz bringen, sind beide im Chip „Priester“ zusammengefasst (ebenso Beschwören und Gesundheitssteine beim Hexenmeister).
  - Nach Klassenpatches muss die Tabelle eventuell angepasst werden.
- **Instanz-Hinweise** nutzen Klassik-`mapID`s. Ob Forever dieselben verwendet, zeigt `/bgf debug`.
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
| `tests/run.lua` | Bewertungslogik, Szenarien 1–7 und 12, Pflicht-Fähigkeiten, Stufen, Rollenwahl, Instanz-Hinweise, fehlende/gesperrte API, Gruppenwert, zusammengefasste Fähigkeiten und Umstellung alter Einstellungen, Mana-Buffs, Zauber je Klasse vollständig, Abkürzungen, Vorlagensprachen und -namen; Vollständigkeit aller 11 Sprachdateien | 83/83 bestanden |
| `tests/smoke.lua` | komplettes Addon in TOC-Reihenfolge mit nachgebildeter WoW-Oberfläche: Laden, Events, Liste mit Daten wie in den Beta-Screenshots, Spaltenbreiten und Abkürzungen bei Originalbreite (Schrift 12/14), Aussortieren, Filterleiste (Fenster nur höher, nicht breiter), Chips, „+ mehr“, Haken aus/an (BGF-Ansicht bleibt, keine Punkte, nichts aussortiert), Gruppenwert nur bei Gruppen, Chip-Tooltips (Klasse – Zauber ab Stufe, Bedingungen, Klassen-Chips ohne Präfix, Zaubernamen aus dem Spiel), Klassennamen für Buff-Chips, Erklärungsfenster mit Abschnitten, Option „Punkte anzeigen“, Erklärungsfenster, `/bgf off` ohne Leiste und Button, Schriftarten inkl. LibSharedMedia, Vorlagen-Menü (Überschrift, nur zwei Sprachen, eigene Namen), Platzhalter, automatisches Senden, Fallback bei Chat-Sperre, Einladen + Nachricht, Tooltip, `/bgf`-Befehle | alle bestanden |

Die Tests lassen sich mit Lua 5.1 erneut ausführen: `lua tests/run.lua` und `lua tests/smoke.lua` aus dem Addon-Ordner.

### Nur konzeptionell geprüft, bitte im Spiel testen

Vorher `/console taintLog 1` eingeben. Nach dem Test liegt die Datei `Logs\taint.log` im Client-Ordner.

| # | Test | Erwartung |
|---|---|---|
| 1 | Gruppenfinder öffnen → Suche → Dungeons | BGF-Liste in Blizzard-Optik, Fenster in Originalgröße, +/- in den Bereichsköpfen korrekt |
| 2 | Filter-Button | Filterleiste klappt auf, Fenster wird länger, Liste gleich hoch, Button bleibt eingedrückt, Zahnrad frei |
| 3 | Fähigkeit auf „benötigt“ stellen | Punkt im Chip; Treffer ohne diese Fähigkeit rutschen nach unten bzw. zu „Aussortiert“ |
| 4 | Liste ansehen | Spielstil auf Höhe der Rollen-Icons; Gruppen: Nutzen + grauer Gruppenwert; Einzelspieler: Nutzen mittig; nichts überlappt |
| 5 | Über Fähigkeiten-Chips fahren | Tooltip „Klasse – Zauber ab Stufe …“ mit Zaubernamen in deiner Sprache; bei Priester/Magier/Druide ohne Klassenname |
| 5b | Optionen → „Wie entstehen die Punkte?“ | Abschnitte mit goldenen Überschriften, Plus grün, Abzüge rot, Aussortiert orange; scrollbar, falls zu lang |
| 6 | Optionen → Schriftart wechseln | Liste, Filterleiste und Tooltip übernehmen die Schrift |
| 7 | Eintrag hovern | Blizzard-Tooltip + BGF-Begründung darunter |
| 8 | Gruppe wählen → Vorlagen → Freundlich | Flüsternachricht wird gesendet, Platzhalter korrekt |
| 9 | Als Gruppenleiter Einzelspieler → Vorlagen | Einladung + Nachricht |
| 10 | Haken „BGF-Filter aktiv“ aus/an | BGF-Ansicht bleibt, ohne Punkte/Aussortieren; nichts verschwindet hinter der Leiste. `/bgf off` → Originalliste |
| 11 | Nach dem Test: Dungeon betreten, kämpfen, Aktionsleisten benutzen | keine „Aktion blockiert“-Meldungen. `taint.log` nach `BetterGroupFinder` durchsuchen und mir schicken, falls Einträge auftauchen |
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
Logic/Scoring.lua       Bewertung (ohne Spiel-API)
Logic/Engine.lua        Liest Gruppenfinder-Daten, Perspektive, Zauberbuchprüfung
Core.lua                Einstellungen, Events, /bgf, Sprache, Vorlagen
UI/Fonts.lua            Schriftarten (Spiel, mitgeliefert, LibSharedMedia)
UI/List.lua             BGF-Liste, Zeilen, Bereiche, Spaltenbreiten, Abkürzen
UI/Templates.xml        Zeilen-/Kopf-Vorlagen
UI/Tooltip.lua          Tooltip mit Begründung
UI/FilterBar.lua        Filterleiste
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
