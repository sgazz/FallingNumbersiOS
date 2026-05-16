import Foundation

protocol AudioClient {
    func trigger(_ event: SoundEvent)
}

enum SoundEvent: Equatable {
    case move
    case lock
    case clear
    case cascade(level: Int)
    case perfectClear
    case hardDrop
    case rowClear
    case columnClear
    case reorder
    case gameOver
    case buttonTap
}

struct NoopAudioClient: AudioClient {
    func trigger(_ event: SoundEvent) {}
}
