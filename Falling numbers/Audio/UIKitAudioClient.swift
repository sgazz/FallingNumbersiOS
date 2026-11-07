import Foundation
import AVFoundation

// Mutable playback state is confined to the serial queue; callers only enqueue work.
nonisolated final class UIKitAudioClient: AudioClient, @unchecked Sendable {
    private let queue = DispatchQueue(label: "FallingNumbers.AudioClient")
    // Accessed only on queue, including construction and playback.
    private var playback: AudioPlayback?
    private var isInterrupted = false
    private var servicesAvailable = true
    private var observers: [NSObjectProtocol] = []

    init() {
        observeAudioLifecycle()
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    private func observeAudioLifecycle() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                            object: nil, queue: nil) { [weak self] notification in
            guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
            self?.queue.async { [weak self] in
                guard let self else { return }
                switch AVAudioSession.InterruptionType(rawValue: rawType) {
                case .began: self.isInterrupted = true
                case .ended: self.isInterrupted = false
                default: break
                }
                self.playback?.handleInterruption(type: rawType)
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereLostNotification,
                                            object: nil, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in
                self?.servicesAvailable = false
                self?.playback?.suspend()
                self?.playback = nil
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                            object: nil, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in
                self?.servicesAvailable = true
                self?.playback = nil
            }
        })
    }

    func trigger(_ event: SoundEvent) {
        trigger(event) { _ in }
    }

    // Report actual player submission so integration tests can verify the whole audio path.
    func trigger(_ event: SoundEvent, completion: @escaping @Sendable (Bool) -> Void) {
        queue.async { [weak self] in
            guard let self, self.servicesAvailable, !self.isInterrupted else {
                completion(false)
                return
            }
            if self.playback == nil { self.playback = AudioPlayback() }
            completion(self.playback?.trigger(event) ?? false)
        }
    }

    func stop() {
        queue.async { [weak self] in self?.playback?.stopEffects() }
    }
}

// Audio work must not inherit the project's default MainActor isolation.
nonisolated private final class AudioPlayback {
    private let session = AVAudioSession.sharedInstance()
    private var isSessionActive = false
    private var isInterrupted = false

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
        // Configure before prepareToPlay, which can also activate the session.
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            isSessionActive = true
        } catch {
            NSLog("[AUDIO] Failed to configure AVAudioSession: %@", String(describing: error))
        }

        movePlayer = TonePlayer(frequency: 430, duration: 0.07, volume: 0.28)
        lockPlayer = TonePlayer(frequency: 280, duration: 0.12, volume: 0.40)
        clearPlayer = TonePlayer(frequency: 620, duration: 0.12, volume: 0.42)
        cascadeLowPlayer = TonePlayer(frequency: 700, duration: 0.12, volume: 0.40)
        cascadeMidPlayer = TonePlayer(frequency: 780, duration: 0.12, volume: 0.42)
        cascadeHighPlayer = TonePlayer(frequency: 860, duration: 0.12, volume: 0.44)
        perfectClearPlayer = TonePlayer(frequency: 920, duration: 0.20, volume: 0.48)
        hardDropPlayer = TonePlayer(frequency: 220, duration: 0.12, volume: 0.44)
        rowClearPlayer = TonePlayer(frequency: 540, duration: 0.14, volume: 0.42)
        columnClearPlayer = TonePlayer(frequency: 500, duration: 0.14, volume: 0.42)
        reorderPlayer = TonePlayer(frequency: 460, duration: 0.16, volume: 0.40)
        gameOverPlayer = TonePlayer(frequency: 190, duration: 0.22, volume: 0.40)
        buttonTapPlayer = TonePlayer(frequency: 500, duration: 0.09, volume: 0.32)
    }

    private var players: [TonePlayer] {
        [movePlayer, lockPlayer, clearPlayer, cascadeLowPlayer, cascadeMidPlayer,
         cascadeHighPlayer, perfectClearPlayer, hardDropPlayer, rowClearPlayer,
         columnClearPlayer, reorderPlayer, gameOverPlayer, buttonTapPlayer]
    }

    func suspend() {
        isInterrupted = true
        isSessionActive = false
        stopEffects()
    }

    func stopEffects() {
        for player in players { player.stop() }
    }

    func handleInterruption(type: UInt) {
        switch AVAudioSession.InterruptionType(rawValue: type) {
        case .began:
            suspend()
        case .ended:
            isInterrupted = false
            // One-shot effects are never replayed after a call or Siri interruption.
            // Reactivate only for a subsequent gameplay event.
        default:
            break
        }
    }

    private func activateIfNeeded() -> Bool {
        guard !isInterrupted else { return false }
        if isSessionActive { return true }
        do {
            // Retry configuration too: an earlier interruption or activation failure may have left it unset.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            isSessionActive = true
            return true
        } catch {
            NSLog("[AUDIO] Failed to reactivate AVAudioSession: %@", String(describing: error))
            return false
        }
    }

    func trigger(_ event: SoundEvent) -> Bool {
        guard activateIfNeeded() else { return false }
        switch event {
        case .move:
            return movePlayer.play()
        case .lock:
            return lockPlayer.play()
        case .clear:
            return clearPlayer.play()
        case .cascade(let level):
            if level >= 4 {
                return cascadeHighPlayer.play()
            } else if level >= 3 {
                return cascadeMidPlayer.play()
            } else {
                return cascadeLowPlayer.play()
            }
        case .perfectClear:
            return perfectClearPlayer.play()
        case .hardDrop:
            return hardDropPlayer.play()
        case .rowClear:
            return rowClearPlayer.play()
        case .columnClear:
            return columnClearPlayer.play()
        case .reorder:
            return reorderPlayer.play()
        case .gameOver:
            return gameOverPlayer.play()
        case .buttonTap:
            return buttonTapPlayer.play()
        }
    }
}

// Internal so integration tests can exercise the real AVAudioPlayer path, not just event doubles.
nonisolated final class TonePlayer {
    private var player: AVAudioPlayer?
    private let data: Data?
    private let volume: Float

    init(frequency: Double, duration: Double, volume: Float) {
        self.data = Self.makeToneData(frequency: frequency, duration: duration)
        self.volume = volume
        preparePlayer()
    }

    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }

    private func preparePlayer() {
        guard let data else { return }
        do {
            let candidate = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
            candidate.volume = volume
            guard candidate.prepareToPlay() else {
                NSLog("[AUDIO] Failed to prepare tone player")
                return
            }
            player = candidate
        } catch {
            NSLog("[AUDIO] Failed to initialize tone player: %@", String(describing: error))
        }
    }

    @discardableResult
    func play() -> Bool {
        if player == nil { preparePlayer() }
        guard let player else { return false }
        player.currentTime = 0
        guard player.play() else {
            NSLog("[AUDIO] Tone playback failed; rebuilding player for the next effect")
            self.player = nil
            return false
        }
        return true
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    static func makeToneData(frequency: Double, duration: Double) -> Data? {
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
