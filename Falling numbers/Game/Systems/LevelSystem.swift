import Foundation

struct LevelSystem {
    private let basicMaxFallSpeedMultiplier = 3.5
    private let expertMaxFallSpeedMultiplier = 4.25

    func levelThreshold(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        let raw = 400.0 * pow(Double(level - 1), 1.45)
        return Int(raw.rounded())
    }

    func level(forScore score: Int) -> Int {
        var level = 1
        while score >= levelThreshold(level + 1) {
            level += 1
        }
        return level
    }

    func progressToNextLevel(score: Int) -> Double {
        let currentLevel = level(forScore: score)
        let currentThreshold = levelThreshold(currentLevel)
        let nextThreshold = levelThreshold(currentLevel + 1)
        let span = max(1, nextThreshold - currentThreshold)
        return min(1.0, max(0.0, Double(score - currentThreshold) / Double(span)))
    }

    func targetRange(forCycle cycle: Int, mode: GameMode) -> ClosedRange<Int> {
        if mode == .expert {
            return 5...20
        }

        switch cycle {
        case ...2:
            return 8...12
        case 3...5:
            return 10...16
        default:
            return 12...20
        }
    }

    func targetNumber(forCycle cycle: Int, previousTarget: Int, repeatCount: Int, mode: GameMode) -> Int {
        let range = targetRange(forCycle: cycle, mode: mode)
        if mode == .expert {
            var candidate = Int.random(in: range)
            if candidate == previousTarget || abs(candidate - previousTarget) <= 1 {
                // Expert volatility: avoid tiny/no-op target shifts where possible.
                let upward = min(range.upperBound, previousTarget + 2)
                let downward = max(range.lowerBound, previousTarget - 2)
                if upward != previousTarget {
                    candidate = upward
                } else if downward != previousTarget {
                    candidate = downward
                }
            }
            return candidate
        }

        let jumpCap: Int
        switch cycle {
        case ...2:
            jumpCap = 2
        case 3...5:
            jumpCap = 3
        default:
            jumpCap = 4
        }

        // Deterministic candidate based on time cycle.
        let span = range.upperBound - range.lowerBound + 1
        var candidate = range.lowerBound + (((cycle + 1) * 7 + 3) % span)

        let delta = candidate - previousTarget
        if abs(delta) > jumpCap {
            candidate = previousTarget + (delta > 0 ? jumpCap : -jumpCap)
        }
        candidate = min(range.upperBound, max(range.lowerBound, candidate))

        if candidate == previousTarget {
            if repeatCount >= 1 {
                candidate += 1
                if candidate > range.upperBound {
                    candidate = range.lowerBound
                }
            } else if candidate < range.upperBound {
                candidate += 1
            } else {
                candidate -= 1
            }
        }

        return candidate
    }

    func fallSpeedMultiplier(forLevel level: Int, mode: GameMode) -> Double {
        let normalizedLevel = max(1, level)
        if mode == .expert {
            let raw = 1.15 + pow(Double(normalizedLevel - 1), 1.20) * 0.095
            return min(expertMaxFallSpeedMultiplier, raw)
        }
        let raw = 1.0 + pow(Double(normalizedLevel - 1), 1.15) * 0.075
        return min(basicMaxFallSpeedMultiplier, raw)
    }

    func tickInterval(base: TimeInterval, level: Int, mode: GameMode) -> TimeInterval {
        let multiplier = fallSpeedMultiplier(forLevel: level, mode: mode)
        return base / multiplier
    }

    func targetTimerDecrementMultiplier(level: Int, mode: GameMode) -> Double {
        if mode == .expert {
            return level >= 15 ? 1.22 : 1.08
        }
        return level >= 15 ? 1.08 : 1.0
    }

    func maxFallMultiplier(mode: GameMode) -> Double {
        mode == .expert ? expertMaxFallSpeedMultiplier : basicMaxFallSpeedMultiplier
    }
}
