import SwiftUI

@main
struct FallingNumbersApp: App {
    @StateObject private var viewModel = GameScreenViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background, .inactive:
                        viewModel.appDidEnterBackground()
                    case .active:
                        viewModel.appDidBecomeActive()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
