# EyeRelief

A macOS menu bar app that helps prevent eye strain using the **20-20-20 rule**: every 20 minutes, look at something 20 feet away for 20 seconds.

## Features

- **Customizable Intervals** - Choose between 15, 20, 30, 45-minute or 1-hour work sessions
- **Adjustable Break Duration** - 5, 10, or 20-second look-away timers
- **Full-Screen Overlay** - Gentle reminder that blocks your screen during breaks
- **Menu Bar Integration** - Live countdown timer always visible in your menu bar
- **Sound Notifications** - Choose from Chime, Bell, or Gentle alert sounds
- **Launch at Startup** - Automatically start protecting your eyes when you log in
- **Streak Tracking** - Track your daily streak and total breaks taken
- **Skip Option** - Skip a break when you're in the middle of something important
- **Modern UI** - Clean, frosted glass interface with T1 Red accent color

## Installation

### Download DMG
1. Go to the [Releases](../../releases) page
2. Download the latest `EyeRelief.dmg`
3. Open the DMG and drag EyeRelief to your Applications folder
4. **Remove quarantine** (required for first launch):
   ```bash
   xattr -cr /Applications/EyeRelief.app
   ```
5. Launch EyeRelief from Applications

> **Why is this needed?** macOS quarantines apps downloaded from the internet. Since this app isn't notarized with Apple Developer ID, you need to remove the quarantine flag. This is a one-time step.

### Build from Source
```bash
# Clone the repository
git clone https://github.com/gearupstudios/EyeRelief.git
cd EyeRelief

# Build the app
./build_app.sh

# Or build with DMG
./build_app.sh --dmg

# Build and launch
./build_app.sh --launch
```

**Requirements:**
- macOS 11.0 (Big Sur) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Usage

1. **Start the Timer** - Click "Start" to begin your work session
2. **Work** - The timer counts down in your menu bar
3. **Take a Break** - When the timer ends, a full-screen overlay reminds you to look away
4. **Look Away** - Focus on something 20 feet away for the break duration
5. **Repeat** - The timer automatically restarts after each break

### Settings

- **Interval**: How long between breaks (15/20/30/45 min or 1 hour)
- **Look Away**: How long each break lasts (5/10/20 seconds)
- **Sound**: Enable/disable and choose notification sound
- **Launch at Startup**: Auto-start with your Mac

## The 20-20-20 Rule

The 20-20-20 rule is recommended by eye care professionals to reduce digital eye strain:

> Every **20 minutes**, look at something **20 feet away** for **20 seconds**.

This simple practice helps:
- Reduce eye fatigue
- Prevent dry eyes
- Minimize headaches from screen time
- Maintain better focus throughout the day

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **AppKit** - Native macOS integration
- **UserNotifications** - System notification support
- **Combine** - Reactive state management

## Project Structure

```
EyeRelief/
├── EyeReliefApp.swift      # App entry point
├── ContentView.swift        # Main UI
├── AppDelegate.swift        # App lifecycle & notifications
├── BreakOverlayView.swift   # Full-screen break overlay
├── build_app.sh             # Build script
├── Models/
│   ├── TimerManager.swift       # Timer logic
│   ├── NotificationManager.swift # System notifications
│   ├── OverlayManager.swift     # Break overlay window
│   ├── MenuBarManager.swift     # Menu bar integration
│   ├── SettingsManager.swift    # User preferences
│   ├── StatsManager.swift       # Streak & stats tracking
│   └── LaunchAtLoginManager.swift # Startup launch
├── Resources/
│   ├── AppIcon.icns         # App icon
│   └── AppIcon.svg          # Icon source
└── Scripts/
    ├── create_icon.sh       # Icon generation
    └── generate_icon.py     # Python icon generator
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Developed by [Gear Up Studios](https://github.com/gearupstudios)**
