import SwiftUI

let buyMeACoffeeURL = URL(string: "https://buymeacoffee.com/vpotar")!

extension Color {
    /// Shared error/blocked color (contrast-tuned per appearance).
    static let danger = Color(nsColor: NSColor(name: nil) {
        $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 1.0, green: 0.50, blue: 0.47, alpha: 1)
            : NSColor(red: 0.70, green: 0.08, blue: 0.08, alpha: 1)
    })
}

@main
struct IPGlanceApp: App {
    @State private var viewModel = IPViewModel()
    @State private var updater = UpdaterController()

    var body: some Scene {
        // Main popover — .window style allows custom UI with dark/light theme
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Text(viewModel.statusText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        // Native tabbed settings window (General / Kill switch / About)
        Settings {
            SettingsView(viewModel: viewModel, updater: updater)
        }
    }
}
