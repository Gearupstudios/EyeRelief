import Foundation
import Combine

class StatsManager: ObservableObject {
    static let shared = StatsManager()

    // Published stats
    @Published var currentStreak: Int = 0
    @Published var totalBreaks: Int = 0
    @Published var longestStreak: Int = 0
    @Published var todayBreaks: Int = 0

    private let defaults = UserDefaults.standard

    // Keys
    private let streakKey = "eyerelief.currentStreak"
    private let totalBreaksKey = "eyerelief.totalBreaks"
    private let longestStreakKey = "eyerelief.longestStreak"
    private let lastBreakDateKey = "eyerelief.lastBreakDate"
    private let todayBreaksKey = "eyerelief.todayBreaks"
    private let lastBreakDayKey = "eyerelief.lastBreakDay"

    init() {
        loadStats()
        checkAndUpdateStreak()
    }

    private func loadStats() {
        currentStreak = defaults.integer(forKey: streakKey)
        totalBreaks = defaults.integer(forKey: totalBreaksKey)
        longestStreak = defaults.integer(forKey: longestStreakKey)
        todayBreaks = defaults.integer(forKey: todayBreaksKey)
    }

    private func saveStats() {
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(totalBreaks, forKey: totalBreaksKey)
        defaults.set(longestStreak, forKey: longestStreakKey)
        defaults.set(todayBreaks, forKey: todayBreaksKey)
    }

    private func checkAndUpdateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastBreakDay = defaults.object(forKey: lastBreakDayKey) as? Date

        if let lastDay = lastBreakDay {
            let daysSinceLastBreak = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSinceLastBreak > 1 {
                // Streak broken - missed more than 1 day
                currentStreak = 0
                todayBreaks = 0
                saveStats()
            } else if daysSinceLastBreak == 1 {
                // New day - reset today's breaks counter
                todayBreaks = 0
                saveStats()
            }
        }
    }

    func recordBreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastBreakDay = defaults.object(forKey: lastBreakDayKey) as? Date

        // Increment total breaks
        totalBreaks += 1
        todayBreaks += 1

        // Check if this is a new day for streak
        if let lastDay = lastBreakDay {
            let daysSinceLastBreak = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSinceLastBreak >= 1 {
                // New day - increment streak
                currentStreak += 1
            }
            // Same day - streak stays the same
        } else {
            // First ever break
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Save last break day
        defaults.set(today, forKey: lastBreakDayKey)
        defaults.set(Date(), forKey: lastBreakDateKey)

        saveStats()

        print("📊 Break recorded! Streak: \(currentStreak), Total: \(totalBreaks), Today: \(todayBreaks)")
    }

    // Encouraging messages based on stats
    var encouragementMessage: String {
        if currentStreak == 0 {
            return "Start your eye care journey today!"
        } else if currentStreak == 1 {
            return "Great start! Keep it going tomorrow."
        } else if currentStreak < 7 {
            return "You're building a healthy habit!"
        } else if currentStreak < 14 {
            return "One week strong! Your eyes thank you."
        } else if currentStreak < 30 {
            return "Amazing dedication to eye health!"
        } else if currentStreak < 100 {
            return "Eye care champion! \(currentStreak) days strong!"
        } else {
            return "Legendary! \(currentStreak) days of eye protection!"
        }
    }

    // Streak level for visual indicator
    var streakLevel: StreakLevel {
        switch currentStreak {
        case 0:
            return .none
        case 1...6:
            return .bronze
        case 7...29:
            return .silver
        case 30...99:
            return .gold
        default:
            return .diamond
        }
    }

    enum StreakLevel {
        case none, bronze, silver, gold, diamond

        var title: String {
            switch self {
            case .none: return "Beginner"
            case .bronze: return "Eye Saver"
            case .silver: return "Eye Guardian"
            case .gold: return "Eye Champion"
            case .diamond: return "Eye Legend"
            }
        }
    }
}
