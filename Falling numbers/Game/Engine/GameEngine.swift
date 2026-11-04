import Foundation

struct GameEngine {
    private(set) var state: GameState
    let config: GameConfig

    private let detector: CombinationDetector
    private let spawnSystem: SpawnSystem
    private var gravitySystem: GravitySystem
    private let scoreSystem: ScoreSystem
    private let levelSystem: LevelSystem
    private var fallTimeAccumulator: TimeInterval = 0
    private var pendingTargetCycleAdvance: Bool

    init(
        config: GameConfig = .default,
        detector: CombinationDetector = CombinationDetector(),
        spawnSystem: SpawnSystem = SpawnSystem(),
        gravitySystem: GravitySystem = GravitySystem(),
        scoreSystem: ScoreSystem = ScoreSystem(),
        levelSystem: LevelSystem = LevelSystem()
    ) {
        self.config = config
        self.state = GameState.initial(config: config, mode: .beginner)
        self.detector = detector
        self.spawnSystem = spawnSystem
        self.gravitySystem = gravitySystem
        self.scoreSystem = scoreSystem
        self.levelSystem = levelSystem
        self.pendingTargetCycleAdvance = false
        configureInitialTargetForMode()
        updateProgressionState()
        StartingLayoutSystem.apply(state: &state, seed: config.startingLayoutSeed)
        state.nextPieceKind = spawnSystem.nextTileKind(
            level: state.level,
            mode: state.gameMode,
            specialSpawnChance: effectiveSpecialSpawnChance(),
            recentValues: state.spawnedNumberHistory
        )
    }

    init(
        state: GameState,
        config: GameConfig = .default,
        detector: CombinationDetector = CombinationDetector(),
        spawnSystem: SpawnSystem = SpawnSystem(),
        gravitySystem: GravitySystem = GravitySystem(),
        scoreSystem: ScoreSystem = ScoreSystem(),
        levelSystem: LevelSystem = LevelSystem()
    ) {
        self.config = config
        self.state = state
        self.detector = detector
        self.spawnSystem = spawnSystem
        self.gravitySystem = gravitySystem
        self.scoreSystem = scoreSystem
        self.levelSystem = levelSystem
        self.pendingTargetCycleAdvance = false
        updateProgressionState()
        if case .number(let value) = self.state.nextPieceKind, (1...9).contains(value) == false {
            self.state.nextPieceKind = .number(spawnSystem.nextValue(level: self.state.level, mode: self.state.gameMode))
        }
    }

    mutating func send(_ action: GameAction) {
        state.didLevelChange = false
        state.didTargetChange = false
        state.didPerfectClear = false
        state.lastPerfectClearBonus = 0
        state.lastPowerUpActivation = nil
        state.lastSumClearEvent = nil

        switch action {
        case .newGame:
            resetGame()
            return
        case .setMode(let mode):
            setMode(mode)
            return
        case .togglePause:
            state.isPaused.toggle()
            return
        default:
            break
        }

        guard !state.isGameOver, !state.isPaused else { return }

        switch action {
        case .start:
            spawnIfNeeded()
        case .moveLeft:
            moveActivePiece(columnDelta: -1)
        case .moveRight:
            moveActivePiece(columnDelta: 1)
        case .softDrop:
            softDropStep()
        case .hardDrop:
            hardDrop()
        case .tick:
            advanceTime(by: state.currentTickInterval)
        case .advanceTime(let elapsed):
            advanceTime(by: elapsed)
        case .newGame, .setMode, .togglePause:
            break
        }
    }

    private mutating func resetGame() {
        state = GameState.initial(config: config, mode: state.gameMode)
        pendingTargetCycleAdvance = false
        fallTimeAccumulator = 0
        configureInitialTargetForMode()
        updateProgressionState()
        StartingLayoutSystem.apply(state: &state, seed: config.startingLayoutSeed)
        state.nextPieceKind = spawnSystem.nextTileKind(
            level: state.level,
            mode: state.gameMode,
            specialSpawnChance: effectiveSpecialSpawnChance(),
            recentValues: state.spawnedNumberHistory
        )
        spawnIfNeeded()
    }

