import SwiftUI
import IPGlanceCore

struct AboutTab: View {
    let updater: UpdaterController

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    Text(verbatim: "IPGlance").font(.title2.bold())
                    Text(verbatim: "v \(appVersion)").foregroundStyle(.secondary)
                    Text("about_description", bundle: .module)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            Section {
                HStack {
                    Button { updater.checkForUpdates() } label: {
                        Text("check_for_updates_button", bundle: .module)
                    }
                    .disabled(!updater.canCheckForUpdates)
                    Spacer()
                    Toggle(isOn: Binding(
                        get: { updater.automaticChecksEnabled },
                        set: { updater.automaticChecksEnabled = $0 }
                    )) {
                        Text("check_automatically_label", bundle: .module)
                    }
                    .disabled(!updater.canCheckForUpdates)
                }
                statusLine.foregroundStyle(.secondary)
            } header: {
                Text("updates_section_title", bundle: .module)
            }
            Section {
                Link(destination: buyMeACoffeeURL) {
                    HStack(spacing: 6) {
                        Text(verbatim: "☕").accessibilityHidden(true)
                        Text(verbatim: "Buy Me a Coffee")
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(Text(verbatim: "Buy Me a Coffee"))
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 400)
    }

    @ViewBuilder
    private var statusLine: some View {
        if !updater.canCheckForUpdates {
            Text("update_status_disabled", bundle: .module)
        } else {
            switch updater.lastResult {
            case .idle:
                Text("update_status_idle", bundle: .module)
            case .checking:
                Text("update_status_checking", bundle: .module)
            case .upToDate:
                Text("update_status_up_to_date", bundle: .module)
            case .available(let version):
                Text(String(format: String(localized: "update_status_available", bundle: .module), version))
            case .failed(.signatureInvalid):
                Text("update_status_failed_signature", bundle: .module)
                    .foregroundStyle(Color.danger)
            case .failed(.network), .failed(.other):
                Text("update_status_failed_generic", bundle: .module)
            }
        }
    }
}
