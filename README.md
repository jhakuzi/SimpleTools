# SimpleTools

Lightweight QoL for WoW Forever.

Timer, stopwatch, reminder, XP and gold per hour, gathering, notepad, and a shopping list. Additionally you can set up a break timer and save/share your current location on the map and in a list. Any of them can be sent to the screen.

## Install

Copy the `SimpleTools` folder to:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Then `/reload`.

## Combat logging

The **Logs** tab starts or stops WoW's combat logging. **Send to screen** shows a draggable status overlay with a small Start/Stop button. It stays visible with the main window closed, and hiding it does not stop logging. Reloading restores the overlay without changing logging state.

WoW manages files in its `Logs` folder. Creating separate log files, renaming, and deleting them must be done outside the addon.

**Auto logging: On/Off** starts logging when you enter a dungeon or raid (including loading into one). It is off by default and remembers your choice. Enabling it while already inside starts logging immediately. Leaving an instance or turning the option off does not stop logging; use **Stop logging** when finished.


## Commands

| Command | action |
| --- | --- |
| `/tools` | Open or close |

`/simpletools` and `/st` do the same as `/tools`.