    private mutating func setMode(_ mode: GameMode) {
        state.gameMode = mode
        resetGame()
    }

    private mutating func configureInitialTargetForMode() {
        guard state.gameMode == .expert else { return }
        state.targetNumber = Int.random(in: 5...20)
        state.targetCycleIndex = 0
        state.targetRepeatCount = 0
    }

    private mutating func moveActivePiece(columnDelta: Int) {
        guard var piece = state.activePiece else { return }
        let from = piece.position
        let nextPosition = piece.position.translated(rowDelta: 0, columnDelta: columnDelta)
        guard state.board.canPlace(at: nextPosition) else {
            GameDebugLogger.logMove(
                action: columnDelta < 0 ? "move_left" : "move_right",
                from: from,
                to: nil,
                accepted: false
            )
            return
        }
        piece.position = nextPosition
        state.activePiece = piece
        GameDebugLogger.logMove(
            action: columnDelta < 0 ? "move_left" : "move_right",
            from: from,
            to: nextPosition,
            accepted: true
        )
        if isGrounded(piece) {
            startLockDelay(resetToFull: true)
        } else {
            cancelLockDelay()
        }
        state.hasPlayerMoved = true
    }

    private mutating func softDropStep() {
        guard var piece = state.activePiece else {
            spawnIfNeeded()
            return
        }

        let from = piece.position
        let nextPosition = piece.position.translated(rowDelta: 1, columnDelta: 0)
        if state.board.canPlace(at: nextPosition) {
            piece.position = nextPosition
            state.activePiece = piece
            GameDebugLogger.logMove(action: "move_down", from: from, to: nextPosition, accepted: true)
            state.score += 1
            if isGrounded(piece) {
                startLockDelay(resetToFull: true)
            } else {
                cancelLockDelay()
            }
            state.hasPlayerMoved = true
            return
        }

        GameDebugLogger.logMove(action: "move_down", from: from, to: nil, accepted: false)
        startLockDelay(resetToFull: false)
    }

    private mutating func hardDrop() {
        guard var piece = state.activePiece else {
            spawnIfNeeded()
            return
        }

        var droppedRows = 0
        while true {
            let nextPosition = piece.position.translated(rowDelta: 1, columnDelta: 0)
            guard state.board.canPlace(at: nextPosition) else { break }
            piece.position = nextPosition
            droppedRows += 1
        }

        state.activePiece = piece
        state.score += droppedRows * 2
        state.hasPlayerMoved = true
        GameDebugLogger.logHardDrop(value: piece.kind.numericValue ?? 0, finalPosition: piece.position, droppedRows: droppedRows)

        cancelLockDelay()
        let lockedPosition = lock(piece)
        resolveAfterLock(for: piece, lockedPosition: lockedPosition)
        spawnIfNeeded()
        applyPendingTargetChangeIfSafe()
    }

    private mutating func advanceTime(by elapsed: TimeInterval) {
        guard elapsed.isFinite, elapsed > 0 else { return }
        BalanceTelemetrySystem.recordActiveGameplayTime(state: &state, elapsed: elapsed)
        guard !endGameIfAnyColumnFilledToTop() else { return }
        applyPendingTargetChangeIfSafe()
        advanceTargetTimerIfNeeded(elapsed: elapsed)
        guard let piece = state.activePiece else {
            spawnIfNeeded()
            return
        }

        if isGrounded(piece) {
            fallTimeAccumulator = 0
            if !state.isLockDelayActive {
                startLockDelay(resetToFull: false)
                return
            }
            consumeLockDelay(elapsed: elapsed)
            return
        }

        cancelLockDelay()
        fallTimeAccumulator += elapsed
        while fallTimeAccumulator + 0.000_001 >= state.currentTickInterval {
            fallTimeAccumulator = max(0, fallTimeAccumulator - state.currentTickInterval)
            guard var falling = state.activePiece else { break }
            falling.position = falling.position.translated(rowDelta: 1, columnDelta: 0)
            state.activePiece = falling
            if isGrounded(falling) {
                startLockDelay(resetToFull: false)
                let groundedTime = fallTimeAccumulator
                fallTimeAccumulator = 0
                consumeLockDelay(elapsed: groundedTime)
                break
            }
        }
    }

