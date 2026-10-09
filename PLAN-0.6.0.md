# BGF 0.6.0 – vereinbarter Plan (Felix hat "go" für den automatischen Start nach dem Limit-Reset gegeben)

Basis: BetterGroupFinder 0.5.0 (/home/claude/BetterGroupFinder, ZIP /home/claude/BetterGroupFinder-0.5.0.zip)

1. Filterleiste Fähigkeiten:
   - Immer sichtbar: Kontrolle, Unterbrechen, Kampfwiederbelebung, Angriffskraft, Mana + Klappchips "+ Klassen" und "+ mehr".
   - Hinter "+ mehr": Fluch entfernen, Magie bannen, Gift heilen, Krankheit heilen.
   - Hinter "+ Klassen" (eigene Zeile, wenn aufgeklappt; "- Klassen"): alle 9 Klassen (Krieger, Paladin, Jäger, Schurke, Priester, Schamane, Magier, Hexenmeister, Druide).
   - Variante B für beide Klappchips: zugeklappt = komplett versteckt, auch wenn aktiv; Zahl am Klappchip zeigt aktive Chips, z. B. "+ Klassen (1)". Zustand wird gespeichert.
2. Klassen-Chips = "diese Klasse in der Gruppe". Gewicht 6 (bevorzugt 6, benötigt 9; Raid: Klasse zählt einmal). Default überall "egal". Keine Farben. Kein "lieber nicht".
   - Tooltip: was die Klasse bringt, nach Bereichen gruppiert, mit Stufe, Bedingungen, "(Talent)".
   - Bisherige Chips buff_stamina/buff_int/buff_wild/summon entfallen (gehen in Klassen-Chips auf). Alte Einstellungen werden NICHT übernommen.
   - Paladin: Segen der Könige (20), Segen der Rettung (26) im Tooltip; Macht/Weisheit bleiben zusätzlich in Angriffskraft/Mana.
   - Priester: Seelenstärke (1), Furchtzauberschutz (20), Göttlicher Willen (30).
   - Hexenmeister: Gesundheitsstein (10), Ritual der Beschwörung (20).
3. Talente der Beta (Build 1.60.1.70291) als "möglich", Tooltip "(Talent)", Stufe = 10 + 5*(Reihe-1):
   - Kontrolle: Krieger Erschütternder Schlag 30 (12809), Paladin Buße 30 (20066, nur Humanoide), Jäger Streuschuss 30 (19503), Jäger Einschüchterung 30 (19577, Begleiter).
   - Unterbrechen: Priester Stille 30 (15487), Druide Wilde Attacke 20 (16979, Bärform).
   - Mana: Schamane Totem der Manaflut 25 (16190).
   - Angriffskraft: Jäger Aura des Volltreffers 25 (19506, nur Fernkampf).
   Eigener Charakter: Zauberbuch -> sicher.
4. Baseline ergänzen: Hexenmeister Zaubersperre 36 (19244, Teufelsjäger) -> Unterbrechen möglich; Verführung (Sukkubus) -> Kontrolle möglich; Druide Winterschlaf (2637, nur Wildtiere/Drachkin) -> Kontrolle; Druide Hieb (Bärform) -> Unterbrechen (Lernstufe prüfen). Jäger: kein Stich des Flügeldrachen.
5. Begründung im Tooltip nennt echte Bedingung statt "(Talent oder Begleiter)".
6. "Benötigt" strenger: "möglich" erfüllt es nicht (halber Abzug bleibt, ohne freien Platz aussortiert).
7. Rollen-Chips: grauer Hinweis "automatisch, Klick ändert" weg aus der Leiste, stattdessen Tooltip der Rollen-Chips (Automatisch/Manuell gewählt, Klick ändert, "Filter zurücksetzen" in den Optionen).
8. Profilanzeige in der Filterleiste entfällt.
9. Punkte-Erklärung (11 Sprachen), README (Quelle talentsforever.com, CC BY 4.0 nennen; Hinweis Talente können sich bis Release 4.11. ändern), Tests anpassen. Version 0.6.0, ZIP bauen, prüfen, senden. Danach wieder warten.

10. Nach 0.6.0: GitHub-Releases v0.1.0 bis v0.6.0 anlegen (ZIPs aus releases/ anhängen, kurze Änderungsliste aus README-Changelog). Danach releases/-Ordner wieder aus dem Repo entfernen.
