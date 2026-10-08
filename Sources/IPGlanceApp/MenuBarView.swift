import SwiftUI
import IPGlanceCore

struct MenuBarView: View {
    var viewModel: IPViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openSettings) private var openSettings
    @AppStorage("settingsTab") private var settingsTab = "general"

    private var isDark: Bool { colorScheme == .dark }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var hairline: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.06) }
    private var statBg: Color { isDark ? .white.opacity(0.04) : .black.opacity(0.03) }
    private var stroke: Color { isDark ? .white.opacity(0.08) : .black.opacity(0.07) }

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            if viewModel.isBlocked || viewModel.killSwitchError != nil {
                killSwitchSection
            }
            statsSection
            Divider().opacity(0.3).padding(.horizontal, 8)
            actionsSection
            if !viewModel.history.isEmpty {
                hairline.frame(height: 0.5).padding(.horizontal, 8)
                historySection
            }
            hairline.frame(height: 0.5)
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).stroke(stroke, lineWidth: 0.5)
                    )
                    .frame(width: 56, height: 56)
                Text(viewModel.countryInfo?.flagEmoji ?? "🌐")
                    .font(.system(size: 36))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("current_ip", bundle: .module)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(sub)
                    .textCase(.uppercase)
                    .tracking(0.4)
                if viewModel.isLoading {
                    Text("...").font(.system(size: 18, weight: .semibold, design: .monospaced))
                } else {
                    Text(viewModel.countryInfo?.ip ?? "—")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .tracking(-0.2)
                    if let info = viewModel.countryInfo {
                        Text(info.city.isEmpty ? info.countryName : "\(info.countryName) · \(info.city)")
                            .font(.system(size: 12.5))
                            .foregroundStyle(sub)
                    }
                }
            }
            Spacer()
        }
        .padding(18)
        .padding(.bottom, 4)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            StatCell(
                label: "provider",
                value: viewModel.countryInfo.map { firstWord($0.isp) } ?? "—",
                isDark: isDark
            )
            StatCell(
                label: "ASN",
                value: viewModel.countryInfo.map { $0.asn.isEmpty ? "—" : $0.asn } ?? "—",
                mono: true,
                isDark: isDark
            )
            StatCell(
                label: "timezone",
                value: viewModel.countryInfo.map { shortTZ($0.timezone) } ?? "—",
                isDark: isDark
            )
        }
        .background(statBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Kill switch

    private var killSwitchSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.isBlocked {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.danger)
                        .accessibilityHidden(true)
                    Text("killswitch_blocked", bundle: .module)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.danger)
                        .lineLimit(1)
                        .layoutPriority(1)
                    Spacer()
                    if let info = viewModel.countryInfo {
                        Text(verbatim: "\(info.flagEmoji) \(info.countryName)")
                            .font(.system(size: 12))
                            .foregroundStyle(sub)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
                ActionRow(icon: "lock.open", label: "killswitch_unblock", hint: "", isDark: isDark) {
                    Task { await viewModel.manualUnblock() }
                }
            }
            if let error = viewModel.killSwitchError {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.danger)
                        .accessibilityHidden(true)
                    Text(verbatim: error)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 4)
        .background(Color.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "doc.on.doc", label: "copy_ip", hint: "⌘C", isDark: isDark) {
                if let ip = viewModel.countryInfo?.ip {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(ip, forType: .string)
                }
            }
            ActionRow(
                icon: "arrow.clockwise", label: "refresh", hint: "⌘R",
                isDark: isDark, disabled: viewModel.isLoading
            ) {
                Task { await viewModel.refresh() }
            }
            ActionRow(icon: "gearshape", label: "settings_ellipsis", hint: "⌘,", isDark: isDark) {
                // LSUIElement agents don't auto-foreground — without this
                // the window opens behind whatever app is currently active.
                NSApplication.shared.activate()
                openSettings()
            }
            ActionRow(icon: "info.circle", label: "about", hint: "", isDark: isDark) {
                settingsTab = "about"
                NSApplication.shared.activate()
                openSettings()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("recently", bundle: .module)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(sub)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 18)
                .padding(.top, 8)

            ForEach(Array(viewModel.history.prefix(3).enumerated()), id: \.offset) { _, h in
                HStack(spacing: 8) {
                    Text(h.flagEmoji).frame(width: 20)
                    Text(h.ip)
                        .font(.system(size: 11.5, design: .monospaced))
                    Spacer()
                    Text(h.countryName)
                        .font(.system(size: 11))
                        .foregroundStyle(sub)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 18)
                .padding(.vertical, 3)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(verbatim: "v \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
                .font(.system(size: 11))
                .foregroundStyle(sub)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.19, green: 0.71, blue: 0.42))
                    .frame(width: 6, height: 6)
                Text("updated", bundle: .module)
                    .font(.system(size: 11))
                    .foregroundStyle(sub)
            }
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("quit", bundle: .module)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(sub)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func firstWord(_ s: String) -> String {
        s.split(separator: " ").first.map(String.init) ?? s
    }

    private func shortTZ(_ tz: String) -> String {
        guard !tz.isEmpty else { return "—" }
        return tz.split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") } ?? tz
    }
}

// MARK: - Sub-components

struct StatCell: View {
    let label: LocalizedStringKey
    let value: String
    var mono: Bool = false
    let isDark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label, bundle: .module)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: mono ? .monospaced : .default))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActionRow: View {
    let icon: String
    let label: LocalizedStringKey
    let hint: String
    let isDark: Bool
    var disabled: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .opacity(0.7)
                Text(label, bundle: .module).font(.system(size: 13))
                Spacer()
                Text(hint)
                    .font(.system(size: 11, design: .monospaced))
                    .opacity(isDark ? 0.45 : 0.4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isHovered
                    ? (isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .foregroundStyle(
                disabled
                    ? (isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                    : (isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.85))
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovered = $0 }
    }
}
