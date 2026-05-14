import Foundation

struct LevelSystem {
    func level(forClearedTiles totalClearedTiles: Int) -> Int {
        1 + (totalClearedTiles / 24)
    }

    func targetNumber(level: Int) -> Int {
        // Deterministic 5...20 cycle to keep target variety stable and testable.
        5 + ((level * 7) % 16)
    }

    func tickInterval(base: TimeInterval, level: Int) -> TimeInterval {
        let reduced = base * pow(0.92, Double(max(0, level - 1)))
        return max(0.26, reduced)
    }
}
