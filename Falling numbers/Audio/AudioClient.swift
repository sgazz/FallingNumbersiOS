import Foundation

protocol AudioClient {
    func trigger(_ event: SoundEvent)
}

enum SoundEvent {
    case move
    case lock
    case clear(combo: Int)
    case hardDrop
    case gameOver
}

struct NoopAudioClient: AudioClient {
    func trigger(_ event: SoundEvent) {}
}
