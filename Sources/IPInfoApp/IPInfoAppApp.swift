import SwiftUI

@main
struct IPInfoAppApp: App {
    @State private var viewModel = IPViewModel()

    var body: some Scene {
        // Main popover — .window style allows custom UI with dark/light theme
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Text(viewModel.statusText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        // Settings window — opened via openWindow(id: "settings")
        Window("Настройки — IP Info", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 540)
    }
}
