# BGF – Development notes

Technical notes for working on BGF: offline tests, the in-game test checklist and the file layout. For features and usage see the [README](../README.md).

## Offline tests

Requirements: Lua 5.1 and [luacheck](https://github.com/lunarmodules/luacheck).

```sh
# Debian/Ubuntu
apt-get install -y lua5.1 luarocks
luarocks --lua-version=5.1 install luacheck

# from the repository root
lua5.1 tests/run.lua     # rating logic
lua5.1 tests/smoke.lua   # whole addon against a mocked WoW UI
luacheck . -q            # static checks (config in .luacheckrc)
```

All three must pass before a release.

| Test | Scope |
|---|---|
| `luacheck` | all Lua files (30 at version 0.10.1) |
| `tests/run.lua` | rating logic (about 140 checks): scenarios, required abilities, levels, role choice, instance hints, missing or locked API data, group value, chip links and overrides, open roles for "required", talents as "possible", loot competition, English instance names for templates, abbreviations, template languages and names, completeness of all locale files |
| `tests/smoke.lua` | the complete addon loaded in TOC order with a mocked WoW UI and sample listings: loading, events, list layout and abbreviations at Blizzard's window width, sorting out, zone display, filter bar, chips incl. loot and same zone, favourites, categories, links, tooltips, options pages, fonts incl. LibSharedMedia, template menu, placeholders, sending and chat-lockdown fallback, invite + message, "What's new" window, `/bgf` commands |

New WoW globals used by the addon go into `.luacheckrc`. New features get new checks.

## In-game test checklist

Offline tests can't replace the game. Before testing, enter `/console taintLog 1`; afterwards the file `Logs\taint.log` is in the client folder. Install **BugSack + BugGrabber** to collect Lua errors.

| # | Test | Expected |
|---|---|---|
| 1 | Open the Group Finder → search → dungeons | BGF list in Blizzard's style, window in original size, +/- in the section headers correct |
| 2 | Filter button | filter bar opens, window gets taller, list keeps its height, button stays pressed, cogwheel free |
| 3 | Set an ability to "required" | dot in the chip; results without this ability move down or to "Sorted out" |
| 4 | Look at the list | playstyle level with the role icons; on the right only the points without "+", green/yellow/grey; nothing overlaps |
| 5 | Hover ability chips | short tooltip with classes and hint; Shift held: "Class – spell from level …", talents marked "(talent)"; release Shift: short again |
| 6 | Expand/collapse categories, right-click chips | open category in its own rows; star and favourites row; Warrior *required* → attack power with turquoise border |
| 7 | Options → "How are points calculated?" | sections with golden headings, plus green, penalties red, sorted out orange; scrollable if too long |
| 8 | Options → change font (each entry shown in its own font) | list, filter bar and tooltip use the font |
| 9 | Hover a listing | Blizzard tooltip + BGF reasoning below, coloured verdict, for groups the group value right below |
| 10 | Select a group → Templates → a template | whisper is sent, placeholders correct; English template in Shadowfang Keep says "Shadowfang Keep" |
| 11 | As group leader: single player → Templates | invite + message |
| 12 | Untick / tick "BGF filter active" | BGF view stays, without points/sorting out; nothing hidden behind the bar. `/bgf off` → original list |
| 13 | Afterwards: enter a dungeon, fight, use action bars | no taint log entries for BetterGroupFinder (passed with 0.7.8, 10 Oct 2026) |
| 14 | `/bgf debug`, hover listings | raw data appears; check whether `spec` is filled and which `mapID` the Forever instances have |
| 15 | Options main page, at the bottom: click the Discord field, Ctrl+C, then type | link gets highlighted and can be copied; typing does not change it |

## Files

```
BetterGroupFinder.toc   Interface 16001, SavedVariables BetterGroupFinderDB
Init.lua                namespace, helpers, language lists, version
Locales/*.lua           10 languages: UI, class/role words, default templates
Data/Abilities.lua      abilities per class (level, spell IDs, certain/possible)
Data/Profiles.lua       role targets, default filters per profile, instance hints
Data/Abbreviations.lua  abbreviation rules per language
Data/Instances.lua      instance names English/German by map ID (for {instance})
Data/News.lua           pages of the "What's new" window (German and English)
Logic/Scoring.lua       rating (no game API)
Logic/Engine.lua        reads Group Finder data, perspective, spellbook check
Core.lua                settings, events, /bgf, language, templates
UI/Fonts.lua            fonts (game, bundled, LibSharedMedia)
UI/List.lua             BGF list, rows, sections, column widths, abbreviations
UI/Templates.xml        row/header templates
UI/Tooltip.lua          tooltip with reasoning
UI/FilterBar.lua        filter bar
UI/Popup.lua            own small menu (templates, fonts, context menu)
UI/Contact.lua          templates button and menu, placeholders, sending
UI/Options.lua          options and template editor
UI/WhatsNew.lua         "What's new" window
UI/Main.lua             integration into Blizzard's window, header buttons, window height
Media/Circle.tga        circle texture for chips and icons
Media/Logo.tga          logo for the addon list (64x64), source: Media/bgf_logo.svg
Media/Fonts/            bundled fonts + licenses (SIL OFL, see FONTS.txt)
tests/                  offline tests (not loaded by the game)
docs/                   this file (not part of the release ZIP)
releases/               release ZIPs and changelogs used by the release workflow
```

## Taint rules

The Group Finder is a protected Blizzard UI. To stay taint-free, BGF:
- never opens Blizzard menus (MenuUtil/dropdowns) from addon code, but uses its own `UI/Popup.lua`
- uses no `hooksecurefunc` on Blizzard functions, only events and `HookScript`
- doesn't modify Blizzard's own frames (e.g. their group tooltip)
- sets fonts only via `SetFontObject`
- doesn't use `UISpecialFrames` (Escape is handled by `Popup.CloseOnEscape`, outside of combat)
- never calls protected functions such as `C_LFGList.Search`

## Releases

Releases are uploaded to CurseForge by the GitHub Actions workflow in `.github/workflows/release.yml`, driven by `releases/notes/releases.txt` (one line per released version) and `releases/notes/<version>.md` (changelog: English, `---`, German).
