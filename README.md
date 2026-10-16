# BGF - Better Group Finder Forever

🇩🇪 [Deutsche Version](README.de.md)

An addon for the Group Finder of **WoW Forever**:
- smart filters for classes, buffs, dispels, crowd control and more
- a rating of how well each listing fits you or your group, with the reason in the tooltip
- message templates that whisper or invite with one click
- a clear two-line list with coloured points

Author: **Ibona93** · License: MIT (see [`LICENSE`](LICENSE); bundled fonts: SIL OFL 1.1)
Game version: WoW Forever **1.60.1, Interface 16001**

**Download:** [CurseForge](https://www.curseforge.com/projects/1736838) · **Feedback:** [Discord](https://discord.gg/4nPNJMYetV) · [GitHub Issues](https://github.com/Ibona93/BetterGroupFinder/issues)

---

## 1. Installation

**Recommended:** install BGF with the CurseForge app. It also keeps the addon up to date.

**Manual:**
1. Close the game (or type `/reload` afterwards).
2. Unzip the file. You get a folder named `BetterGroupFinder`.
3. Copy this folder into the `Interface\AddOns` folder of your WoW Forever client, i.e. inside the client folder you start Forever from.
4. The folder must contain `BetterGroupFinder.toc` directly. `BetterGroupFinder\BetterGroupFinder\…` does not work.
5. On the character selection screen, open **AddOns** and enable "BGF - Better Group Finder Forever".

If the game marks the addon as "out of date", the interface number changed with a patch. Check it with `/dump (select(4, GetBuildInfo()))` and update the number in the first line of the `.toc` file, or wait for the next BGF update.

---

## 2. Features

| Area | What BGF does |
|---|---|
| Result list | Its own list inside the Group Finder window, styled like Blizzard's. Sections: **Groups**, **Players**, **Sorted out** (collapsed, with the reason). Sorted by BGF points. |
| Window size | The window keeps **Blizzard's original width and height**. It only grows taller while the filter bar is open (outside of combat). |
| Listings | Two lines: name (+ level, "New players welcome") on top, instance below. Playstyle and role icons in the middle, each role icon with a ring in class colour (can be turned off under Options › Display). Raids show role counts instead of single icons. |
| Points | On the right, the value a listing brings ("30"), coloured like the M+ rating in Retail: green = good fit (40+), yellow = fits (15–39), grey = little value; neutral white for quests & zones. The **group value** ("72 %", how complete the group already is) is in the tooltip right below the verdict. Can be turned off in the options; "How are points calculated?" explains the rating there. |
| Font | Fixed sizes like Blizzard's: names 14, everything else 12. Font face selectable (default: the WoW font). |
| Your own listing | Shows your group members (class colour, role), the missing role as a faded icon and, in line 2, "Your listings · activity". No points. |
| Abbreviations | If a text does not fit, BGF first shortens it sensibly (German example: "Höhlen d. Wehklagens"). Only then is it cut off with "…". The tooltip always shows the full names. |
| Filter bar | Filter button next to "Refresh" (stays pressed while the bar is open). Rounded chips: dot = required, half circle = preferred, tick = selected role, star = favourite, turquoise border = selected along with another chip. A **Favourites** row, below it the categories **Classes**, **Buffs**, **Dispels** and **Combat & utility** to expand. Collapsed categories sit side by side (grey) with a counter for active chips ("+ Buffs (2)"); an open one gets its own rows and a golden category chip. |
| Filter off | Untick "BGF filter active": the BGF view stays, but without points, without sorting out, in Blizzard's order. The bar stays open (filters greyed out). |
| Emergency exit | `/bgf off` shows Blizzard's original list (without filter bar and filter button), `/bgf on` brings BGF back. |
| Rating | Automatically from your point of view: solo "do I fit in?", in a group "does this player fit us?". Two groups are checked for a merge. |
| Tooltip | Blizzard's tooltip (members, voice chat, activity) plus the BGF reasoning below it: green = advantage, red = penalty, grey = gap, orange = reason for sorting out. |
| Templates button | In the footer between "Send message" and "Group invite". Opens the template menu; clicking a template **sends it right away**. |
| Right-click on a listing | Own context menu: send message, invite (if possible), templates…, plus "Report…" as a note: Blizzard does not allow addons to report (`C_ReportSystem.SendReport`), so reporting works in Blizzard's list after `/bgf off`. |
| What's new | After an update, a short "What's new in BGF" window appears once at login. Can be switched off; the options main page shows the same content. |
| Languages | Interface in all WoW client languages (10 translations). Templates: your game language plus English. |

---

## 3. Usage

### Filter bar
- **Save · Reset** (right side of the first row): "Save" stores the chips of the Group Finder category currently shown as your own default. "Reset" sets the chips of this category back to your default (without a saved default: to the built-in one) and the roles to automatic; favourites and other categories stay. "Reset filters" in the options resets all categories, "Restore defaults" deletes your own defaults.
- **BGF filter active:** turns rating, sorting and sorting out on or off. The BGF view and the bar stay.
- **Rating for:** your perspective, e.g. "Hunter 22 · DPS" or "Your group (3)".
- **Profile:** not shown, but follows the category at the top of the window (dungeons, raids, other). Each category has its own chip settings.
- **Open slot for / Looking for:** set automatically (solo: your roles from the Group Finder; in a group: the missing roles). A click switches to manual selection; "Reset filters" in the options switches back to automatic. Solo, the chips apply to you: for groups as the role you join with; for other single players (you would start a group together) they don't restrict the other player.
- **Chips:** left-click cycles between *ignored* (grey), *preferred* (white, half circle) and *required* (gold, dot). **Right-click** makes a chip a favourite (star) or removes it; favourites also appear in the favourites row, it is the same chip. Starting favourites: crowd control, interrupt, battle res, attack power, mana. A chip's tooltip is short: which classes bring the ability, below it "maybe:" for classes that only have it with a talent, pet, form or similar, and the hint "Hold Shift: details". With Shift held (live) it shows class, spell and level learned, with conditions where they apply (e.g. "Warrior – Shield Bash from level 12 (shield only)", "Priest – Silence from level 30 (talent)"). Spell names come from the game, so they are in your client language.
- **Loot competition** ("Loot" chip, starting favourite): *preferred* = minus points per competitor (−8, "maybe" −4), *required* = groups with a competitor are sorted out ("maybe" only lowers the points). A competitor is someone with the same class, or the same armour type (below/from level 40: Hunter/Shaman leather/mail, Warrior/Paladin mail/plate) with the same main stat (from class and role; Shaman as DPS only "maybe"). Rings, necklaces, cloaks and weapons don't count. By default BGF only checks for you; **Shift-click** on the chip opens a menu with you and your group members to tick (e.g. only for a friend). The chip shows who it applies to: "Loot (me)", "Loot (Thoradin)", "Loot (2)", "Loot (nobody)".
- **Zones:** every listing shows the current zone next to the activity (for groups the leader's, the game only reports that one; also in the tooltip), green = your zone, grey = elsewhere. **"Same zone"** chip (ignored by default, directly in the abilities row): *preferred* +6 for players in your zone, *required* = only players in your zone (unknown zones are never sorted out).
- **Shown chips** (Options › Filter & Chips): hide the favourites row, the abilities row, single categories or chips. Hidden counts as *ignored*, also for links and instance hints; without the abilities row only the favourites remain usable.
- **Categories:** *Classes* (9 chips, "this class in the group", *ignored* by default), *Buffs* (attack power, mana, Fortitude, Arcane Intellect, Mark of the Wild, Blessing of Kings, Salvation, Divine Spirit, Fear Ward), *Dispels* (curse, magic, poison, disease), *Combat & utility* (crowd control, interrupt, battle res, healthstone, summon). A class chip's tooltip shows one line per category; with Shift, the full view of everything the class brings to the group.
- **Links:** a class chip selects its class's buffs in the same state (Warrior *required* → attack power *required*; Warlock → healthstone and summon). A chip only one class brings selects that class (Fortitude → Priest). No chain reactions. Chips selected this way have a turquoise border; clicking them turns them off anyway ("deselected despite …", muted turquoise border, struck through) until the triggering chip is off again. Linked chips give points and penalties but never sort anything out on their own.
- **Priority:** listings that meet all chips you set to *required* yourself always come first in groups and players; the rest follow with the note "Lower priority".

### Templates button
| Selection | What happens | Menu heading |
|---|---|---|
| Group, you are solo | Join request to the group leader | "Join request to …" |
| Group, you are in a group | Request as a group (merge) | "Request as group to …" |
| Single player, you may invite | Invite **and** invite message | "Invite + message to …" |

Menu layout: white heading (what happens), below it the languages in gold (your game language, then English), below that the indented templates. Hover a template to see the finished text. If the chat is locked (combat in instances) or sending fails, the text is ready in the chat box; just press Enter.

### Commands
| Command | Effect |
|---|---|
| `/bgf` | Open the options |
| `/bgf off` / `/bgf on` | Emergency exit: Blizzard's original list / BGF back on |
| `/bgf debug` | Debug output on/off. Hovering a listing prints its raw data (incl. `mapID`, specialisation) to the chat. |

### Options (`/bgf` or Options › AddOns › BGF - Better Group Finder Forever)
- **Main page:** version, short description, "Show what's new after updates", the news of the current version (the version badge opens earlier releases), commands, and at the very bottom the Discord link to copy (click the field, Ctrl+C).
- **Display:** **Show points** (with the button "How are points calculated?"), BGF rating in the tooltip, **class colour ring around the role icons** (off = no ring, like Blizzard's), font.
- **Filter & Chips:** BGF filter active, shown rows/categories/chips, "Show all", "Reset filters", "Restore defaults".
- **Message templates:** send immediately, templates per language (your own language is preselected and highlighted), "Reset templates of this language".
- **Font** with preview:
  - included in the game: Friz Quadrata (default), Arial Narrow, Morpheus, Skurri
  - bundled: Philosopher, PT Sans Narrow, Roboto Condensed, Noto Sans
  - plus all fonts from **LibSharedMedia** if another addon (e.g. Details, WeakAuras, ElvUI) brings them. In return, BGF offers its fonts to other addons there.
  - Korean and Chinese clients always use the game font.
- **Templates** per language (game language and English): each template has a **name** (shown in the menu) and a **text**. Empty field = default.

Placeholders in templates:

| Placeholder | Replaced with |
|---|---|
| `{name}` | recipient |
| `{me}` | your name |
| `{class}` | your class (in the template's language) |
| `{role}` | your role |
| `{level}` | your level |
| `{instance}` | the activity; in the English text with the English name (own name table by map ID, e.g. "Shadowfang Keep" instead of "Burg Shadowfang") |
| `{group}` | your group, e.g. "Warrior (Tank), Priest (Healer)" |

All settings are saved account-wide in `WTF\Account\<Account>\SavedVariables\BetterGroupFinder.lua`.

---

## 4. Filter and rating logic

The logic lives in `Logic/Scoring.lua` and is plain Lua without game API (tested offline).

**Who is host, who is guest?** The bigger side is the host; on a tie, yours.
- Solo vs. group: the group takes you in.
- Your group vs. single player: you take them in.
- Group vs. group: merge.

**Role targets:**
- Dungeon (5 players): 1 tank / 1 healer / 3 DPS, **strict**. Surplus roles are sorted out.
- Raid:
  - 10: 2 / 3 / 5
  - 20: 3 / 5 / 12
  - 40: 4 / 10 / 26
  - Other sizes are scaled proportionally. Surplus roles only give a penalty.
- Quests & zones / custom: no role targets, no role check (role chips greyed out), no penalties for same class or missing value, nothing sorted out for 0 points.

Players offering several roles get a free tank or healer slot first (scarce roles), then DPS.

**Points:**

| Factor | Points |
|---|---|
| Fills a missing tank / healer | +40 |
| Fills a missing DPS slot | +20 |
| Brings a missing ability | + weight (×1.5 when "required", ×1.5 with an instance hint) |
| Ability only "possible" (talent/pet/shield/creature type) | + half weight; the tooltip names the real condition, e.g. "maybe brings interrupt (talent)" |
| Group would be complete | +10 |
| Merge possible | +5 |
| Another player of the same class without new value | −10 (raid −5) |
| No new value | −5 (raid −2) |
| Level outside the recommended range (other players below it) | −8 |
| Surplus role in a raid | −8 |
| "Required" still missing or only "possible", but slots are free | − half weight |

**Ability weights:**

| Ability | Weight |
|---|---|
| Crowd control | 10 |
| Interrupt | 8 |
| Summon | 7 |
| Remove curse, dispel magic, battle res, each class (class chips) | 6 |
| Cure poison, cure disease | 5 |
| Fortitude, Fear Ward | 4 |
| Mark of the Wild, Blessing of Kings, healthstone | 3 |
| Attack power, mana, Arcane Intellect, Salvation, Divine Spirit | 2 |

In a raid a class only counts once: with a Druid already in, a second one brings nothing more for the Druid chip.

**Sorted out** (moved to the "Sorted out" section, never hidden) are:
- too many players combined
- no slot for the role (naming which role is still wanted)
- role not wanted (manual role selection)
- an ability or class you set to *required* yourself is missing (or only "possible") and can't be added anymore: no free slot, or no class that brings it can play one of the open roles ("Required: Mage doesn't fit any free slot")
- level below the activity's minimum level
- doesn't match the activity filter, no longer listed
- **0 points or less** ("No real benefit")

**Group value** (groups only, only with role targets, so not for quests & zones):
- 60 % roles: filled slots relative to the target, tank and healer slots count double.
- 40 % abilities: all abilities not set to "ignored" (plus instance hints), weighted as above; "possible" counts half.
- The tooltip shows the details: "Group value 72 %: roles 3/5, abilities 2/3".

If all results are sorted out, a note appears at the top: "All X results were sorted out – loosen the filters?".

**Abilities:**
- Your own character: BGF checks your spellbook, as long as the Classic spell IDs are recognised in Forever. Otherwise BGF falls back to class + level, see `/bgf debug` → "spellbook check".
- Other players: class + level. Talents, pets, shield or creature type make an ability only "possible".
- Talents come from the talent trees of the Forever beta (build 1.60.1.70291): at the earliest from level 10 + 5 × (row − 1). If you learned the talent yourself, it counts as certain for you.
- Included talents: Concussion Blow (Warrior), Repentance (Paladin), Scatter Shot, Intimidation and Trueshot Aura (Hunter), Silence (Priest), Mana Tide Totem (Shaman), Feral Charge (Druid).
- An ability already present is not counted again as missing or as an advantage.

**Instance hints** (`Data/Profiles.lua`): for known instances certain abilities get a higher weight and count even when set to "ignored". Examples: poison and magic in Wailing Caverns, disease and curse in Stratholme. For fear-heavy instances (Blackrock Depths, Molten Core, Onyxia's Lair, Blackwing Lair) Fear Ward is taken into account.

**Unknown data:**
- If class or role is missing, it is marked as "? …" and not guessed.
- If member data is locked (chat lockdown in instance combat), BGF shows a note and rates again afterwards.

---

## 5. Known limitations

- **Raids** were not available in the beta; the raid logic is only tested offline.
- **The other player's language** is not provided by the API. That's why the menu lets you choose between your language and English.
- **Specialisation and talents** of other players are not available: in the beta the `specName` field only contains the class name. Talent-based abilities therefore only count as "possible".
- **Talent data** comes from [talentsforever.com](https://talentsforever.com/) (data from the beta client, build 1.60.1.70291, license CC BY 4.0), checked against individual Wowhead Forever spell pages. Talents may still change until launch (4 November 2026). The level for Bash (Druid) is taken from Classic and not confirmed for Forever.
- **Ability table** (`Data/Abilities.lua`): levels and spell IDs come from WoW Classic.
  - Spell names in the tooltip come from the game (`C_Spell.GetSpellName`). If Forever doesn't know an ID, BGF shows the name from the table: in German on German clients, in English everywhere else.
  - Confirmed for Forever: no Bloodlust/Heroism, Fear Ward for all priests from 20, Blessing of Kings (20) and Salvation (26, formerly "Blessing of Salvation", renamed on 16 Oct 2026, same spell ID) as well as Divine Spirit (30) without talent, no Wyvern Sting.
- **Map IDs:** Forever uses the Classic IDs (checked: Shadowfang Keep 33, Deadmines 36, Wailing Caverns 43); Ruins of Lordaeron is 2999. Instance hints and the name table rely on them.
- **Own menus:** the template menu, the font list and the right-click menu are BGF's own simple windows (`UI/Popup.lua`), not Blizzard's menu system. With `/console taintLog 1`, the beta client crashed when an addon button opened a Blizzard menu. Escape closes BGF windows via its own key handling (outside of combat), not via Blizzard's `UISpecialFrames`.
- **No category preselected:** Blizzard starts without a category; BGF then shows the hint "Choose a category at the top left". BGF can't preselect one: the search is protected and would be blocked by an addon value.
- **No hooks on Blizzard functions:** BGF follows the Group Finder through its events (results received, search failed, listing changed) and only hooks window scripts (show, hide, refresh button).
- **Languages other than German/English** are machine-assisted translations. Corrections from native speakers are very welcome.
- **Window height:** with the filter bar open, BGF changes the height of Blizzard's window, only outside of combat, to avoid taint.
- **The search** itself is never started by BGF. It stays protected and runs through Blizzard's refresh button.
- **Inviting** only works for single players, like in Blizzard's UI. Groups are reached through a request to the leader.

---

## 6. Feedback and contributing

- **Discord:** [discord.gg/4nPNJMYetV](https://discord.gg/4nPNJMYetV) (forums for bugs and suggestions, plus a German channel)
- **GitHub Issues:** [github.com/Ibona93/BetterGroupFinder/issues](https://github.com/Ibona93/BetterGroupFinder/issues)
- **CurseForge:** comments on the project page

For Lua errors, please include a screenshot or the text from BugSack. Tests, file layout and the in-game test checklist are in [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

---

## 7. Changelog

**0.10.2**
- Discord: the invite link (discord.gg/4nPNJMYetV) can be copied from the bottom of the options main page; mentioned on the "What's new" page 0.10.2 and on the welcome page.
- Blizzard renamed "Blessing of Salvation" to "Salvation" (beta build of 16 Oct 2026, same spell ID 1038). Chip name updated in all 10 languages.

**0.10.1**
- New option "Class colour ring around the role icons" (Options › Display, on by default). Turn it off for plain role icons in the list, like Blizzard's; the icons then fill the whole slot. Names keep their class colour.

**0.10.0**
- Every listing now shows the current zone next to the activity (for groups the leader's zone). Green = your zone.
- New "Same zone" chip: plus points for players in your zone (preferred) or only players in your zone (required). Off by default.

**0.9.0**
- New "Loot" chip (avoid loot competition): minus points or sorted out for players with the same class, or the same armour type and main stat (from class, role and level; armour changes at level 40). Shift-click the chip to choose who to check for: you and/or your group members.
- Options split into pages: Display, Filter & Chips, Message templates. The main page shows what's new.
- Filter & Chips: hide the favourites row, the abilities row, whole categories or single chips. Hidden chips count as ignored.
- New "What's new" window at login after an update (click the version to see earlier releases). Can be switched off in the window or in the options.
- No more level penalty for your own level or for higher-level players.

**0.8.2**
- Chip tooltips are now short: abilities show which classes bring them, classes show one line per category. Hold Shift for full details (spells, levels, conditions).
- Points are coloured (green 40+, yellow 15–39, grey below) and shown without "+". The group value moved into the group tooltip.
- New "Save" button in the filter bar: store your own default filters per category. "Reset" now goes back to them. Options: "Restore defaults".

**0.8.1**
- Renamed to "BGF - Better Group Finder Forever" (addon list and options). Chat messages and the filter button tooltip now say "BGF". Folder, settings and `/bgf` stay the same.

**0.8.0** – first public release on CurseForge
- Group Finder list sorted by how well a listing fits you or your group, filter chips, explained scores in the tooltip, message templates with invite + whisper in one click.

**0.1.0 – 0.7.9** – development versions before the public release. The detailed history is in the [German README](README.de.md#7-änderungen).
