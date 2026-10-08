import SwiftUI
import IPGlanceCore

struct MenuBarView: View {
    var viewModel: IPViewModel
    @Environment(\.openSettings) private var openSettings
    @AppStorage("settingsTab") private var settingsTab = "general"
    @State private var copied = false
    @State private var historyExpanded = false
    @State private var statusHovered = false

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .short; f.dateTimeStyle = .named; return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            if viewModel.isBlocked || viewModel.killSwitchError != nil {
                killSwitchSection
            }
            statusRow
            buttonsRow
            if !viewModel.history.isEmpty {
                historySection
            }
            actionsSection
            Divider()
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                    .frame(width: 56, height: 56)
                Text(viewModel.countryInfo?.flagEmoji ?? "🌐")
                    .font(.system(size: 36))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("current_ip", bundle: .module)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
                if viewModel.isLoading && viewModel.countryInfo == nil {
                    Text("...").font(.system(size: 18, weight: .semibold, design: .monospaced))
                } else {
                    Text(viewModel.countryInfo?.ip ?? "—")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .tracking(-0.2)
                    if let info = viewModel.countryInfo {
                        Text(info.city.isEmpty ? info.countryName : "\(info.countryName) · \(info.city)")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                        let details = [info.isp, info.asn, shortTZ(info.timezone)]
                            .filter { !$0.isEmpty && $0 != "—" }
                            .joined(separator: " · ")
                        if !details.isEmpty {
                            Text(verbatim: details)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .help(details)
                        }
                    }
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .padding(18)
        .padding(.bottom, 4)
    }

    // MARK: - Status

    private var statusRow: some View {
        let ks = viewModel.settings.killSwitchEnabled
        let showLeft = !(viewModel.isBlocked || viewModel.killSwitchError != nil)
        let allowed = viewModel.settings.allowedCountries
        let flags = allowed.prefix(3).map { CountryInfo(ip: "", countryCode: $0, countryName: "").flagEmoji }.joined()
        let more = allowed.count > 3 ? " +\(allowed.count - 3)" : ""
        let stateKey: LocalizedStringKey = ks ? "killswitch_on" : "killswitch_off"
        let stateText = String(localized: ks ? "killswitch_on" : "killswitch_off", bundle: .module)
        // ponytail: ticks every second even while the popover is hidden — negligible cost; switch to an onAppear-driven timer if it ever shows in Energy.
        return TimelineView(.periodic(from: .now, by: 1)) { context in
        Button {
            settingsTab = "killswitch"
            NSApplication.shared.activate()
            openSettings()
        } label: {
            HStack(spacing: 8) {
                if showLeft {
                    Label {
                        Text(stateKey, bundle: .module)
                    } icon: {
                        Image(systemName: ks ? "checkmark.shield" : "shield.slash")
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(ks ? .primary : .secondary)
                    if ks && !allowed.isEmpty {
                        Text(verbatim: flags + more).accessibilityHidden(true)
                    }
                }
                Spacer()
                lastCheckLabel(now: context.date)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(statusHovered ? Color.primary.opacity(0.07) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { statusHovered = $0 }
        .padding(.horizontal, 8)
        .accessibilityLabel(statusAccessibilityLabel(stateText, showLeft: showLeft, now: context.date))
        .accessibilityHint(Text("killswitch_status_hint", bundle: .module))
        }
    }

    @ViewBuilder private func lastCheckLabel(now: Date) -> some View {
        if viewModel.errorMessage != nil {
            Label {
                Text("status_check_failed", bundle: .module)
            } icon: {
                Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
            }
            .foregroundStyle(.secondary)
        } else if let last = viewModel.lastUpdated {
            Label {
                Text(verbatim: Self.relative.localizedString(for: last, relativeTo: now))
            } icon: {
                Image(systemName: "clock").accessibilityHidden(true)
            }
            .foregroundStyle(.secondary)
        } else {
            Label {
                Text("update_status_checking", bundle: .module)
            } icon: {
                Image(systemName: "clock").accessibilityHidden(true)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func statusAccessibilityLabel(_ state: String, showLeft: Bool, now: Date) -> String {
        var parts: [String] = []
        if showLeft { parts.append(state) }
        if viewModel.errorMessage != nil {
            parts.append(String(localized: "status_check_failed", bundle: .module))
        } else if let last = viewModel.lastUpdated {
            let rel = Self.relative.localizedString(for: last, relativeTo: now)
            parts.append(String(format: String(localized: "status_checked", bundle: .module), rel))
        } else {
            parts.append(String(localized: "update_status_checking", bundle: .module))
        }
        return parts.joined(separator: ", ")
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
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
                ActionRow(icon: "lock.open", label: "killswitch_unblock") {
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

    // MARK: - Buttons

    private var buttonsRow: some View {
        HStack(spacing: 8) {
            Button {
                guard let ip = viewModel.countryInfo?.ip else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ip, forType: .string)
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                Group {
                if copied {
                    Label { Text("copied", bundle: .module) } icon: { Image(systemName: "checkmark") }
                } else {
                    Label { Text("copy_ip", bundle: .module) } icon: { Image(systemName: "doc.on.doc") }
                }
                }
                .frame(maxWidth: .infinity)
            }
            .keyboardShortcut("c")
            .disabled(viewModel.countryInfo == nil)
            .help("⌘C")

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label { Text("refresh", bundle: .module) } icon: { Image(systemName: "arrow.clockwise") }
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut("r")
            .disabled(viewModel.isLoading)
            .help("⌘R")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - History

    private var historySection: some View {
        DisclosureGroup(isExpanded: $historyExpanded) {
            ForEach(Array(viewModel.history.prefix(3).enumerated()), id: \.offset) { _, h in
                HStack(spacing: 8) {
                    Text(h.flagEmoji).frame(width: 20)
                    Text(h.ip)
                        .font(.system(size: 11.5, design: .monospaced))
                    Spacer()
                    Text(h.countryName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 12))
                .padding(.vertical, 2)
            }
        } label: {
            (Text("recently", bundle: .module) + Text(verbatim: " (\(viewModel.history.count))"))
                .font(.system(size: 12))
                .contentShape(Rectangle())
                .onTapGesture { historyExpanded.toggle() }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "gearshape", label: "settings_ellipsis") {
                settingsTab = "general"
                // LSUIElement agents don't auto-foreground — without this
                // the window opens behind whatever app is currently active.
                NSApplication.shared.activate()
                openSettings()
            }
            .keyboardShortcut(",")
            ActionRow(icon: "info.circle", label: "about") {
                settingsTab = "about"
                NSApplication.shared.activate()
                openSettings()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(verbatim: "v \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
            Spacer()
            Link(destination: buyMeACoffeeURL) {
                HStack(spacing: 4) {
                    Text(verbatim: "☕").accessibilityHidden(true)
                    Text(verbatim: "Buy Me a Coffee")
                }
            }
            .accessibilityLabel(Text(verbatim: "Buy Me a Coffee"))
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("quit", bundle: .module)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func shortTZ(_ tz: String) -> String {
        guard !tz.isEmpty else { return "—" }
        return tz.split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") } ?? tz
    }
}

// MARK: - Sub-components

struct ActionRow: View {
    let icon: String
    let label: LocalizedStringKey
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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isHovered ? Color.primary.opacity(0.07) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
