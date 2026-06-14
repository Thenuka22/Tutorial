import SwiftUI
import Combine

struct TapFrenzyView: View {
    @State private var remaining: Int = 10
    @State private var score: Int = 0
    @State private var isRunning: Bool = false

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Time: \(remaining)s")
                Spacer()
                Text("Score: \(score)")
            }
            .font(.headline)
            .monospacedDigit()

            Button(action: { if isRunning { score += 1 } }) {
                Text("TAP!")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isRunning)

            HStack(spacing: 12) {
                Button(isRunning ? "Restart" : "Start") {
                    start()
                }
                .buttonStyle(.borderedProminent)

                Button("Stop") {
                    stop()
                }
                .buttonStyle(.bordered)
                .disabled(!isRunning)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if remaining > 0 {
                remaining -= 1
            }
            if remaining == 0 {
                stop()
            }
        }
        .navigationTitle("Tap Frenzy")
    }

    private func start() {
        remaining = 10
        score = 0
        isRunning = true
    }

    private func stop() {
        isRunning = false
    }
}

#Preview {
    NavigationStack { TapFrenzyView() }
}
