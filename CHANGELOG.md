# Changelog

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
