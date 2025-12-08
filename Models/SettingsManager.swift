import Foundation
import AVFoundation
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    @Published var selectedSound: BreakSound {
        didSet { UserDefaults.standard.set(selectedSound.rawValue, forKey: "selectedSound") }
    }

    @Published var breakDuration: BreakDuration {
        didSet { UserDefaults.standard.set(breakDuration.rawValue, forKey: "breakDuration") }
    }

    @Published var exercisesEnabled: Bool {
        didSet { UserDefaults.standard.set(exercisesEnabled, forKey: "exercisesEnabled") }
    }

    private var audioPlayer: NSSound?

    // MARK: - Eye Exercises
    struct EyeExercise {
        let emoji: String
        let title: String
        let instruction: String
    }

    static let eyeExercises: [EyeExercise] = [
        EyeExercise(emoji: "👀", title: "20-20-20 Rule", instruction: "Look at something 20 feet away"),
        EyeExercise(emoji: "🔄", title: "Eye Circles", instruction: "Slowly roll your eyes in large circles"),
        EyeExercise(emoji: "👆", title: "Focus Shift", instruction: "Look at your thumb, then far away, repeat"),
        EyeExercise(emoji: "😌", title: "Palming", instruction: "Cover your eyes with palms and relax")
    ]

    func getRandomExercise() -> EyeExercise {
        return Self.eyeExercises.randomElement() ?? Self.eyeExercises[0]
    }

    enum BreakSound: String, CaseIterable {
        case chime = "chime"
        case bell = "bell"
        case gentle = "gentle"
        case none = "none"

        var displayName: String {
            switch self {
            case .chime: return "Chime"
            case .bell: return "Bell"
            case .gentle: return "Gentle"
            case .none: return "None"
            }
        }

        var systemSound: NSSound.Name? {
            switch self {
            case .chime: return NSSound.Name("Glass")
            case .bell: return NSSound.Name("Ping")
            case .gentle: return NSSound.Name("Pop")
            case .none: return nil
            }
        }
    }

    enum BreakDuration: Int, CaseIterable {
        case fiveSeconds = 5
        case tenSeconds = 10
        case twentySeconds = 20

        var displayName: String {
            switch self {
            case .fiveSeconds: return "5 sec"
            case .tenSeconds: return "10 sec"
            case .twentySeconds: return "20 sec"
            }
        }

        var seconds: Int {
            return self.rawValue
        }
    }

    init() {
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        let savedSound = UserDefaults.standard.string(forKey: "selectedSound") ?? BreakSound.chime.rawValue
        self.selectedSound = BreakSound(rawValue: savedSound) ?? .chime
        let savedDuration = UserDefaults.standard.integer(forKey: "breakDuration")
        self.breakDuration = BreakDuration(rawValue: savedDuration) ?? .fiveSeconds
        // Eye exercises disabled by default
        self.exercisesEnabled = UserDefaults.standard.object(forKey: "exercisesEnabled") as? Bool ?? false
    }

    func playBreakSound() {
        guard soundEnabled, selectedSound != .none else { return }

        if let soundName = selectedSound.systemSound {
            audioPlayer = NSSound(named: soundName)
            audioPlayer?.play()
        }
    }

    func previewSound(_ sound: BreakSound) {
        guard sound != .none, let soundName = sound.systemSound else { return }
        let previewPlayer = NSSound(named: soundName)
        previewPlayer?.play()
    }

    func playBreakEndSound() {
        guard soundEnabled else { return }
        // Play a pleasant completion sound - "Hero" indicates success/completion
        let endSound = NSSound(named: NSSound.Name("Hero"))
        endSound?.play()
    }
}
