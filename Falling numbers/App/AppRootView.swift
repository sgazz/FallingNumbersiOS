import SwiftUI

struct AppRootView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @State private var flow: AppFlowState = .menu

    var body: some View {
        ZStack {
            switch flow {
            case .menu:
                MainMenuView(viewModel: viewModel) { mode in
                    if viewModel.state.gameMode != mode || viewModel.state.isGameOver {
                        viewModel.setMode(mode)
                    }
                    viewModel.startGameFromOverlay()
                    withAnimation(.easeInOut(duration: 0.24)) {
                        flow = .game
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .game:
                GameView(
                    viewModel: viewModel,
                    onMainMenu: {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            flow = .menu
                        }
                    },
                    showsEmbeddedStartOverlay: false
                )
                .transition(.opacity.combined(with: .scale(scale: 1.01)))
            }
        }
    }
}
