import Foundation

struct GameEngine {
    private(set) var state: GameState
    let config: GameConfig

    private let detector: CombinationDetector
    private let spawnSystem: SpawnSystem
    private var gravitySystem: GravitySystem
    private let scoreSystem: ScoreSystem
    private let levelSystem: LevelSystem

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
        updateProgressionState()
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
        updateProgressionState()
        if !(1...9).contains(self.state.nextPieceValue) {
            self.state.nextPieceValue = spawnSystem.nextValue(level: self.state.level)
        }
    }

    mutating func send(_ action: GameAction) {
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
            stepDownOrLock()
        case .newGame, .togglePause:
            break
        }
    }

    private mutating func resetGame() {
        state = GameState.initial(config: config)
        updateProgressionState()
        state.nextPieceValue = spawnSystem.nextValue(level: state.level)
        spawnIfNeeded()
    }

    private mutating func moveActivePiece(columnDelta: Int) {
        guard var piece = state.activePiece else { return }
        let nextPosition = piece.position.translated(rowDelta: 0, columnDelta: columnDelta)
        guard state.board.canPlace(at: nextPosition) else { return }
        piece.position = nextPosition
        state.activePiece = piece
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
            state.hasPlayerMoved = true
            return
        }

        lock(piece)
        resolveBoard()
        spawnIfNeeded()
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

        lock(piece)
        resolveBoard()
        spawnIfNeeded()
    }

    private mutating func stepDownOrLock() {
        // Tick model: each tick attempts exactly one downward step.
        // If blocked, the active tile locks, board resolves, and next tile spawns.
        guard var piece = state.activePiece else {
            spawnIfNeeded()
            return
        }

        let nextPosition = piece.position.translated(rowDelta: 1, columnDelta: 0)
        if state.board.canPlace(at: nextPosition) {
            piece.position = nextPosition
            state.activePiece = piece
            return
        }

        lock(piece)
        resolveBoard()
        spawnIfNeeded()
    }

    private mutating func lock(_ piece: FallingPiece) {
        state.board.setCell(Cell(value: piece.value), at: piece.position)
        state.activePiece = nil
    }

    private mutating func resolveBoard() {
        var combo = 0

        while true {
            let groups = detector.findMatchingGroups(on: state.board, target: state.targetNumber)
            if groups.isEmpty {
                break
            }

            combo += 1
            // Deterministic resolution rule:
            // each pass clears exactly one group, chosen by largest group size first,
            // then by lexicographic grid-position key for stable tie-breaking.
            guard let selectedGroup = selectClearGroup(from: groups) else { break }

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
    }

    private mutating func updateProgressionState() {
        state.level = levelSystem.level(forClearedTiles: state.totalClearedTiles)
        state.targetNumber = levelSystem.targetNumber(level: state.level)
        state.currentTickInterval = levelSystem.tickInterval(base: config.tickInterval, level: state.level)
    }

    private mutating func spawnIfNeeded() {
        guard state.activePiece == nil else { return }

        let spawnValue = state.nextPieceValue
        guard let piece = spawnSystem.makePiece(on: state.board, value: spawnValue) else {
            state.isGameOver = true
            return
        }

        state.activePiece = piece
        state.nextPieceValue = spawnSystem.nextValue(level: state.level)
    }

    private func selectClearGroup(from groups: [[GridPosition]]) -> [GridPosition]? {
        groups.min(by: { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count > rhs.count
            }
            return groupKey(lhs) < groupKey(rhs)
        })
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
