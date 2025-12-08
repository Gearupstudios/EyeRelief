import SwiftUI
import UserNotifications

// T1 Red color
let t1Red = Color(red: 226/255, green: 1/255, blue: 45/255)

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var menuBarManager = MenuBarManager()
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.colorScheme) var colorScheme

    init() {
        print("🚀 ContentView init called!")
    }

    var progress: Double {
        let totalDuration = timerManager.timerDurations[timerManager.selectedDurationIndex]
        return 1.0 - (timerManager.timeRemaining / totalDuration)
    }

    var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.16)
            : Color.white
    }

    var body: some View {
        ZStack {
            // Solid background
            backgroundColor
                .ignoresSafeArea()

            // Very subtle glass overlay (10% effect)
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(0.1)
                .ignoresSafeArea()

            mainContent
        }
        .frame(width: 380, height: 720)
        .onAppear {
            menuBarManager.setup(with: timerManager)
        }
    }

    var mainContent: some View {
        VStack(spacing: 0) {
            HeaderView(isActive: timerManager.isActive)
            Spacer()
            TimerCircleView(
                progress: progress,
                formattedTime: timerManager.formattedTime,
                isActive: timerManager.isActive,
                sessionBreakCount: timerManager.sessionBreakCount,
                maxSessionBreaks: TimerManager.maxSessionBreaks
            )
            Spacer()

            Group {
                IntervalSelector(timerManager: timerManager)
                BreakDurationSelector(settings: settings)
                SoundSettingsView(settings: settings)
                SmartScheduleView()
            }

            Spacer()
            ControlButtons(timerManager: timerManager)
            StatsView()
            FooterView()
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let isActive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("EyeRelief")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("20-20-20 Rule")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatusPill(isActive: isActive)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

struct StatusPill: View {
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme

    var pillBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? t1Red : Color.orange)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : "Paused")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(pillBackground)
        .cornerRadius(12)
    }
}

// MARK: - Timer Circle
struct TimerCircleView: View {
    let progress: Double
    let formattedTime: String
    let isActive: Bool
    let sessionBreakCount: Int
    let maxSessionBreaks: Int
    @Environment(\.colorScheme) var colorScheme

