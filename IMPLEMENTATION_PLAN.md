# EyeRelief v1.9 - Premium Features Implementation Plan

## Overview
Three premium features to justify $5 price point:
1. Multi-Monitor Full-Screen Blocking
2. Guided Eye Exercises (with disable toggle)
3. Smart Scheduling & Focus Mode Integration

---

## Feature 1: Multi-Monitor Full-Screen Blocking

### Current Behavior
- `OverlayManager.swift` creates a single `NSWindow` on the main screen
- Only blocks one monitor, users can look at other screens

### Implementation Plan

**Files to modify:** `Models/OverlayManager.swift`

**Changes:**
1. Get all screens using `NSScreen.screens`
2. Create an overlay window for EACH screen
3. Store windows in an array `[NSWindow]`
4. Position each window on its respective screen using `screen.frame`
5. Close all windows when break completes
6. Main countdown shows on primary screen, secondary screens show simpler overlay

**Key Code:**
```swift
private var overlayWindows: [NSWindow] = []

func showBreakOverlay(completion: @escaping () -> Void) {
    for screen in NSScreen.screens {
        let window = createOverlayWindow(for: screen, isPrimary: screen == NSScreen.main)
        overlayWindows.append(window)
    }
}
```

---

## Feature 2: Guided Eye Exercises

### Design
- Random exercise shown during break (instead of just "look away")
- 3 simple exercises with emoji icons
- Toggle in settings to enable/disable (disabled by default per user request)

### Exercises
1. **👀 20-20-20 Rule** - "Look at something 20 feet away"
2. **🔄 Eye Circles** - "Slowly roll your eyes in circles"
3. **👆 Focus Shift** - "Look at your finger, then far away"
4. **😌 Palming** - "Cover eyes with palms, relax"

**Files to modify:**
- `Models/SettingsManager.swift` - Add `exercisesEnabled` toggle
- `BreakOverlayView.swift` - Show random exercise
- `ContentView.swift` - Add toggle in settings UI

**Key Code:**
```swift
struct EyeExercise {
    let emoji: String
    let title: String
    let instruction: String
}

let exercises = [
    EyeExercise(emoji: "👀", title: "20-20-20", instruction: "Look at something 20 feet away"),
    EyeExercise(emoji: "🔄", title: "Eye Circles", instruction: "Slowly roll your eyes in circles"),
    // ...
]
```

---

## Feature 3: Smart Scheduling & Focus Mode Integration

### Features
1. **Focus Mode Detection** - Pause when macOS Do Not Disturb is active
2. **Active Hours** - Only run during specified hours (e.g., 9 AM - 6 PM)
3. **Calendar Integration** - Pause during calendar events (optional)

### Implementation Plan

**Files to create:**
- `Models/ScheduleManager.swift` - Handles all scheduling logic

**Files to modify:**
- `Models/SettingsManager.swift` - Add schedule settings
- `Models/TimerManager.swift` - Check schedule before running
- `ContentView.swift` - Add schedule settings UI

### Part A: Focus Mode Detection
```swift
// Check Do Not Disturb status
func isFocusModeActive() -> Bool {
    // Use DistributedNotificationCenter to detect DND
    // Or check NSWorkspace for presentation mode
}
```

### Part B: Active Hours
```swift
struct ActiveHours {
    var enabled: Bool
    var startHour: Int  // 0-23
    var endHour: Int    // 0-23
    var activeDays: Set<Int>  // 1=Sun, 2=Mon, etc.
}

func isWithinActiveHours() -> Bool {
    let now = Date()
    let hour = Calendar.current.component(.hour, from: now)
    return hour >= startHour && hour < endHour
}
```

### Part C: Calendar Integration
```swift
// Request calendar access
// Check for events in current time
// Pause if event is happening
```

**Settings UI:**
- Toggle: "Smart Scheduling"
- Active Hours: Start/End time pickers
- Toggle: "Pause during Focus Mode"
- Toggle: "Pause during Calendar Events"

---

## Implementation Order

1. **Multi-Monitor** (30 min)
   - Modify OverlayManager
   - Test with multiple displays

2. **Eye Exercises** (20 min)
   - Add exercises data
   - Modify BreakOverlayView
   - Add settings toggle (disabled by default)

3. **Smart Scheduling** (45 min)
   - Create ScheduleManager
   - Add Focus Mode detection
   - Add Active Hours
   - Add Calendar integration
   - Update UI

4. **Testing & Polish** (15 min)
   - Test all features
   - Build DMG

---

## Version
- Current: 1.8
- Target: 1.9
