import SwiftUI
import IPGlanceCore

struct AboutView: View {
    let updater: UpdaterController

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 31/255, green: 32/255, blue: 36/255) : Color(red: 244/255, green: 245/255, blue: 247/255) }
    private var panel: Color { isDark ? Color(red: 38/255, green: 40/255, blue: 45/255) : .white }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var stroke: Color { isDark ? .white.opacity(0.07) : .black.opacity(0.07) }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 20) {
                hero
                updatesSection
            }
            .padding(36)
        }
        .frame(width: 400)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(stroke, lineWidth: 0.5))
                    .frame(width: 80, height: 80)
                Text("🌐").font(.system(size: 50))
            }
            Text("IPGlance")
                .font(.system(size: 22, weight: .bold))
            Text("v \(appVersion)")
                .font(.system(size: 13))
                .foregroundStyle(sub)
            Text("about_description", bundle: .module)
                .font(.system(size: 13))
                .foregroundStyle(sub)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
    }

    // MARK: - Updates section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("updates_section_title", bundle: .module)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(sub)

            HStack {
                Button {
                    updater.checkForUpdates()
                } label: {
                    Text("check_for_updates_button", bundle: .module)
                }
                .disabled(!updater.canCheckForUpdates)

                Spacer()

                Toggle(isOn: Binding(
                    get: { updater.automaticChecksEnabled },
                    set: { updater.automaticChecksEnabled = $0 }
                )) {
                    Text("check_automatically_label", bundle: .module)
                        .font(.system(size: 12))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!updater.canCheckForUpdates)
            }

            statusLine
                .font(.system(size: 12))
                .foregroundStyle(sub)
        }
        .padding(14)
        .background(panel)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .foregroundStyle(.red)
            case .failed(.network), .failed(.other):
                Text("update_status_failed_generic", bundle: .module)
            }
        }
    }
}