    var circleBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.14, green: 0.14, blue: 0.15)
            : Color.white
    }

    var trackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    var outerTrackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.04)
    }

    // Progress for outer ring (0-10 breaks)
    var sessionProgress: Double {
        return Double(sessionBreakCount) / Double(maxSessionBreaks)
    }

    // Color gradient based on progress - starts dim, becomes brighter green as it fills
    var sessionRingGradient: LinearGradient {
        let progress = sessionProgress
        if progress >= 1.0 {
            // Full - bright green
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.85, blue: 0.4),
                    Color(red: 0.3, green: 0.95, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress >= 0.7 {
            // Nearly full - green
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.3, green: 0.75, blue: 0.4),
                    Color(red: 0.4, green: 0.85, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress >= 0.4 {
            // Mid - yellow-green
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.75, blue: 0.3),
                    Color(red: 0.5, green: 0.8, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Low - dim green-gray
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.6, blue: 0.45),
                    Color(red: 0.55, green: 0.65, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            // Subtle card background with very light glass effect
            Circle()
                .fill(circleBackground)
                .frame(width: 240, height: 240)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06), radius: 20, x: 0, y: 8)

            // Outer ring - session break count track
            Circle()
                .stroke(outerTrackColor, lineWidth: 6)
                .frame(width: 210, height: 210)

            // Outer ring - session break count progress
            Circle()
                .trim(from: 0, to: CGFloat(sessionProgress))
                .stroke(sessionRingGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: sessionBreakCount)

            // Inner ring - timer track
            Circle()
                .stroke(trackColor, lineWidth: 12)
                .frame(width: 170, height: 170)

            // Inner ring - timer progress
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(progressGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 42, weight: .light, design: .monospaced))
                    .foregroundColor(isActive ? .primary : .secondary)
                Text("remaining")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                // Session break indicator
                Text("\(sessionBreakCount)/\(maxSessionBreaks) breaks")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(sessionBreakCount == maxSessionBreaks ? Color.green : .secondary.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 10)
    }

    var progressGradient: LinearGradient {
        if isActive {
            return LinearGradient(gradient: Gradient(colors: [t1Red, Color(red: 255/255, green: 100/255, blue: 100/255)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Interval Selector
struct IntervalSelector: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 8) {
            Text("INTERVAL")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(0..<timerManager.timerDurationLabels.count, id: \.self) { index in
                    DurationButton(
                        title: timerManager.timerDurationLabels[index],
                        isSelected: timerManager.selectedDurationIndex == index,
                        isDisabled: timerManager.isActive,
                        selectedColor: t1Red
                    ) {
                        timerManager.selectDuration(at: index)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Break Duration Selector
struct BreakDurationSelector: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        VStack(spacing: 8) {
            Text("LOOK AWAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(SettingsManager.BreakDuration.allCases, id: \.self) { duration in
                    BreakDurationButton(
                        title: duration.displayName,
                        isSelected: settings.breakDuration == duration
                    ) {
                        settings.breakDuration = duration
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
}

struct BreakDurationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var unselectedBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .frame(width: 54)
                .padding(.vertical, 8)
                .background(isSelected ? t1Red : unselectedBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sound Settings
struct SoundSettingsView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var launchManager = LaunchAtLoginManager.shared
    @Environment(\.colorScheme) var colorScheme

    var buttonBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: { settings.soundEnabled.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 12))
                        Text(settings.soundEnabled ? "Sound On" : "Sound Off")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(settings.soundEnabled ? t1Red : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                if settings.soundEnabled {
                    SoundPicker(settings: settings)
                }
            }

            // Launch at login toggle
            Button(action: { launchManager.launchAtLogin.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: launchManager.launchAtLogin ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                    Text("Launch at startup")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(launchManager.launchAtLogin ? t1Red : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonBackground)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // Eye exercises toggle
            Button(action: { settings.exercisesEnabled.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: settings.exercisesEnabled ? "figure.mind.and.body" : "figure.stand")
                        .font(.system(size: 12))
                    Text("Eye Exercises")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(settings.exercisesEnabled ? t1Red : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonBackground)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

struct SoundPicker: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        Picker("", selection: $settings.selectedSound) {
            ForEach(SettingsManager.BreakSound.allCases.filter { $0 != .none }, id: \.self) { sound in
                Text(sound.displayName).tag(sound)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 150)
        .onChange(of: settings.selectedSound) { newSound in
            settings.previewSound(newSound)
        }
    }
}

// MARK: - Smart Schedule Settings
struct SmartScheduleView: View {
    @ObservedObject var schedule = ScheduleManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showScheduleOptions = false

    var buttonBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Main toggle button
            Button(action: {
                if schedule.smartSchedulingEnabled {
                    showScheduleOptions.toggle()
                } else {
                    schedule.smartSchedulingEnabled = true
                    showScheduleOptions = true
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: schedule.smartSchedulingEnabled ? "calendar.badge.clock" : "calendar")
                        .font(.system(size: 12))
                    Text("Smart Schedule")
                        .font(.system(size: 11, weight: .medium))
                    if schedule.smartSchedulingEnabled {
                        Image(systemName: showScheduleOptions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8))
                    }
                }
                .foregroundColor(schedule.smartSchedulingEnabled ? t1Red : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonBackground)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded options
            if showScheduleOptions && schedule.smartSchedulingEnabled {
                VStack(spacing: 6) {
                    // Disable toggle
                    Button(action: {
                        schedule.smartSchedulingEnabled = false
                        showScheduleOptions = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 10))
                            Text("Disable")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Focus Mode toggle
                    ScheduleToggleRow(
                        icon: "moon.fill",
                        title: "Pause in Focus Mode",
                        isEnabled: $schedule.pauseDuringFocusMode
                    )

                    // Active Hours toggle with time pickers
                    VStack(spacing: 4) {
                        ScheduleToggleRow(
                            icon: "clock.fill",
                            title: "Active Hours Only",
                            isEnabled: $schedule.activeHoursEnabled
                        )

                        if schedule.activeHoursEnabled {
                            HStack(spacing: 8) {
                                HourPicker(hour: $schedule.activeHoursStart, label: "From")
                                Text("-")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 10))
                                HourPicker(hour: $schedule.activeHoursEnd, label: "To")
                            }
                            .padding(.top, 2)
                        }
                    }

                    // Calendar toggle
                    VStack(spacing: 4) {
                        ScheduleToggleRow(
                            icon: "person.2.fill",
                            title: "Pause in Meetings",
                            isEnabled: $schedule.pauseDuringMeetings
                        )

                        if schedule.pauseDuringMeetings && !schedule.calendarAccessGranted {
                            Button(action: {
                                schedule.requestCalendarAccess()
                            }) {
                                Text("Grant Calendar Access")
                                    .font(.system(size: 9))
                                    .foregroundColor(t1Red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(buttonBackground.opacity(0.5))
                .cornerRadius(8)
            }

            // Status indicator when paused by schedule
            if schedule.isPausedBySchedule {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 10))
                    Text(schedule.pauseReason)
                        .font(.system(size: 10))
                }
                .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
}

struct ScheduleToggleRow: View {
    let icon: String
    let title: String
    @Binding var isEnabled: Bool

    var body: some View {
        Button(action: { isEnabled.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(isEnabled ? t1Red : .secondary)
                    .frame(width: 14)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Spacer()
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isEnabled ? t1Red : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HourPicker: View {
    @Binding var hour: Int
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Picker("", selection: $hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(formatHour(h)).tag(h)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 70)
            .scaleEffect(0.8)
        }
    }

    func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Control Buttons
struct ControlButtons: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme

    private var buttonColor: Color {
        timerManager.isActive ? Color.orange : t1Red
    }

    var resetButtonBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleTimer) {
                HStack(spacing: 6) {
                    Image(systemName: timerManager.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(timerManager.isActive ? "Pause" : "Start")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonColor)
                        .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { timerManager.resetTimer() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(resetButtonBackground)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 28)
    }

    func toggleTimer() {
        if timerManager.isActive {
            timerManager.pauseTimer()
        } else {
            timerManager.startTimer()
        }
    }
}

// MARK: - Stats View
struct StatsView: View {
    @ObservedObject var stats = StatsManager.shared
    @Environment(\.colorScheme) var colorScheme

    var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.14, green: 0.14, blue: 0.15)
            : Color.white
    }

    var dividerColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Streak and breaks row
            HStack(spacing: 20) {
                // Streak
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("\(stats.currentStreak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(stats.currentStreak > 0 ? t1Red : .secondary)
                    Text("day streak")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Divider
                Rectangle()
                    .fill(dividerColor)
                    .frame(width: 1, height: 16)

                // Total breaks
                HStack(spacing: 4) {
                    Text("👁")
                        .font(.system(size: 14))
                    Text("\(stats.totalBreaks)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("breaks")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // Encouragement message
            Text(stats.encouragementMessage)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
}

// MARK: - Footer
struct FooterView: View {
    var body: some View {
        Text("Developed by Gear up studios")
            .font(.system(size: 10))
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.bottom, 16)
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let selectedColor: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var unselectedBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.18, blue: 0.2)
            : Color(red: 0.92, green: 0.92, blue: 0.94)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .frame(width: 54)
                .padding(.vertical, 8)
                .background(isSelected ? selectedColor : unselectedBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1)
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
