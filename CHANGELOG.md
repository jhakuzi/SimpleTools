# Changelog

## 2.2.0 — Timer / stopwatch overlays, gather buttons

- **Timer** and **Stopwatch** now have **Send to screen** overlays (countdown / elapsed, drag, persist, keep running with the window closed)
- Gather / XP / Gold / Timer / Stopwatch buttons are a centered trio: Start · Send to screen · Reset — no overlap with the gather scrollbar

## 2.1.0 — Overlays, gather, notes HUD

- XP and gold **Send to screen** overlays are unchanged in behavior: drag, persist position, keep ticking with the window closed
- **Gather** tab: nodes/hr with Start / Pause / Reset
  - Counts Herb Gathering, Mining, and Skinning casts (`UNIT_SPELLCAST_SUCCEEDED`)
  - Lists herbs, ores/stones, and leather/hides looted this session (`CHAT_MSG_LOOT`, item class + vanilla ID fallback)
  - Own **Send to screen** overlay (nodes, rate, breakdown, top items)
- **Notepad** **Send to screen**: a draggable notes HUD so the main window can close
- Overlays sit on `HIGH` strata, clamped to screen; positions save on drag stop

- XP and gold **Send to screen** overlays are unchanged in behavior: drag, persist position, keep ticking with the window closed
- **Gather** tab: nodes/hr with Start / Pause / Reset
  - Counts Herb Gathering, Mining, and Skinning casts (`UNIT_SPELLCAST_SUCCEEDED`)
  - Lists herbs, ores/stones, and leather/hides looted this session (`CHAT_MSG_LOOT`, item class + vanilla ID fallback)
  - Own **Send to screen** overlay (nodes, rate, breakdown, top items)
- **Notepad** **Send to screen**: a draggable notes HUD so the main window can close
- Overlays sit on `HIGH` strata, clamped to screen; positions save on drag stop

## 2.0.0 — Forever / Midnight

Ready for WoW Forever (Camelot, interface 16001) and Midnight 12.1 (interface 120100).

### Compatibility
- Dual TOC: `## Interface: 120100` plus `## Interface-Camelot: 16001`
- Dedicated `SimpleTools_Camelot.toc` so the Forever client picks this pack without “out of date”
- Does not branch on `WOW_PROJECT_ID` (Forever reports as Mainline)

### Fixes
- Timers, stopwatch, XP, and gold no longer break after `/reload` (stopped persisting `GetTime()`)
- Notepad no longer writes SavedVariables on every keystroke
- Gold tracking uses `PLAYER_MONEY` instead of polling
- XP events live on a hidden core frame, not the XP tab (so they fire while another tab is open)
- Reminder input validates `00:00–23:59`
- Esc closes the window (`UISpecialFrames`); window is clamped to screen
- Chat/load spam reduced to a one-time welcome

### Architecture
- `Core.lua` owns DB schema v2, migration, ticker, formatters, secret-value guards
- `C_Timer.NewTicker` replaces a permanent `OnUpdate` (idle when nothing is running)
- Settings panel via the Midnight `Settings` API (`/tools options`)
- Minimap button plus addon compartment; both persist
- Overlay frames use `BackdropTemplate`
- Money display prefers `GetCoinTextureString`

### Secret values
- `UnitXP` / `GetMoney` wrapped with `issecretvalue`; rates skip if a value is secret
- No combat APIs (`UnitHealth`, CLEU, auras). This addon stays QoL-only.

### Commands
- `/tools` or `/simpletools` or `/st` — toggle
- `/tools options` — settings
- `/tools resetpos` — recenter the window
