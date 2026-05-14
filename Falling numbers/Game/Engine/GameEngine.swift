import Foundation

struct GameEngine {
    private(set) var state: GameState
    let config: GameConfig

    private let detector: CombinationDetector
    private let spawnSystem: SpawnSystem
    private var gravitySystem: GravitySystem
    private let scoreSystem: ScoreSystem
    private let levelSystem: LevelSystem
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
        self.state = GameState.initial(config: config)
        self.detector = detector
        self.spawnSystem = spawnSystem
        self.gravitySystem = gravitySystem
        self.scoreSystem = scoreSystem
        self.levelSystem = levelSystem
        self.pendingTargetCycleAdvance = false
        updateProgressionState()
        applyStartingLayout()
        state.nextPieceValue = spawnSystem.nextValue(level: state.level)
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
        if !(1...9).contains(self.state.nextPieceValue) {
            self.state.nextPieceValue = spawnSystem.nextValue(level: self.state.level)
        }
    }

    mutating func send(_ action: GameAction) {
        state.didLevelChange = false
        state.didTargetChange = false

        switch action {
        case .newGame:
            resetGame()
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
            applyPendingTargetChangeIfSafe()
            advanceTargetTimerIfNeeded()
            stepDownOrLock()
        case .newGame, .togglePause:
            break
        }
    }

    private mutating func resetGame() {
        state = GameState.initial(config: config)
        pendingTargetCycleAdvance = false
        updateProgressionState()
        applyStartingLayout()
        state.nextPieceValue = spawnSystem.nextValue(level: state.level)
        spawnIfNeeded()
    }

    private mutating func moveActivePiece(columnDelta: Int) {
        guard var piece = state.activePiece else { return }
        let nextPosition = piece.position.translated(rowDelta: 0, columnDelta: columnDelta)
        guard state.board.canPlace(at: nextPosition) else { return }
        piece.position = nextPosition
        state.activePiece = piece
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

        let nextPosition = piece.position.translated(rowDelta: 1, columnDelta: 0)
        if state.board.canPlace(at: nextPosition) {
            piece.position = nextPosition
            state.activePiece = piece
            state.score += 1
            if isGrounded(piece) {
                startLockDelay(resetToFull: true)
            } else {
                cancelLockDelay()
            }
            state.hasPlayerMoved = true
            return
        }

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

        cancelLockDelay()
        let lockedPosition = lock(piece)
        resolveBoard(preferredOrigin: lockedPosition)
        spawnIfNeeded()
        applyPendingTargetChangeIfSafe()
    }

    private mutating func stepDownOrLock() {
        // Tick model: each tick attempts one downward step.
        // If blocked, lock delay runs while grounded; lock happens only when delay expires.
        guard var piece = state.activePiece else {
            spawnIfNeeded()
            return
        }

        let nextPosition = piece.position.translated(rowDelta: 1, columnDelta: 0)
        if state.board.canPlace(at: nextPosition) {
            piece.position = nextPosition
            state.activePiece = piece
            cancelLockDelay()
            return
        }

        if !state.isLockDelayActive {
            startLockDelay(resetToFull: false)
            return
        }

        state.lockDelayRemaining -= state.currentTickInterval
        if state.lockDelayRemaining <= 0 {
            cancelLockDelay()
            let lockedPosition = lock(piece)
            resolveBoard(preferredOrigin: lockedPosition)
            spawnIfNeeded()
            applyPendingTargetChangeIfSafe()
        }
    }

    private mutating func lock(_ piece: FallingPiece) -> GridPosition {
        state.board.setCell(Cell(value: piece.value), at: piece.position)
        state.activePiece = nil
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

    private func isGrounded(_ piece: FallingPiece) -> Bool {
        let below = piece.position.translated(rowDelta: 1, columnDelta: 0)
        return !state.board.canPlace(at: below)
    }

    private mutating func resolveBoard(preferredOrigin: GridPosition?) {
        var combo = 0
        var originForCurrentPass = preferredOrigin

        while true {
            let groups = detector.findMatchingGroups(on: state.board, target: state.targetNumber)
            if groups.isEmpty {
                break
            }

            combo += 1
            // Deterministic resolution rule:
            // the first clear pass prefers groups containing the just-locked tile,
            // then falls back to largest-group-first with lexicographic tie-breaking.
            // Chain passes use the regular deterministic largest-group-first behavior.
            guard let selectedGroup = selectClearGroup(from: groups, preferredOrigin: originForCurrentPass) else { break }
            originForCurrentPass = nil

            for position in selectedGroup {
                state.board.setCell(nil, at: position)
            }

            let clearedCount = selectedGroup.count
            state.totalClearedTiles += clearedCount
            state.score += scoreSystem.pointsForClear(tileCount: clearedCount, combo: combo)

            gravitySystem.collapse(board: &state.board)
        }

        state.comboCount = combo
        updateProgressionState()
        applyPendingTargetChangeIfSafe()
    }

    private mutating func updateProgressionState() {
        let previousLevel = state.level

        let computedLevel = levelSystem.level(forScore: state.score)
        state.level = computedLevel
        state.didLevelChange = computedLevel != previousLevel

        state.currentTickInterval = levelSystem.tickInterval(base: config.tickInterval, level: state.level)
    }

    private mutating func advanceTargetTimerIfNeeded() {
        guard state.activePiece != nil else { return }
        state.targetTimerRemaining -= state.currentTickInterval
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
            repeatCount: state.targetRepeatCount
        )
        if state.targetNumber == previous {
            state.targetRepeatCount += 1
            state.didTargetChange = false
        } else {
            state.targetRepeatCount = 0
            state.didTargetChange = true
        }
    }

    private mutating func spawnIfNeeded() {
        guard state.activePiece == nil else { return }

        let spawnValue = state.nextPieceValue
        guard let piece = spawnSystem.makePiece(on: state.board, value: spawnValue) else {
            state.isGameOver = true
            return
        }

        state.activePiece = piece
        cancelLockDelay()
        state.nextPieceValue = spawnSystem.nextValue(level: state.level)
    }

    private mutating func applyStartingLayout() {
        // Early-game pacing:
        // add a small deterministic prefill near the bottom to reduce empty-start feel,
        // while keeping spawn safe and avoiding immediate target clears.
        let templates: [[(rowFromBottom: Int, column: Int, value: Int)]] = [
            // Sum clusters intentionally avoid target=10 on spawn (pairs sum to 9/7/9).
            [(1, 1, 4), (1, 2, 5), (1, 7, 3), (1, 8, 4), (2, 4, 2), (2, 5, 7)],
            // Sums avoid target=10 (8, 9, 6); keeps gaps and bottom-heavy placement.
            [(1, 0, 3), (1, 1, 5), (1, 8, 5), (1, 9, 4), (2, 4, 2), (2, 6, 4)],
            // Slightly denser (7 tiles), still avoiding target=10 connected subsets.
            [(1, 1, 1), (1, 2, 8), (1, 6, 2), (1, 7, 7), (2, 4, 3), (2, 5, 5), (2, 8, 1)]
        ]

        let template = templates[abs(config.startingLayoutSeed) % templates.count]
        for item in template {
            let row = state.board.rows - item.rowFromBottom
            let position = GridPosition(row: row, column: item.column)
            guard state.board.isInside(position) else { continue }
            if state.board.cell(at: position) == nil {
                state.board.setCell(Cell(value: item.value), at: position)
            }
        }
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

    private func groupKey(_ group: [GridPosition]) -> String {
        group
            .sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row < rhs.row }
                return lhs.column < rhs.column
            }
            .map { "\($0.row):\($0.column)" }
            .joined(separator: "|")
    }
}
