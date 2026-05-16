import Foundation

struct ClearScoreBreakdown {
    let lineLength: Int
    let baseScore: Int
    let lengthMultiplier: Double
    let cascade: Int
    let cascadeMultiplier: Double
    let expertMultiplier: Double
    let awardedScore: Int
}

struct ScoreSystem {
    private let horizontalBonusMultiplier = 1.1

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
        case 4...5:
            return 0.12
        default:
            // Balance guard: very deep cascades should not keep inflating future special spawns.
            return 0.10
        }
    }

    func occupancyAdjustedSpecialSpawnChance(
        baseChance: Double,
        occupancyPercent: Int,
        mode: GameMode
    ) -> Double {
        if mode == .expert {
            let adjusted: Double
            switch occupancyPercent {
            case ..<25:
                adjusted = baseChance * 0.35
            case 25...55:
                adjusted = baseChance * 0.65
            case 56...69:
                adjusted = baseChance * 0.9
            case 70...100:
                adjusted = baseChance * 1.15
            default:
                adjusted = baseChance * 0.65
            }
            return max(0.0, min(0.16, adjusted))
        }

        let adjusted: Double
        switch occupancyPercent {
        case ..<20:
            adjusted = baseChance * 0.45
        case 20...40:
            adjusted = baseChance
        case 46...100:
            adjusted = baseChance * 1.35
        default:
            adjusted = baseChance
        }
        return max(0.0, min(0.22, adjusted))
    }

    func scoreBreakdownForClear(
        tileCount: Int,
        cascade: Int,
        isHorizontal: Bool = false,
        expertMode: Bool = false
    ) -> ClearScoreBreakdown {
        let baseScore = tileCount * 10
        let lengthMultiplier = lengthMultiplier(for: tileCount)
        let cascadeMultiplier = cascadeMultiplier(for: cascade)
        let directionalMultiplier = isHorizontal ? horizontalBonusMultiplier : 1.0
        let expertMultiplier = expertMode ? 1.2 : 1.0
        let final = Int((Double(baseScore) * lengthMultiplier * cascadeMultiplier * directionalMultiplier * expertMultiplier).rounded())
        return ClearScoreBreakdown(
            lineLength: tileCount,
            baseScore: baseScore,
            lengthMultiplier: lengthMultiplier,
            cascade: max(1, cascade),
            cascadeMultiplier: cascadeMultiplier,
            expertMultiplier: expertMultiplier,
            awardedScore: final
        )
    }

    func pointsForClear(tileCount: Int, cascade: Int, isHorizontal: Bool = false, expertMode: Bool = false) -> Int {
        scoreBreakdownForClear(tileCount: tileCount, cascade: cascade, isHorizontal: isHorizontal, expertMode: expertMode).awardedScore
    }
}
