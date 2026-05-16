import Foundation

enum GameMode: String, CaseIterable {
    case beginner
    case expert

    var title: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .expert:
            return "Expert"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "Current friendly ramp and pacing."
        case .expert:
            return "Full random targets and numbers from the start."
        }
    }
}
