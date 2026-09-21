# SimpleTools 2.0

Lightweight QoL for **World of Warcraft: Midnight** and **WoW Forever**.

Timer, stopwatch, daily reminder, notepad, XP/hr (with rested XP and time-to-level), and gold/hr. Overlays can be sent to the screen and keep running while the window is closed.

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

- **Timer** — countdown in minutes, sound + chat when it ends
- **Stopwatch** — independent count-up
- **Reminder** — 24-hour HH:MM alarm, fires once per day until cleared
- **XP** — gained, XP/hr, time-to-level, rested XP; optional detached overlay
- **Gold** — session gold and gold/hr; optional detached overlay
- **Notepad** — notes persist across sessions (saves on debounce, not every key)

State survives `/reload` and logout. Saved variables migrate from 1.x automatically; running timers are re-anchored because `GetTime()` resets on reload.

## Forever / Midnight notes

Forever uses Mainline’s 12.1.5-era API, including secret values. SimpleTools never reads combat data. XP and gold go through `issecretvalue` guards so a secret return cannot error the Lua VM.

See [CHANGELOG.md](CHANGELOG.md) for the 2.0 refactor.

## License

Author: Jhakuzi
