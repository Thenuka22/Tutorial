import AVKit
import SwiftUI
internal import UIKit

struct LaunchSequenceView<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var stage: LaunchStage = .artwork

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                splashArtwork(size: proxy.size)

                if stage == .video {
                    SplashVideoPlayer(shouldPlay: scenePhase == .active) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            stage = .app
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .transition(.opacity)
                    .accessibilityHidden(true)
                }

                if stage == .app {
                    content
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .transition(.opacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(splashBackdrop)
        }
        .ignoresSafeArea()
        .task {
            guard stage == .artwork else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled, stage == .artwork else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                stage = .video
            }
        }
    }

    private func splashArtwork(size: CGSize) -> some View {
        Image("SplashBackground")
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .accessibilityLabel("MiNi ARCADE")
    }

    private var splashBackdrop: Color {
        Color(red: 0.035, green: 0.18, blue: 0.05)
    }
}

private enum LaunchStage {
    case artwork
    case video
    case app
}

private struct SplashVideoPlayer: UIViewControllerRepresentable {
    let shouldPlay: Bool
    let onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = UIColor(red: 0.035, green: 0.18, blue: 0.05, alpha: 1)

        guard let url = Bundle.main.url(forResource: "SplashVideo", withExtension: "mp4") else {
            DispatchQueue.main.async {
                context.coordinator.finish()
            }
            return controller
        }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        controller.player = player
        context.coordinator.observe(item)

        if shouldPlay {
            DispatchQueue.main.async {
                player.play()
            }
        }

        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        context.coordinator.onFinished = onFinished
        if shouldPlay {
            controller.player?.play()
        } else {
            controller.player?.pause()
        }
    }

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        controller.player?.pause()
        coordinator.cancel()
    }

    final class Coordinator {
        var onFinished: () -> Void

        private var observerTokens: [NSObjectProtocol] = []
        private var didFinish = false

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func observe(_ item: AVPlayerItem) {
            cancel()
            didFinish = false
            let center = NotificationCenter.default
            observerTokens.append(
                center.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { [weak self] _ in
                    self?.finish()
                }
            )
            observerTokens.append(
                center.addObserver(
                    forName: .AVPlayerItemFailedToPlayToEndTime,
                    object: item,
                    queue: .main
                ) { [weak self] _ in
                    self?.finish()
                }
            )
        }

        func finish() {
            guard !didFinish else { return }
            didFinish = true
            onFinished()
        }

        func cancel() {
            let center = NotificationCenter.default
            observerTokens.forEach { center.removeObserver($0) }
            observerTokens.removeAll()
        }

        deinit {
            cancel()
        }
    }
}
