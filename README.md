# SimpleTools 2.2.1

Lightweight QoL for **World of Warcraft: Midnight** and **WoW Forever**.

Timer, stopwatch, daily reminder, notepad, XP/hr, gold/hr, and gathering nodes/hr. Overlays can be sent to the screen and keep running while the window is closed.

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
| `/tools resetpos` | Recenter the window |

Esc also closes the window. Left-click the minimap button or the addon compartment entry to toggle; right-click the minimap button for settings.

## Features

- **Timer** — countdown in minutes, sound + chat when it ends; **Send to screen** overlay
- **Stopwatch** — independent count-up; **Send to screen** overlay
- **Reminder** — 24-hour HH:MM alarm, fires once per day until cleared
- **XP** — gained, XP/hr, time-to-level, rested XP; **Send to screen** overlay
- **Gold** — session gold and gold/hr; **Send to screen** overlay
- **Gather** — nodes/hr for herbalism, mining, and skinning; session list of herbs, ores, and leather; **Send to screen** overlay
- **Notepad** — notes persist (debounced save); **Send to screen** HUD so you can close the window

Overlays are draggable, clamped, and remember position. Trackers keep ticking after you hide SimpleTools.

State survives `/reload` and logout. Saved variables migrate from 1.x automatically; running timers are re-anchored because `GetTime()` resets on reload.

## Gather tracking

- A **node** is a successful player cast of Herb Gathering, Mining, or Skinning
- The loot list only records tradegoods classified as herb, metal & stone, or leather (plus a vanilla item-ID fallback)
- No combat log. Works under Midnight / Forever secret-value rules

## Forever / Midnight notes

Forever uses Mainline’s 12.1.5-era API, including secret values. SimpleTools never reads combat data. XP and gold go through `issecretvalue` guards so a secret return cannot error the Lua VM.

See [CHANGELOG.md](CHANGELOG.md) for the 2.0 refactor and 2.1 overlay/gather work.

## License

Author: Jhakuzi
