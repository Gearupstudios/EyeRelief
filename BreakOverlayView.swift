import SwiftUI

struct BreakOverlayView: View {
    @State private var countdown: Int
    @State private var timer: Timer?
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var isSkipping: Bool = false
    let totalDuration: Int
    let onBreakComplete: () -> Void

    // Current exercise (selected once when view appears)
    @State private var currentExercise: SettingsManager.EyeExercise?

    init(onBreakComplete: @escaping () -> Void) {
        let duration = SettingsManager.shared.breakDuration.seconds
        self._countdown = State(initialValue: duration)
        self.totalDuration = duration
        self.onBreakComplete = onBreakComplete
    }

    // Determine what to show based on settings
    private var exerciseEmoji: String {
        if SettingsManager.shared.exercisesEnabled, let exercise = currentExercise {
            return exercise.emoji
        }
        return "👁"
    }

    private var exerciseTitle: String {
        if SettingsManager.shared.exercisesEnabled, let exercise = currentExercise {
            return exercise.title
        }
        return "Eye Break!"
    }

    private var exerciseInstruction: String {
        if SettingsManager.shared.exercisesEnabled, let exercise = currentExercise {
            return exercise.instruction
        }
        return "Look at something 20 feet away"
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Exercise icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 140, height: 140)

                    Text(exerciseEmoji)
                        .font(.system(size: 80))
                        .scaleEffect(scale)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: scale
                        )
                }

                VStack(spacing: 8) {
                    Text(exerciseTitle)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(exerciseInstruction)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Countdown circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / CGFloat(totalDuration))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 226/255, green: 1/255, blue: 45/255), Color(red: 255/255, green: 100/255, blue: 100/255)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)

                    VStack(spacing: 2) {
                        Text("\(countdown)")
                            .font(.system(size: 48, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)

                        Text("sec")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Skip button
                Button(action: skipBreak) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                        Text("Skip this time")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 30)

                // Subtle credit
                Text("Gear up studios")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.15))
                    .padding(.bottom, 20)
            }
        }
        .opacity(opacity)
        .onAppear {
            // Select random exercise if enabled
            if SettingsManager.shared.exercisesEnabled {
                currentExercise = SettingsManager.shared.getRandomExercise()
            }

            // Play sound
            SettingsManager.shared.playBreakSound()

            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
                scale = 1.1
            }
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func skipBreak() {
        guard !isSkipping else { return }
        isSkipping = true
        timer?.invalidate()
        timer = nil
        onBreakComplete()
    }

    private func startCountdown() {
        countdown = totalDuration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                timer = nil
                // Play sound when break ends
                SettingsManager.shared.playBreakEndSound()
                onBreakComplete()
            }
        }
    }
}

struct BreakOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        BreakOverlayView(onBreakComplete: {})
    }
}
