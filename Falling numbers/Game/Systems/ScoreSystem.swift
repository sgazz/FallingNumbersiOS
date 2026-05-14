import Foundation

struct ScoreSystem {
    func pointsForClear(tileCount: Int, combo: Int) -> Int {
        let comboMultiplier = max(1, combo)
        return tileCount * 10 * comboMultiplier
    }
}
