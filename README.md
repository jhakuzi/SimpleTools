
# SimpleTools

A lightweight World of Warcraft addon providing a countdown timer, a stopwatch, a daily reminder (alarm), an XP per hour tracker, and a gold per hour tracker through a clean, tabbed interface.

## Features

### Timer Tab
- **Duration Input**: Enter timer duration in minutes.
- **Countdown**: High-precision countdown from the set time.
- **Notification**: Plays a sound and prints a message when the timer finishes.

### Watch Tab
- **Stopwatch**: A count-up timer to track elapsed time.
- **Independent**: Runs independently of the countdown timer and reminders.

### Reminder Tab
- **Daily Alarm**: Set a specific time (HH:MM) to receive a notification.
- **Format**: Uses standard 24-hour format (e.g., 14:30 for 2:30 PM).
- **Persistent**: Keeps track of the set time until cleared.

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

## Usage

1. Type `/tools` or `/simpletools` in chat to show/hide the main window.
2. Use the **Tabs** at the top to switch between "Timer", "Stopwatch", "Reminder", "XP", and "Gold".

### Using the Timer
1. Select the **Timer** tab.
2. Enter the desired duration in minutes (default is 10).
3. Click **Start** to begin.

### Using the Stopwatch
1. Select the **Watch** tab.
2. Click **Start** to begin counting up.

### Using the Reminder
1. Select the **Reminder** tab.
2. Enter the time in **HH:MM** format (e.g., `17:00`).
3. Click **Set** to activate the alarm.
4. Click **Clear** to remove the set reminder.

### Using the XP Tracker
1. Select the **XP** tab.
2. Click **Start** to begin tracking your experience gains.
3. Click **Send to screen** to project the tracker text onto your screen. You can left-click and drag this overlay to position it wherever you like.
4. Use **Pause** to temporarily halt tracking. Use **Reset** to clear the current session data (if the tracker is running, it will automatically restart from zero; if paused, it will remain stopped).

### Using the Gold Tracker
1. Select the **Gold** tab.
2. Click **Start** to begin tracking gold changes.
3. Click **Send to screen** to project gold stats onto your screen.
4. Use **Pause** to temporarily halt tracking. Use **Reset** to clear the current session.

## Notes

- The window position is movable - click and drag the title bar.
- All states (timer, stopwatch, reminder, XP, and gold) are maintained when switching tabs, closing the window, or reloading the UI.
- Smooth updates (10 times per second) ensure the display remains accurate and responsive.