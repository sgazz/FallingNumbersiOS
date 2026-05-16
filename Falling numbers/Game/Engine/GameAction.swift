import Foundation

enum GameAction {
    case start
    case newGame
    case setMode(GameMode)
    case togglePause
    case moveLeft
    case moveRight
    case softDrop
    case hardDrop
    case tick
}
