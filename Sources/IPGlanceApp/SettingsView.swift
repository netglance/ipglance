import SwiftUI
import IPGlanceCore

struct SettingsView: View {
    var viewModel: IPViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SettingsDraft = .init()

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 31/255, green: 32/255, blue: 36/255) : Color(red: 244/255, green: 245/255, blue: 247/255) }
    private var panel: Color { isDark ? Color(red: 38/255, green: 40/255, blue: 45/255) : .white }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var stroke: Color { isDark ? .white.opacity(0.07) : .black.opacity(0.07) }
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
        }
    }

    // MARK: - General tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {

            SettingsSection(title: "section_launch", panel: panel, stroke: stroke, isDark: isDark) {
                SettingsField(label: "autostart_label", hint: "autostart_hint", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.autostartEnabled, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_flag", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showFlag, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_country", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showCountry, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "show_ip", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showIP, isDark: isDark)
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

        }
        .padding(26)
        .padding(.top, 2)
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

    init() {}

    @MainActor
    init(from s: AppSettings) {
        showFlag = s.showFlag
        showCountry = s.showCountry
        showIP = s.showIP
        autostartEnabled = s.autostartEnabled
    }

    @MainActor
    func apply(to s: AppSettings) {
        s.showFlag = showFlag
        s.showCountry = showCountry
        s.showIP = showIP
        s.autostartEnabled = autostartEnabled
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
        .onTapGesture { isOn.toggle() }
    }
}