    private mutating func consumeLockDelay(elapsed: TimeInterval) {
        state.lockDelayRemaining = max(0, state.lockDelayRemaining - elapsed)
        guard state.lockDelayRemaining <= 0.000_001,
              let piece = state.activePiece else { return }
        cancelLockDelay()
        let lockedPosition = lock(piece)
        resolveAfterLock(for: piece, lockedPosition: lockedPosition)
        spawnIfNeeded()
        applyPendingTargetChangeIfSafe()
    }

    private mutating func lock(_ piece: FallingPiece) -> GridPosition {
        state.board.setCell(Cell(kind: piece.kind, id: piece.id), at: piece.position)
        GameDebugLogger.logLock(value: piece.kind.numericValue ?? 0, position: piece.position)
        state.lastLockedPosition = piece.position
        state.activePiece = nil
        state.telemetry.totalLocks += 1
        BalanceTelemetrySystem.recordOccupancySample(state: &state)
        BalanceTelemetrySystem.logPeriodicBalanceSample(state: &state, triggeredByLevelChange: false, spawnColumn: nil)
        return piece.position
    }

    private mutating func startLockDelay(resetToFull: Bool) {
        if !state.isLockDelayActive {
            state.isLockDelayActive = true
            state.lockDelayRemaining = config.lockDelayDuration
            return
        }

        if resetToFull {
            state.lockDelayRemaining = config.lockDelayDuration
        }
    }

    private mutating func cancelLockDelay() {
        state.isLockDelayActive = false
        state.lockDelayRemaining = 0
    }

    private mutating func resolveAfterLock(for piece: FallingPiece, lockedPosition: GridPosition) {
        switch piece.kind {
        case .number:
            resolveBoard(preferredOrigin: lockedPosition)
        case .rowClear:
            PowerUpSystem.activateRowClear(state: &state, gravitySystem: &gravitySystem, at: lockedPosition)
            resolveBoard(preferredOrigin: nil)
        case .columnClear:
            PowerUpSystem.activateColumnClear(state: &state, gravitySystem: &gravitySystem, at: lockedPosition)
            resolveBoard(preferredOrigin: nil)
        case .reorder:
            PowerUpSystem.activateReorder(state: &state, at: lockedPosition)
        }
    }

    private func isGrounded(_ piece: FallingPiece) -> Bool {
        let below = piece.position.translated(rowDelta: 1, columnDelta: 0)
        return !state.board.canPlace(at: below)
    }

