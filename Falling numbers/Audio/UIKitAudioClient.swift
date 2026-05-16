import Foundation
import AVFoundation

final class UIKitAudioClient: AudioClient {
    private let session = AVAudioSession.sharedInstance()
    private let queue = DispatchQueue(label: "FallingNumbers.AudioClient")

    private let movePlayer: TonePlayer
    private let lockPlayer: TonePlayer
    private let clearPlayer: TonePlayer
    private let cascadeLowPlayer: TonePlayer
    private let cascadeMidPlayer: TonePlayer
    private let cascadeHighPlayer: TonePlayer
    private let perfectClearPlayer: TonePlayer
    private let hardDropPlayer: TonePlayer
    private let rowClearPlayer: TonePlayer
    private let columnClearPlayer: TonePlayer
    private let reorderPlayer: TonePlayer
    private let gameOverPlayer: TonePlayer
    private let buttonTapPlayer: TonePlayer

    init() {
        movePlayer = TonePlayer(frequency: 430, duration: 0.035, volume: 0.09)
        lockPlayer = TonePlayer(frequency: 280, duration: 0.08, volume: 0.14)
        clearPlayer = TonePlayer(frequency: 620, duration: 0.07, volume: 0.15)
        cascadeLowPlayer = TonePlayer(frequency: 700, duration: 0.07, volume: 0.14)
        cascadeMidPlayer = TonePlayer(frequency: 780, duration: 0.07, volume: 0.15)
        cascadeHighPlayer = TonePlayer(frequency: 860, duration: 0.07, volume: 0.16)
        perfectClearPlayer = TonePlayer(frequency: 920, duration: 0.12, volume: 0.17)
        hardDropPlayer = TonePlayer(frequency: 220, duration: 0.08, volume: 0.16)
        rowClearPlayer = TonePlayer(frequency: 540, duration: 0.08, volume: 0.15)
        columnClearPlayer = TonePlayer(frequency: 500, duration: 0.08, volume: 0.15)
        reorderPlayer = TonePlayer(frequency: 460, duration: 0.1, volume: 0.14)
        gameOverPlayer = TonePlayer(frequency: 190, duration: 0.14, volume: 0.14)
        buttonTapPlayer = TonePlayer(frequency: 500, duration: 0.05, volume: 0.10)

        configureSession()
    }

    func trigger(_ event: SoundEvent) {
        queue.async { [weak self] in
            guard let self else { return }
            switch event {
            case .move:
                movePlayer.play()
            case .lock:
                lockPlayer.play()
            case .clear:
                clearPlayer.play()
            case .cascade(let level):
                if level >= 4 {
                    cascadeHighPlayer.play()
                } else if level >= 3 {
                    cascadeMidPlayer.play()
                } else {
                    cascadeLowPlayer.play()
                }
            case .perfectClear:
                perfectClearPlayer.play()
            case .hardDrop:
                hardDropPlayer.play()
            case .rowClear:
                rowClearPlayer.play()
            case .columnClear:
                columnClearPlayer.play()
            case .reorder:
                reorderPlayer.play()
            case .gameOver:
                gameOverPlayer.play()
            case .buttonTap:
                buttonTapPlayer.play()
            }
        }
    }

    private func configureSession() {
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
#if DEBUG
            print("[AUDIO] Failed to configure AVAudioSession: \(error)")
#endif
        }
    }
}

private final class TonePlayer {
    private var player: AVAudioPlayer?

    init(frequency: Double, duration: Double, volume: Float) {
        guard let data = TonePlayer.makeToneData(frequency: frequency, duration: duration) else { return }
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = volume
            player.prepareToPlay()
            self.player = player
        } catch {
#if DEBUG
            print("[AUDIO] Failed to initialize tone player: \(error)")
#endif
        }
    }

    func play() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private static func makeToneData(frequency: Double, duration: Double) -> Data? {
        let sampleRate = 44_100.0
        let frameCount = Int(sampleRate * duration)
        guard frameCount > 0 else { return nil }

        var pcm = Data(capacity: frameCount * 2)
        for i in 0..<frameCount {
            let progress = Double(i) / Double(frameCount)
            let envelope: Double
            if progress < 0.15 {
                envelope = progress / 0.15
            } else {
                envelope = max(0, 1.0 - ((progress - 0.15) / 0.85))
            }
            let sample = sin(2.0 * .pi * frequency * Double(i) / sampleRate) * envelope
            let value = Int16(max(-1, min(1, sample)) * Double(Int16.max))
            var little = value.littleEndian
            pcm.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
        }

        let byteRate = UInt32(sampleRate) * 2
        let subchunk2Size = UInt32(pcm.count)
        let chunkSize = 36 + subchunk2Size

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian, Array.init))
        wav.append("WAVE".data(using: .ascii)!)
        wav.append("fmt ".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init))
        wav.append("data".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: subchunk2Size.littleEndian, Array.init))
        wav.append(pcm)
        return wav
    }
}
