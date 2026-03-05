# SimpleTools

A lightweight World of Warcraft addon providing various tools to improve your gameplay experience.

## Features

### Timer Tab
- **Duration Input**: Enter timer duration in minutes.
- **Countdown**: High-precision countdown from the set time.
- **Notification**: Plays a sound and prints a message when the timer finishes.

### Stopwatch Tab
- **Stopwatch**: A count-up timer to track elapsed time.
- **Independent**: Runs independently of the countdown timer and reminders.

### Reminder Tab
- **Daily Alarm**: Set a specific time (HH:MM) to receive a notification.
- **Format**: Uses standard 24-hour format (e.g., 14:30 for 2:30 PM).
- **Persistent**: Keeps track of the set time until cleared.

### Notepad Tab
- **Notes**: Write and save notes directly in the addon.
- **Persistent**: Notes are saved and persist across game sessions.

### XP Tab
- **Projected UI**: Click "Send to screen" to detach a borderless, draggable overlay of the tracker directly onto your game screen.
- **XP/hr Calculation**: Tracks experience gained over time to calculate an active XP per hour rate.
- **Time to Level (TTL)**: Estimates the time remaining to reach the next level based on your current XP/hr.
- **Session Tracking**: Displays total XP gained and elapsed time for the current tracking session.
- **Controls**: Start, pause, and reset tracking independently of other timers.

### Gold Tab
- **Gold/hr Calculation**: Tracks gold changes over time to calculate gold earned per hour.
- **Projected UI**: Click "Send to screen" to project gold stats as a draggable overlay.
- **Session Tracking**: Displays total gold gained (formatted as Xg Ys Zc) and elapsed time.
- **Controls**: Start, pause, and reset tracking independently of other features.

### Common Features
- **Start/Pause/Resume**: Full control over all timing functions.
- **Reset**: Quickly reset counters to zero.
- **Chat Command**: Use `/tools` or `/simpletools` to toggle the window.
- **Movable Window**: Drag the window anywhere on your screen.
- **Persistent Operation**: All features continue running even when the window is hidden or you switch tabs.
- **State Persistence**: Timers, stopwatches, reminders, and XP tracking survive UI reloads (`/reload`) and relogging.

## Installation

1. Copy the `SimpleTools` folder into your World of Warcraft addons directory:
   - Retail: `World of Warcraft/_retail_/Interface/AddOns/`

2. Reload your UI with `/reload` or restart the game.