    private mutating func resolveBoard(preferredOrigin: GridPosition?) {
        var combo = 0
        var originForCurrentPass = preferredOrigin
        var workingCascade = state.cascadeCount
        var chainClearedTiles = 0
        let cascadeAutoResolveCap = state.gameMode == .beginner ? 6 : 5

        while true {
            if combo >= cascadeAutoResolveCap {
                GameDebugLogger.logCascadeCapHit(
                    mode: state.gameMode,
                    cap: cascadeAutoResolveCap,
                    level: state.level,
                    cascade: max(1, workingCascade)
                )
                break
            }
            GameDebugLogger.logBoard(state.board, title: "board before detection")
            let groups = detector.findMatchingGroups(on: state.board, target: state.targetNumber)
            if groups.isEmpty {
                GameDebugLogger.log("resolve stopped: no matches")
                break
            }

            let candidateGroups: [[GridPosition]]
            if combo == 0, let anchor = originForCurrentPass {
                GameDebugLogger.log("resolve anchor r\(anchor.row)c\(anchor.column)")
                let containing = groups.filter { $0.contains(anchor) }
                let rejected = groups.filter { !$0.contains(anchor) }
                for group in rejected {
                    let pos = group.map { "r\($0.row)c\($0.column)" }.joined(separator: ",")
                    GameDebugLogger.log("rejected_non_anchor line=[\(pos)]")
                }
                if containing.isEmpty {
                    GameDebugLogger.log("resolve stopped: no anchor-matching lines")
                    break
                }
                candidateGroups = containing
            } else {
                candidateGroups = groups
            }

            combo += 1
            if combo == 1 {
                workingCascade = max(1, workingCascade)
            }
            if combo > 1 {
                workingCascade += 1
                GameDebugLogger.logCascade(step: combo)
            }
            // Deterministic line-clear resolution:
            // first pass prefers lines containing the just-locked tile.
            // Tie-break remains stable by longer line, then horizontal, then lexicographic key.
            guard let selectedGroup = selectClearGroup(from: candidateGroups, preferredOrigin: originForCurrentPass) else { break }
            originForCurrentPass = nil

            let scoreBefore = state.score
            let occupancyBefore = occupancyPercent()
            let orderedGroup = orderedPositions(in: selectedGroup, direction: directionFor(group: selectedGroup))
            let selectedValues = orderedGroup.compactMap { state.board.cell(at: $0)?.value }
            let direction: MatchDirection = isHorizontal(selectedGroup) ? .horizontal : .vertical
            for position in orderedGroup {
                state.board.setCell(nil, at: position)
            }
            GameDebugLogger.logBoard(state.board, title: "board after clear")

            let clearedCount = orderedGroup.count
            chainClearedTiles += clearedCount
            state.totalClearedTiles += clearedCount
            state.linesCleared += 1
            state.telemetry.totalMatches += 1
            state.telemetry.matchesByLength[clearedCount, default: 0] += 1
            state.longestLineCleared = max(state.longestLineCleared, clearedCount)
            let effectiveCascade = max(1, workingCascade)
            state.telemetry.cascadeDepthDistribution[effectiveCascade, default: 0] += 1
            state.highestCascade = max(state.highestCascade, effectiveCascade)
            let scoreBreakdown = scoreSystem.scoreBreakdownForClear(
                tileCount: clearedCount,
                cascade: effectiveCascade,
                isHorizontal: direction == .horizontal,
                expertMode: state.gameMode == .expert
            )
            state.score += scoreBreakdown.awardedScore
            state.lastClearLength = scoreBreakdown.lineLength
            state.lastClearLengthMultiplier = scoreBreakdown.lengthMultiplier
            state.specialSpawnChance = scoreSystem.specialSpawnChance(for: effectiveCascade, mode: state.gameMode)
            if state.gameMode == .beginner {
                state.lastSumClearEvent = SumClearEvent(
                    values: selectedValues,
                    target: state.targetNumber,
                    direction: direction == .horizontal ? .horizontal : .vertical,
                    positions: orderedGroup,
                    cascade: effectiveCascade
                )
                state.sumClearEventToken &+= 1
            }
            GameDebugLogger.logScoreBreakdown(
                cascade: effectiveCascade,
                lineLength: scoreBreakdown.lineLength,
                baseScore: scoreBreakdown.baseScore,
                lengthMultiplier: scoreBreakdown.lengthMultiplier,
                cascadeMultiplier: scoreBreakdown.cascadeMultiplier,
                expertMultiplier: scoreBreakdown.expertMultiplier,
                specialSpawnChance: state.specialSpawnChance,
                awarded: scoreBreakdown.awardedScore
            )

            gravitySystem.collapse(board: &state.board)
            GameDebugLogger.logBoard(state.board, title: "board after gravity")
            let occupancyAfter = occupancyPercent()
            let scoreGained = state.score - scoreBefore
            GameDebugLogger.logMatch(
                direction: direction,
                positions: orderedGroup,
                values: selectedValues,
                target: state.targetNumber,
                removed: clearedCount,
                cascade: effectiveCascade,
                score: scoreGained
            )
            if effectiveCascade >= 6 {
                GameDebugLogger.logLongCascade(
                    level: state.level,
                    target: state.targetNumber,
                    cascade: effectiveCascade,
                    occupancyBefore: occupancyBefore,
                    occupancyAfter: occupancyAfter,
                    clearedTilesInChain: chainClearedTiles
                )
            }
            if state.gameMode == .expert {
                // Expert anti-cascade: one clear pass per lock, no recursive chain resolving.
                break
            }
        }

        if combo > 0, boardIsEmpty() {
            let bonus = scoreSystem.perfectClearBonus(
                level: state.level,
                base: config.perfectClearBonusBase,
                perLevel: config.perfectClearBonusPerLevel
            )
            state.score += bonus
            state.didPerfectClear = true
            state.lastPerfectClearBonus = bonus
            state.perfectClearsCount += 1
            workingCascade = min(workingCascade + 1, 5)
            state.highestCascade = max(state.highestCascade, workingCascade)
            state.specialSpawnChance = scoreSystem.specialSpawnChance(for: workingCascade, mode: state.gameMode)
            GameDebugLogger.logPerfectClear(
                bonus: bonus,
                cascade: workingCascade,
                specialSpawnChance: state.specialSpawnChance
            )
        }

        if combo > 0 {
            state.cascadeCount = workingCascade
            state.movesWithoutClear = 0
        } else {
            state.movesWithoutClear += 1
            if state.movesWithoutClear >= 3 {
                state.cascadeCount = 0
            }
            state.specialSpawnChance = scoreSystem.specialSpawnChance(for: max(1, state.cascadeCount), mode: state.gameMode)
        }
        updateProgressionState()
        applyPendingTargetChangeIfSafe()
    }

