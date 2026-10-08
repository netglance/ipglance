import SwiftUI
import IPGlanceCore

struct SettingsView: View {
    var viewModel: IPViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SettingsDraft = .init()
    @State private var rulesInstalled = KillSwitch.isInstalled

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 31/255, green: 32/255, blue: 36/255) : Color(red: 244/255, green: 245/255, blue: 247/255) }
    private var panel: Color { isDark ? Color(red: 38/255, green: 40/255, blue: 45/255) : .white }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var stroke: Color { isDark ? .white.opacity(0.07) : .black.opacity(0.07) }
    private var danger: Color { isDark ? Color(red: 1.0, green: 0.50, blue: 0.47) : Color(red: 0.70, green: 0.08, blue: 0.08) }
    private var footerBg: Color { isDark ? Color(red: 35/255, green: 37/255, blue: 42/255) : Color(red: 238/255, green: 240/255, blue: 243/255) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                bg
                ScrollView {
                    generalTab
                }
            }
            footer
        }
        .frame(width: 560)
        .onAppear {
            viewModel.settings.refreshAutostartFromSystem()
            draft = SettingsDraft(from: viewModel.settings)
            rulesInstalled = KillSwitch.isInstalled
        }
    }

    // MARK: - General tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {

            SettingsSection(title: "section_launch", panel: panel, stroke: stroke, isDark: isDark) {
                SettingsField(label: "autostart_label", hint: "autostart_hint", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.autostartEnabled, isDark: isDark)
                        .accessibilityLabel(Text("autostart_label", bundle: .module))
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_flag", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showFlag, isDark: isDark)
                        .accessibilityLabel(Text("show_flag", bundle: .module))
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_country", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showCountry, isDark: isDark)
                        .accessibilityLabel(Text("show_country", bundle: .module))
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_ip", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showIP, isDark: isDark)
                        .accessibilityLabel(Text("show_ip", bundle: .module))
                }

                // Live preview
                HStack(spacing: 10) {
                    Text("preview", bundle: .module)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(sub)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                    HStack(spacing: 6) {
                        if draft.showFlag    { Text(viewModel.countryInfo?.flagEmoji ?? "🌐").font(.system(size: 13)) }
                        if draft.showCountry { Text(viewModel.countryInfo?.countryCode ?? "??").font(.system(size: 12.5, weight: .semibold)) }
                        if draft.showIP      { Text(viewModel.countryInfo?.ip ?? "0.0.0.0").font(.system(size: 11.5, design: .monospaced)) }
                        if !draft.showFlag && !draft.showCountry && !draft.showIP {
                            Text("empty", bundle: .module).font(.system(size: 11)).opacity(0.5)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.75))
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(stroke)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(.top, 8)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }

            SettingsSection(title: "section_killswitch", panel: panel, stroke: stroke, isDark: isDark) {
                SettingsField(label: "killswitch_label", hint: "killswitch_hint", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.killSwitchEnabled, isDark: isDark)
                        .disabled(draft.allowedCountries.isEmpty)
                        .accessibilityLabel(Text("killswitch_label", bundle: .module))
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "killswitch_allowed", isDark: isDark, sub: sub) {
                    HStack(spacing: 8) {
                        Button {
                            addCountry(currentCode)
                        } label: {
                            Text("killswitch_add_current", bundle: .module)
                        }
                        .controlSize(.small)
                        .disabled(currentCode == nil || draft.allowedCountries.contains(currentCode!))
                        Menu {
                            ForEach(Self.allRegions.filter { !draft.allowedCountries.contains($0) }, id: \.self) { code in
                                Button {
                                    addCountry(code)
                                } label: {
                                    Text(verbatim: "\(Self.flag(code)) \(Self.regionName(code))")
                                }
                            }
                        } label: {
                            Text("killswitch_add", bundle: .module)
                        }
                        .controlSize(.small)
                        .fixedSize()
                    }
                }
                if draft.allowedCountries.isEmpty {
                    Text("killswitch_empty", bundle: .module)
                        .font(.system(size: 12))
                        .foregroundStyle(sub)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(draft.allowedCountries, id: \.self) { code in
                            let removeLabel = String(format: String(localized: "killswitch_remove_country", bundle: .module), Self.regionName(code))
                            HStack(spacing: 8) {
                                Text(verbatim: Self.flag(code))
                                    .accessibilityHidden(true)
                                Text(verbatim: Self.regionName(code))
                                    .font(.system(size: 13))
                                Text(verbatim: code)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(sub)
                                    .accessibilityHidden(true)
                                Spacer()
                                Button {
                                    removeCountry(code)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .frame(minWidth: 22, minHeight: 22)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(sub)
                                .accessibilityLabel(Text(verbatim: removeLabel))
                                .help(removeLabel)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.bottom, 5)
                }
                if rulesInstalled {
                    SettingsDivider(isDark: isDark)
                    HStack {
                        Spacer()
                        Button {
                            draft.killSwitchEnabled = false
                            Task {
                                await viewModel.uninstallKillSwitch()
                                rulesInstalled = KillSwitch.isInstalled
                            }
                        } label: {
                            Text("killswitch_uninstall", bundle: .module)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                if let error = viewModel.killSwitchError {
                    Text(verbatim: error)
                        .font(.system(size: 11))
                        .foregroundStyle(danger)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
            }

        }
        .padding(26)
        .padding(.top, 2)
    }

    // MARK: - Kill switch helpers

    private var currentCode: String? {
        guard let code = viewModel.countryInfo?.countryCode.uppercased(), code.count == 2 else { return nil }
        return code
    }

    private func addCountry(_ code: String?) {
        guard let code = code?.uppercased(), code.count == 2, !draft.allowedCountries.contains(code) else { return }
        draft.allowedCountries.append(code)
    }

    private func removeCountry(_ code: String) {
        draft.allowedCountries.removeAll { $0 == code }
        // An empty list never blocks, so don't leave a toggle that does nothing.
        if draft.allowedCountries.isEmpty { draft.killSwitchEnabled = false }
    }

    private static let allRegions: [String] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) && Locale.current.localizedString(forRegionCode: $0) != nil }
        .sorted { regionName($0).localizedCompare(regionName($1)) == .orderedAscending }

    private static func regionName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    // Reuses CountryInfo's regional-indicator math instead of duplicating it.
    private static func flag(_ code: String) -> String {
        CountryInfo(ip: "", countryCode: code, countryName: "").flagEmoji
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Text("footer_hint", bundle: .module)
                .font(.system(size: 11))
                .foregroundStyle(sub)
            Spacer()
            Button {
                draft = SettingsDraft(from: viewModel.settings)
                dismiss()
            } label: {
                Text("cancel", bundle: .module)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.2), lineWidth: 0.5)
            )
            .background(isDark ? Color(red: 58/255, green: 61/255, blue: 68/255) : .white)
            .foregroundStyle(isDark ? .white : .black)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button {
                draft.apply(to: viewModel.settings)
                let killSwitchEnabled = draft.killSwitchEnabled
                Task { await viewModel.setKillSwitch(enabled: killSwitchEnabled) }
                dismiss()
            } label: {
                Text("save", bundle: .module)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(footerBg)
        .overlay(Divider().opacity(0.5), alignment: .top)
    }
}

