import SwiftUI

@main
struct IPGlanceApp: App {
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
        Window(String(localized: "window_settings_title", bundle: .module), id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 540)

        // About window — opened via openWindow(id: "about")
        Window(String(localized: "window_about_title", bundle: .module), id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
