import Foundation

struct ClearScoreBreakdown {
    let lineLength: Int
    let baseScore: Int
    let lengthMultiplier: Double
    let cascade: Int
    let cascadeMultiplier: Double
    let awardedScore: Int
}

struct ScoreSystem {
    func perfectClearBonus(level: Int, base: Int, perLevel: Int) -> Int {
        base + (max(1, level) * perLevel)
    }

    func lengthMultiplier(for lineLength: Int) -> Double {
        switch lineLength {
        case ...2:
            return 1.0
        case 3:
            return 1.25
        case 4:
            return 1.5
        case 5:
            return 2.0
        default:
            return 3.0
        }
    }

    func cascadeMultiplier(for cascade: Int) -> Double {
        switch cascade {
        case ...1:
            return 1.0
        case 2:
            return 1.25
        case 3:
            return 1.5
        case 4:
            return 2.0
        default:
            return 3.0
        }
    }

    func specialSpawnChance(for cascade: Int) -> Double {
        switch cascade {
        case ...1:
            return 0.02
        case 2:
            return 0.05
        case 3:
            return 0.08
        default:
            return 0.12
        }
    }

    func scoreBreakdownForClear(tileCount: Int, cascade: Int) -> ClearScoreBreakdown {
        let baseScore = tileCount * 10
        let lengthMultiplier = lengthMultiplier(for: tileCount)
        let cascadeMultiplier = cascadeMultiplier(for: cascade)
        let final = Int((Double(baseScore) * lengthMultiplier * cascadeMultiplier).rounded())
        return ClearScoreBreakdown(
            lineLength: tileCount,
            baseScore: baseScore,
            lengthMultiplier: lengthMultiplier,
            cascade: max(1, cascade),
            cascadeMultiplier: cascadeMultiplier,
            awardedScore: final
        )
    }

    func pointsForClear(tileCount: Int, cascade: Int) -> Int {
        scoreBreakdownForClear(tileCount: tileCount, cascade: cascade).awardedScore
    }
}