// MARK: - Supporting types

enum SettingsTab: CaseIterable, Hashable {
    case general
    var label: LocalizedStringKey { "tab_general" }
    var icon: String { "gearshape" }
}

struct SettingsDraft {
    var showFlag: Bool = true
    var showCountry: Bool = true
    var showIP: Bool = false
    var autostartEnabled: Bool = false
    var killSwitchEnabled: Bool = false
    var allowedCountries: [String] = []

    init() {}

    @MainActor
    init(from s: AppSettings) {
        showFlag = s.showFlag
        showCountry = s.showCountry
        showIP = s.showIP
        autostartEnabled = s.autostartEnabled
        killSwitchEnabled = s.killSwitchEnabled
        allowedCountries = s.allowedCountries
    }

    @MainActor
    func apply(to s: AppSettings) {
        s.showFlag = showFlag
        s.showCountry = showCountry
        s.showIP = showIP
        s.autostartEnabled = autostartEnabled
        // Toggle is applied via setKillSwitch (async: may need a password and roll back).
        s.allowedCountries = allowedCountries
    }
}

// MARK: - Reusable setting components

struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let panel: Color
    let stroke: Color
    let isDark: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title, bundle: .module)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
            VStack(spacing: 0) {
                content
            }
            .background(panel)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(stroke, lineWidth: 0.5))
        }
    }
}

struct SettingsField<Control: View>: View {
    let label: LocalizedStringKey
    var hint: LocalizedStringKey? = nil
    let isDark: Bool
    let sub: Color
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label, bundle: .module)
                    .font(.system(size: 13))
                    .foregroundStyle(isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.85))
                if let hint {
                    Text(hint, bundle: .module)
                        .font(.system(size: 11))
                        .foregroundStyle(sub)
                }
            }
            Spacer()
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct SettingsDivider: View {
    let isDark: Bool
    var body: some View {
        Divider()
            .foregroundStyle(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
            .padding(.horizontal, 14)
    }
}

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let isDark: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.accentColor : (isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.18)))
                .frame(width: 36, height: 22)
                .shadow(color: .black.opacity(0.06), radius: 0, x: 0, y: 0)
            Circle()
                .fill(Color.white)
                .frame(width: 19, height: 19)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .padding(1.5)
        }
        .animation(.spring(response: 0.18), value: isOn)
        .opacity(isEnabled ? 1 : 0.4)
        .onTapGesture { if isEnabled { isOn.toggle() } }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(Text(isOn ? "toggle_on" : "toggle_off", bundle: .module))
        .accessibilityAction { if isEnabled { isOn.toggle() } }
        .focusable()
        .onKeyPress(.space) {
            if isEnabled { isOn.toggle() }
            return .handled
        }
    }
}