    private func occupancyPercent() -> Int {
        let occupied = state.board.allOccupiedPositions().count
        let capacity = max(1, state.board.rows * state.board.columns)
        return Int((Double(occupied) / Double(capacity) * 100.0).rounded())
    }

    private mutating func updateProgressionState() {
        let previousLevel = state.level

        let computedLevel = levelSystem.level(forScore: state.score)
        state.level = computedLevel
        state.didLevelChange = computedLevel != previousLevel
        updateExpertPressureState()

        let baseTick = (state.gameMode == .expert) ? config.expertStartingTickInterval : config.tickInterval
        let speedMultiplier = levelSystem.fallSpeedMultiplier(forLevel: state.level, mode: state.gameMode)
        state.currentTickInterval = levelSystem.tickInterval(base: baseTick, level: state.level, mode: state.gameMode)
        if state.didLevelChange || state.level == 1 {
            GameDebugLogger.logSpeed(level: state.level, interval: state.currentTickInterval, mode: state.gameMode)
            GameDebugLogger.logFallSpeed(
                mode: state.gameMode,
                level: state.level,
                multiplier: speedMultiplier,
                baseFallInterval: baseTick,
                adjustedFallInterval: state.currentTickInterval
            )
        }

        if state.didLevelChange {
            BalanceTelemetrySystem.logPeriodicBalanceSample(state: &state, triggeredByLevelChange: true, spawnColumn: nil)
        }
    }

    private mutating func advanceTargetTimerIfNeeded(elapsed: TimeInterval) {
        guard state.activePiece != nil else { return }
        let timerMultiplier = levelSystem.targetTimerDecrementMultiplier(level: state.level, mode: state.gameMode)
        state.targetTimerRemaining -= elapsed * timerMultiplier
        if state.targetTimerRemaining <= 0 {
            pendingTargetCycleAdvance = true
            state.targetTimerRemaining += config.targetChangeInterval
        }
    }

