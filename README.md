# SimpleTools

Lightweight QoL for WoW Forever.

Timer, stopwatch, reminder, XP and gold per hour, gathering, notepad, and a shopping list. Additionally you can set up a break timer and save/share your current location on the map and in a list or start and stop combat logging. Any of them can be sent to the screen.

## Install

Copy the `SimpleTools` folder to:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Then `/reload`.

## Midnight 12.1.7 testing

This testing branch includes a Midnight TOC (interface 120107) alongside the Forever/Camelot TOC. To test on Midnight, copy the `SimpleTools` folder to `World of Warcraft/_retail_/Interface/AddOns/`, enable it in the AddOns list, and `/reload`.

Please test the tabs and overlays, saved settings across reloads, map bookmarks and waypoints, combat logging, and XP/gold/gather tracking. Midnight may restrict some game values; unavailable values should be treated as unavailable rather than assumed to be zero. In-game validation is still needed before declaring full support.

The **Checklist** tab saves a separate to-do list. Add tasks, tick them off, click their text to edit, or use **x** to delete. **Reset checks** unchecks everything without deleting tasks. **Send to screen** opens a compact, scrollable checklist with the same controls. Tasks, checkmarks, and overlay placement persist across reloads.

The **Calc** tab accepts arithmetic such as `(12 + 8) * 3`, or use its keypad. Press Enter or `=` to calculate; the input clears and keeps the answer. Start the next expression with `+`, `-`, `*`, or `/` to continue from that answer, or enter a number for a fresh calculation. `C` clears both input and answer. Click a history entry to reuse it. **Send to screen** opens a small draggable calculator. History keeps the last ten calculations for the current session.


## Commands

| Command | action |
| --- | --- |
| `/tools` | Open or close |

`/simpletools` and `/st` do the same as `/tools`.

## Session history

The History tab lists completed XP, Gold, and Gather tracker sessions. Resetting a tracker saves its current session; pausing keeps it available to resume. Select a row to inspect details, use its x to delete it, or Clear history to remove all sessions. The newest 100 sessions are retained. Sessions marked partial have incomplete data because a required game value was unavailable.
