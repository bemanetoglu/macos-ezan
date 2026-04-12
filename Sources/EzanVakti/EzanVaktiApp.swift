import SwiftUI

@main
struct EzanVaktiApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MainView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                if !viewModel.menuBarText.isEmpty {
                    Text(viewModel.menuBarText)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window) // Daha modern, popover şeklinde arayüz
    }
}
