# SimpleTools

Lightweight QoL for WoW Forever.

Timer, stopwatch, reminder, XP and gold per hour, gathering, notepad, and a shopping list. Any of them can be sent to the screen.

## Install

Copy the `SimpleTools` folder to:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Then `/reload`.

## Locations and breaks

- **Locations:** Enter a name and click **Save here** to bookmark your current zone and coordinates. An empty name uses the zone name. Select a saved bookmark to **Show on map** or **Remove** it. Where supported, showing it sets the game's waypoint and navigation marker; otherwise it opens the zone map. Locations are unavailable in some instances or unmapped areas.
- **Break:** Choose an interval and snooze duration (1–240 whole minutes), then **Start**. **Pause/Resume** keeps your remaining time; changing the interval before resuming starts a fresh countdown. When due, a small reminder appears even with the main window closed. **Snooze** delays it, **Next break** starts another interval, and **Stop** (or closing the reminder) turns it off. Sound and chat follow the addon settings.

Bookmarks and break state survive `/reload`. Break countdowns measure time in the game session; they do not count time while logged out. Existing tabs keep their original positions, with Locations and Break appended.

## Combat logging

The **Logs** tab starts or stops WoW's combat logging and shows the current state. **Send to screen** creates a draggable status overlay with its own Start/Stop button, which stays visible with the main window closed. Closing the overlay does not stop logging. Status follows `/combatlog` and other addons, and reloads restore overlay visibility and position without changing the client's logging state.

WoW manages the combat log in its `Logs` folder. Addons cannot create separate log files, rename them, or delete them; manage those files outside the game.

## Development checks

Run from the addon folder with Lua 5.1:

```sh
luac5.1 -p ./*.lua tests/*.lua
lua5.1 tests/regression.lua
lua5.1 tests/new-tools.lua
lua5.1 tests/logging.lua
```

The tests use game API stubs. Check actual map navigation, UI layout at different sizes, reminders with the window closed, and saved-state restoration in WoW as well.

## Commands

| Command | Action |
| --- | --- |
| `/tools` | Open or close |
| `/tools options` | Settings |
| `/tools resetpos` | Recenter the window |

`/simpletools` and `/st` do the same as `/tools`.