    private mutating func applyPendingTargetChangeIfSafe() {
        guard pendingTargetCycleAdvance else { return }
        guard !state.isGameOver, !state.isPaused else { return }
        guard !state.isLockDelayActive else { return }
        guard state.activePiece != nil else { return }

        pendingTargetCycleAdvance = false
        let previous = state.targetNumber
        state.targetCycleIndex += 1
        state.targetNumber = levelSystem.targetNumber(
            forCycle: state.targetCycleIndex,
            previousTarget: previous,
            repeatCount: state.targetRepeatCount,
            mode: state.gameMode
        )
        if state.targetNumber == previous {
            state.targetRepeatCount += 1
            state.didTargetChange = false
        } else {
            state.targetRepeatCount = 0
            state.didTargetChange = true
            GameDebugLogger.logTargetChange(
                mode: state.gameMode,
                level: state.level,
                from: previous,
                to: state.targetNumber,
                cycle: state.targetCycleIndex
            )
        }
    }

    private mutating func spawnIfNeeded() {
        guard state.activePiece == nil else { return }
        guard !endGameIfAnyColumnFilledToTop() else { return }

        let spawnKind = state.nextPieceKind
        let preferredColumn: Int? = state.gameMode == .expert
            ? spawnSystem.expertSpawnColumn(columns: state.board.columns)
            : nil
        guard let piece = spawnSystem.makePiece(
            on: state.board,
            kind: spawnKind,
            mode: state.gameMode,
            pressureTier: state.expertSpawnPressureTier,
            preferredColumn: preferredColumn
        ) else {
            if !endGameIfAnyColumnFilledToTop() {
                state.isGameOver = true
                state.telemetry.gameOverReason = .spawnBlocked
                let blocked = GridPosition(row: 0, column: state.board.columns / 2)
                GameDebugLogger.logGameOver(spawnPosition: blocked, board: state.board)
                BalanceTelemetrySystem.logBalanceSummaryIfNeeded(state: &state)
            }
            return
        }

        if case .rowClear = piece.kind {
            state.telemetry.powerUpsSpawned[.rowClear, default: 0] += 1
        } else if case .columnClear = piece.kind {
            state.telemetry.powerUpsSpawned[.columnClear, default: 0] += 1
        } else if case .reorder = piece.kind {
            state.telemetry.powerUpsSpawned[.reorder, default: 0] += 1
        }

        state.activePiece = piece
        fallTimeAccumulator = 0
        state.lastLockedPosition = nil
        if let value = piece.kind.numericValue {
            state.spawnedNumberHistory.append(value)
            if state.spawnedNumberHistory.count > 12 {
                state.spawnedNumberHistory.removeFirst(state.spawnedNumberHistory.count - 12)
            }
        }
        GameDebugLogger.logPieceSpawn(value: piece.kind.numericValue ?? 0, position: piece.position)
        let occupied = state.board.allOccupiedPositions().count
        let capacity = max(1, state.board.rows * state.board.columns)
        let occupancyPercent = Int((Double(occupied) / Double(capacity) * 100.0).rounded())
        GameDebugLogger.logState(
            target: state.targetNumber,
            spawnColumn: piece.position.column,
            occupancyPercent: occupancyPercent
        )
        BalanceTelemetrySystem.logPeriodicBalanceSample(state: &state, triggeredByLevelChange: false, spawnColumn: piece.position.column)
        cancelLockDelay()
        state.nextPieceKind = spawnSystem.nextTileKind(
            level: state.level,
            mode: state.gameMode,
            specialSpawnChance: effectiveSpecialSpawnChance(),
            recentValues: state.spawnedNumberHistory
        )
    }

