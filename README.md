# SimpleTools

Lightweight quality-of-life addon for WoW Forever (Camelot, interface 16001). Version 2.10.0.

## Install

Copy the `SimpleTools` folder into the Forever client's AddOns directory. On the beta client that is:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Then `/reload`, or enable it from the AddOns button at character select. The live Forever folder is the install Battle.net launches, still under `Interface/AddOns`.

## Tools

The window is four groups. Each group has its own tools, and any of them can be sent to the screen.

| Group | Tools |
| --- | --- |
| Time | Countdown, stopwatch, a daily reminder, and a break timer |
| Track | XP and gold per hour, gathering nodes |
| Lists | Notepad, shopping list, checklist, location bookmarks |
| Utility | Calculator, combat logging, options |

XP, gold, and gathering sessions are saved for the character who earned them. Notepad, checklist, and locations stay shared across characters until you switch them under Utility → Options. The shopping list stays shared. The first character to enter the world after updating keeps the old shared tracker session.

## Commands

| Command | Action |
| --- | --- |
| `/tools` | Open or close |
| `/tools options` | Open options |
| `/tools sound` | Toggle alert sounds |
| `/tools chat` | Toggle chat messages |
| `/tools resetpos` | Reset the window position and size |

`/simpletools` and `/st` do the same as `/tools`.

## Notes

- Checklist tasks can be edited, checked, deleted, or reset without deleting the list. The screen overlay uses the same tasks.
- The calculator accepts `(12 + 8) * 3` and never runs the expression as Lua. History is the last ten results for this session.
- Locations can be shown on the map or linked into chat as `Name — Zone (x.x, y.y)`.
- A gold session ignores a 0 copper reading during login, /reload, and loading screens. Spending down to exactly 0 copper while you are playing still counts.
- Auto logging starts only as you enter a dungeon or raid. Leaving the overlay, or the next loading screen inside that instance, does not stop or restart it.
- Shop: shift-click an item while the Shop tool is open, or search the reagent list. Shift-click a row to paste it into auction search. The Find box filters the open fallback menu immediately. A native menu uses the same filter the next time it opens.
