import AVFoundation
import AudioToolbox
import Combine
import Foundation
import UIKit

enum PlayHubSound {
    case tap
    case bonus
    case mistake
    case success
    case finish
    case levelUp

    var frequency: Double {
        switch self {
        case .tap: return 640
        case .bonus: return 880
        case .mistake: return 180
        case .success: return 720
        case .finish: return 520
        case .levelUp: return 980
        }
    }

    var duration: Double {
        switch self {
        case .mistake: return 0.18
        case .finish: return 0.28
        default: return 0.12
        }
    }
}

@MainActor
final class AudioService: ObservableObject {
    static let shared = AudioService()

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []

    private init() { }

    func sync(with settings: GameSettingsStore = .shared) {
        if settings.musicEnabled, settings.musicVolume > 0 {
            startMusic(volume: settings.musicVolume)
        } else {
            stopMusic()
        }
    }

    func play(_ sound: PlayHubSound, settings: GameSettingsStore = .shared) {
        guard settings.soundEffectsEnabled, settings.soundVolume > 0 else { return }
        do {
            let data = Self.toneData(frequency: sound.frequency, duration: sound.duration)
            let player = try AVAudioPlayer(data: data)
            player.volume = Float(settings.soundVolume)
            player.prepareToPlay()
            player.play()
            effectPlayers.append(player)
            effectPlayers.removeAll { !$0.isPlaying }
        } catch {
            AudioServicesPlaySystemSound(1104)
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, settings: GameSettingsStore = .shared) {
        guard settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType, settings: GameSettingsStore = .shared) {
        guard settings.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private func startMusic(volume: Double) {
        if let musicPlayer {
            musicPlayer.volume = Float(volume)
            if !musicPlayer.isPlaying {
                musicPlayer.play()
            }
            return
        }

        do {
            let data = Self.melodyData()
            let player = try AVAudioPlayer(data: data)
            player.numberOfLoops = -1
            player.volume = Float(volume)
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        } catch {
            musicPlayer = nil
        }
    }

    private func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    private static func toneData(frequency: Double, duration: Double, amplitude: Double = 0.28) -> Data {
        samplesData(duration: duration) { sampleIndex, sampleRate, sampleCount in
            let progress = Double(sampleIndex) / Double(max(sampleCount - 1, 1))
            let fade = min(1, min(progress * 12, (1 - progress) * 12))
            return sin(2 * .pi * frequency * Double(sampleIndex) / Double(sampleRate)) * amplitude * fade
        }
    }

    private static func melodyData() -> Data {
        let notes = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 349.23]
        let noteDuration = 0.48
        return samplesData(duration: noteDuration * Double(notes.count), amplitudeScale: 0.12) { sampleIndex, sampleRate, _ in
            let seconds = Double(sampleIndex) / Double(sampleRate)
            let noteIndex = min(notes.count - 1, Int(seconds / noteDuration))
            let localProgress = (seconds.truncatingRemainder(dividingBy: noteDuration)) / noteDuration
            let fade = min(1, min(localProgress * 8, (1 - localProgress) * 8))
            return sin(2 * .pi * notes[noteIndex] * seconds) * fade
        }
    }

    private static func samplesData(
        duration: Double,
        sampleRate: Int = 44_100,
        amplitudeScale: Double = 1.0,
        sample: (Int, Int, Int) -> Double
    ) -> Data {
        let sampleCount = max(1, Int(duration * Double(sampleRate)))
        var pcm = Data(capacity: sampleCount * 2)

        for sampleIndex in 0..<sampleCount {
            let rawValue = sample(sampleIndex, sampleRate, sampleCount) * amplitudeScale
            var value = Int16(max(-1, min(1, rawValue)) * Double(Int16.max)).littleEndian
            Swift.withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
        }

        var data = Data()
        data.appendString("RIFF")
        data.appendLittleEndian(UInt32(36 + pcm.count))
        data.appendString("WAVE")
        data.appendString("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(sampleRate * 2))
        data.appendLittleEndian(UInt16(2))
        data.appendLittleEndian(UInt16(16))
        data.appendString("data")
        data.appendLittleEndian(UInt32(pcm.count))
        data.append(pcm)
        return data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