    private func effectiveSpecialSpawnChance() -> Double {
        let occupied = state.board.allOccupiedPositions().count
        let capacity = max(1, state.board.rows * state.board.columns)
        let occupancyPercent = Int((Double(occupied) / Double(capacity) * 100.0).rounded())
        let baseChance = state.specialSpawnChance
        let adjustedChance = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: baseChance,
            occupancyPercent: occupancyPercent,
            mode: state.gameMode
        )
        if adjustedChance < baseChance {
            GameDebugLogger.logPowerUpChanceAdjustment(
                mode: state.gameMode,
                reason: "low_occupancy",
                occupancyPercent: occupancyPercent,
                baseChance: baseChance,
                adjustedChance: adjustedChance
            )
        } else if adjustedChance > baseChance {
            GameDebugLogger.logPowerUpChanceAdjustment(
                mode: state.gameMode,
                reason: "rescue_high_occupancy",
                occupancyPercent: occupancyPercent,
                baseChance: baseChance,
                adjustedChance: adjustedChance
            )
        }
        return adjustedChance
    }

    private mutating func updateExpertPressureState() {
        guard state.gameMode == .expert else {
            state.expertPressureRampActive = false
            state.expertSpawnPressureTier = 0
            state.telemetry.expertPressureRampActive = false
            state.telemetry.expertSpawnPressureTier = 0
            return
        }
        let level = state.level
        let tier: Int
        if level >= 15 {
            tier = 2
        } else if level >= 12 {
            tier = 1
        } else {
            tier = 0
        }
        state.expertSpawnPressureTier = tier
        state.expertPressureRampActive = tier > 0
        state.telemetry.expertPressureRampActive = state.expertPressureRampActive
        state.telemetry.expertSpawnPressureTier = tier
    }

    private func selectClearGroup(from groups: [[GridPosition]], preferredOrigin: GridPosition?) -> [GridPosition]? {
        let preferredGroups: [[GridPosition]]
        if let preferredOrigin {
            let containing = groups.filter { $0.contains(preferredOrigin) }
            preferredGroups = containing.isEmpty ? groups : containing
        } else {
            preferredGroups = groups
        }

        return preferredGroups.min(by: { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count > rhs.count
            }
            let lhsHorizontal = isHorizontal(lhs)
            let rhsHorizontal = isHorizontal(rhs)
            if lhsHorizontal != rhsHorizontal {
                return lhsHorizontal && !rhsHorizontal
            }
            return groupKey(lhs) < groupKey(rhs)
        })
    }

    private func isHorizontal(_ group: [GridPosition]) -> Bool {
        guard let first = group.first else { return false }
        return group.allSatisfy { $0.row == first.row }
    }

    private func directionFor(group: [GridPosition]) -> MatchDirection {
        isHorizontal(group) ? .horizontal : .vertical
    }

    private func orderedPositions(in group: [GridPosition], direction: MatchDirection) -> [GridPosition] {
        switch direction {
        case .horizontal:
            return group.sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row < rhs.row }
                return lhs.column < rhs.column
            }
        case .vertical:
            return group.sorted { lhs, rhs in
                if lhs.column != rhs.column { return lhs.column < rhs.column }
                return lhs.row < rhs.row
            }
        }
    }

    private func groupKey(_ group: [GridPosition]) -> String {
        group
            .sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row < rhs.row }
                return lhs.column < rhs.column
            }
            .map { "\($0.row):\($0.column)" }
            .joined(separator: "|")
    }

    private func boardIsEmpty() -> Bool {
        state.board.cells.allSatisfy { $0 == nil }
    }

    private func isAnyColumnFilledToTop() -> Bool {
        guard state.board.rows > 0 else { return false }
        for column in 0..<state.board.columns {
            if state.board.cell(at: GridPosition(row: 0, column: column)) != nil {
                return true
            }
        }
        return false
    }

    @discardableResult
    private mutating func endGameIfAnyColumnFilledToTop() -> Bool {
        guard !state.isGameOver, isAnyColumnFilledToTop() else { return state.isGameOver }
        state.isGameOver = true
        state.activePiece = nil
        state.telemetry.gameOverReason = .columnFilledToTop
        let blocked = GridPosition(row: 0, column: state.board.columns / 2)
        GameDebugLogger.logGameOver(spawnPosition: blocked, board: state.board)
        BalanceTelemetrySystem.logBalanceSummaryIfNeeded(state: &state)
        return true
    }

}
