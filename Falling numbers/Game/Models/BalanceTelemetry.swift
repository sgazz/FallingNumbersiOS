import Foundation

enum GameOverReason: String, Equatable, Hashable {
    case columnFilledToTop
    case spawnBlocked
    case unknown
}

struct LevelOccupancyStats: Equatable {
    var sampleCount: Int
    var occupancySum: Int
    var minOccupancy: Int
    var maxOccupancy: Int

    static let empty = LevelOccupancyStats(
        sampleCount: 0,
        occupancySum: 0,
        minOccupancy: Int.max,
        maxOccupancy: Int.min
    )

    mutating func record(_ occupancy: Int) {
        sampleCount += 1
        occupancySum += occupancy
        minOccupancy = min(minOccupancy, occupancy)
        maxOccupancy = max(maxOccupancy, occupancy)
    }

    var averageOccupancy: Double {
        guard sampleCount > 0 else { return 0 }
        return Double(occupancySum) / Double(sampleCount)
    }
}

struct OccupancySample: Equatable {
    var time: TimeInterval
    var occupancyPercent: Int
}

struct SessionTelemetry: Equatable {
    var activeGameplaySeconds: TimeInterval
    var totalLocks: Int
    var totalMatches: Int
    var occupancySampleCount: Int
    var occupancySum: Int
    var maxOccupancy: Int
    var minOccupancy: Int
    var averageOccupancyLast60s: Double
    var timeAbove50Occupancy: TimeInterval
    var timeAbove70Occupancy: TimeInterval
    var topRowsTouchedCount: Int
    var nearDeathEvents: Int
    var expertPressureRampActive: Bool
    var expertSpawnPressureTier: Int
    var recentOccupancySamples: [OccupancySample]
    var wasTopRowsTouched: Bool
    var wasNearDeath: Bool
    var occupancyByLevel: [Int: LevelOccupancyStats]
    var powerUpsSpawned: [PowerUpType: Int]
    var powerUpsUsed: [PowerUpType: Int]
    var matchesByLength: [Int: Int]
    var cascadeDepthDistribution: [Int: Int]
    var timeSpentPerLevel: [Int: TimeInterval]
    var gameOverReason: GameOverReason?
    var didPrintSummary: Bool

    static let initial = SessionTelemetry(
        activeGameplaySeconds: 0,
        totalLocks: 0,
        totalMatches: 0,
        occupancySampleCount: 0,
        occupancySum: 0,
        maxOccupancy: 0,
        minOccupancy: Int.max,
        averageOccupancyLast60s: 0,
        timeAbove50Occupancy: 0,
        timeAbove70Occupancy: 0,
        topRowsTouchedCount: 0,
        nearDeathEvents: 0,
        expertPressureRampActive: false,
        expertSpawnPressureTier: 0,
        recentOccupancySamples: [],
        wasTopRowsTouched: false,
        wasNearDeath: false,
        occupancyByLevel: [:],
        powerUpsSpawned: [:],
        powerUpsUsed: [:],
        matchesByLength: [:],
        cascadeDepthDistribution: [:],
        timeSpentPerLevel: [:],
        gameOverReason: nil,
        didPrintSummary: false
    )
}
