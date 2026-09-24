# SimpleTools 2.5.3

Lightweight QoL for **World of Warcraft: Midnight** and **WoW Forever**.

Timer, stopwatch, daily reminder, notepad, shopping list, XP/hr, gold/hr, and gathering nodes/hr. Overlays can be sent to the screen and keep running while the window is closed.

## Install

Copy the `SimpleTools` folder into:

```
World of Warcraft/_retail_/Interface/AddOns/
```

Forever shares the Mainline `_retail_` AddOns folder. Reload with `/reload`.

If the addon list marks it out of date, the Camelot TOC (`SimpleTools_Camelot.toc`, interface **16001**) is what Forever should load. Midnight uses interface **120100**.

## Commands

| Command | Action |
| --- | --- |
| `/tools` `/simpletools` `/st` | Toggle the window |
| `/tools options` | Open the Settings panel |
| `/tools resetpos` | Recenter the window and restore default size |

Esc also closes the window. Open from the addon compartment (minimap cluster dropdown) or type `/tools`.

## Features

- **Time** — Timer, Stopwatch, and Reminder side by side; timer and stopwatch **Send to screen** overlays
- **XP/Gold** — session XP (rate, TTL, rested) and gold/hr in one tab, each with its own overlay. Kill and Quest sit under the XP total. Rates refresh every 30 seconds; the elapsed clock still ticks.
- **Gather** — nodes/hr for herbalism, mining, and skinning; session list of herbs, ores, and leather; **Send to screen** overlay
- **Notepad** — notes persist (debounced save); **Clear** plus an **editable** **Send to screen** HUD
- **Shop** — shift-click bag items or pick a profession reagent; edit qty on the list or overlay; shift-click a row into auction house search

Overlays are draggable, clamped, and remember position. Trackers keep ticking after you hide SimpleTools.

The main window is resizable from the bottom-right corner. Size is saved; `/tools resetpos` restores 540×240.

State survives `/reload` and logout. Saved variables migrate from 1.x automatically; running timers are re-anchored because `GetTime()` resets on reload.

## Shop list

Open the **Shop** tab. Add items two ways:

- Shift-click from bags, loot, or chat
- Click a profession button and pick a reagent from the dropdown

A prompt asks how many. Matching items stack on the same row. Reagent lists cover Alchemy, Blacksmithing, Enchanting (including Forever's Mote of Magic), Engineering, Leatherworking, Tailoring, Cooking, and First Aid.

- Shift-click a row with the auction house open to fill the search box and run the search (works on the projected overlay too)
- Right-click a row (or the **x**) to remove it
- **Clear list** wipes the list
- **Send to screen** keeps the list visible after you close the window — qty is still editable there
- Shift-click is only intercepted while the Shop tab is visible, so AH and chat still work on other tabs

## Gather tracking

- A **node** is a successful player cast of Herb Gathering, Mining, or Skinning
- The loot list only records tradegoods classified as herb, metal & stone, or leather (plus a vanilla item-ID fallback)
- No combat log. Works under Midnight / Forever secret-value rules

## Forever / Midnight notes

Forever uses Mainline’s 12.1.5-era API, including secret values. SimpleTools never reads combat data. XP and gold go through `issecretvalue` guards so a secret return cannot error the Lua VM.

See [CHANGELOG.md](CHANGELOG.md) for the 2.0 refactor and later overlay / shop work.

## License

Author: Jhakuzi
