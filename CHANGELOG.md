# Changelog

## 2.5.1 — Ping wheel removed

- The Ping tab is gone. Forever already has the ping wheel in the client.

## 2.5.0 — Ping wheel

- JhakPing is now the Ping tab. Click the bind slot, press a key, right-click to clear. Quick tap and Preview sit on the same tab. `/jp` opens it. Disable the old JhakPing addon so the two don't fight over the same key.

## 2.4.2 — Compartment icon

- New anvil / pick / scroll icon in the addon compartment (64×64 TGA, drawn at 32px). The floating minimap button is gone; `/tools` or the compartment entry still opens the window.

## 2.4.1 — Compact default

- `/tools` opens at 540×240. The oversized window from the old resize jump is folded back once; drag the corner later if you want it bigger. `/tools resetpos` also restores this size.

## 2.4.0 — Combined tabs, live overlays

- Time tab: Timer, Stopwatch, and Reminder side by side. XP/Gold share one tab.
- Notepad and Shop overlays are editable in place (type notes, change item qty).
- Resize grip pins the frame before sizing so the window no longer jumps to a huge size.

## 2.3.6 — Notepad inset

- Notepad sits in the same bronze inset box as the Shop list.

## 2.3.5 — Compact window

- Default size is 540×240. Tabs shrink onto one centered row instead of wrapping Shop onto a second line. `/tools resetpos` restores this size. Existing 580×300 windows migrate once.

## 2.3.4 — Centered tabs

- Tab buttons sit as a centered group. If they wrap (narrow window, or more tabs later) each row stays centered instead of leaving a hole on the right.

## 2.3.3 — Resizable main window

- Drag the bottom-right corner to resize SimpleTools. Min 560×260, max 900×640. Size is saved. `/tools resetpos` restores the default 580×300 as well as position.
- Shop profession buttons stretch with the width. Gather / notepad / shop lists already grow with the height, so extra space goes to the list instead of empty chrome.

## 2.3.2 — Notes clear, shop overlay

- **Notepad** has a **Clear** button next to **Send to screen**.
- **Shop** can be sent to the screen. The overlay lists `23 x [Item]` rows; shift-click a row to paste into AH search even with the window closed.

## 2.3.1 — Profession reagent menus

- Shop tab: the demo ingredient chips are gone. Eight profession buttons (Alchemy, Smithing, Enchant, Engineer, Leather, Tailor, Cooking, First Aid) each open a dropdown of reagents.
- Pick a reagent, type a quantity — same `23 x [Item]` row as shift-click from bags. Forever's **Mote of Magic** is in the Enchanting list.

## 2.3.0 — Shopping list

- **Shop** tab: Shift-click an item from bags (with the Shop tab open) and enter a quantity. Rows show `23 x [Item]`.
- Shift-click a row to paste the item name into the auction house search (retail AH or classic browse). Right-click or **x** removes a row.

## 2.2.3 — Forever brown metal frames

- Main window uses Blizzard's `DefaultPanelTemplate` (the same brown metal nine-slice Forever and Midnight windows use). Falls back to the old inset frame if a client is missing it.
- Overlays tint to bronze/parchment instead of grey tooltip chrome.

## 2.2.2 — Resizable notes overlay

- The Notepad **Send to screen** overlay can be resized from the bottom-right corner. Size is saved across `/reload`.

## 2.2.1 — Overlay close on hover

- Projected overlays (Timer, Stopwatch, XP, Gold, Gather, Notes) show a small **x** only while the mouse is over them; click to hide. Trackers keep running.

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
