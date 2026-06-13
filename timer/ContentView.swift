import SwiftUI
import Combine

struct ContentView: View {
    @State private var state = TimerState()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let googleBlue = Color(red: 0.10, green: 0.36, blue: 0.86)
    private let googleRed = Color(red: 0.92, green: 0.26, blue: 0.21)
    private let googleYellow = Color(red: 0.98, green: 0.74, blue: 0.02)
    private let googleGreen = Color(red: 0.20, green: 0.66, blue: 0.32)
    private let pageBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    private let cardBackground = Color.white

    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Timer")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.13, green: 0.15, blue: 0.17))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Timer Section
                VStack(spacing: 24) {
                    timerDisplay(seconds: state.timeElapsed)
                    
                    Button(action: {
                        state = TimerReducer.reduce(currentState: state, action: .timerToggleButtonTapped)
                    }) {
                        Text(state.isTimerRunning ? "Pause Timer" : "Start Timer")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(state.isTimerRunning ? googleRed : googleBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
                
                // Counter Section
                VStack(spacing: 24) {
                    counterDisplay(count: state.clickCount)
                    
                    circleButton {
                        state = TimerReducer.reduce(currentState: state, action: .circleButtonTapped)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
            }
            .padding(24)
            .frame(maxWidth: 420)
        }
        .onReceive(timer) { _ in
            state = TimerReducer.reduce(currentState: state, action: .timerTicked)
        }
    }
    
    // MARK: - View Components
    
    private func timerDisplay(seconds: Int) -> some View {
        Text(TimerReducer.formatTime(seconds: seconds))
            .font(.system(size: 72, weight: .semibold, design: .monospaced))
            .foregroundColor(Color(red: 0.13, green: 0.15, blue: 0.17))
            .minimumScaleFactor(0.7)
    }
    
    private func counterDisplay(count: Int) -> some View {
        Text("Button clicked: \(count) times")
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(Color(red: 0.37, green: 0.40, blue: 0.44))
    }
    
    private func circleButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(cardBackground)
                
                Circle()
                    .trim(from: 0.00, to: 0.25)
                    .stroke(googleBlue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.25, to: 0.50)
                    .stroke(googleRed, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.50, to: 0.75)
                    .stroke(googleYellow, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.75, to: 1.00)
                    .stroke(googleGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(googleBlue)
            }
                .frame(width: 180, height: 180)
        }
        .buttonStyle(.plain)
        .shadow(color: googleBlue.opacity(0.16), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    ContentView()
}
