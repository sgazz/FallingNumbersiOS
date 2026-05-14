import SwiftUI

@main
struct FallingNumbersApp: App {
    @StateObject private var viewModel = GameScreenViewModel()

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
        }
    }
}
