import SwiftUI
import IPInfoCore

struct SettingsView: View {
    var viewModel: IPViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Local working copy of settings (Cancel reverts to last saved)
    @State private var draft: SettingsDraft = .init()
    @State private var selectedTab: SettingsTab = .general

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 31/255, green: 32/255, blue: 36/255) : Color(red: 244/255, green: 245/255, blue: 247/255) }
    private var panel: Color { isDark ? Color(red: 38/255, green: 40/255, blue: 45/255) : .white }
    private var sub: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }
    private var stroke: Color { isDark ? .white.opacity(0.07) : .black.opacity(0.07) }
    private var footerBg: Color { isDark ? Color(red: 35/255, green: 37/255, blue: 42/255) : Color(red: 238/255, green: 240/255, blue: 243/255) }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            ZStack {
                bg
                ScrollView {
                    switch selectedTab {
                    case .general: generalTab
                    case .support: supportTab
                    }
                }
            }
            footer
        }
        .frame(width: 560)
        .onAppear { draft = SettingsDraft(from: viewModel.settings) }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                            .opacity(selectedTab == tab ? 1 : 0.7)
                        Text(tab.label)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        selectedTab == tab
                            ? (isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07))
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.82))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(isDark ? Color(red: 35/255, green: 37/255, blue: 42/255) : Color(red: 244/255, green: 245/255, blue: 247/255))
        .overlay(Divider().opacity(0.5), alignment: .bottom)
    }

    // MARK: - General tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Launch section
            SettingsSection(title: "Запуск", panel: panel, stroke: stroke, isDark: isDark) {
                SettingsField(
                    label: "Запускать при входе в систему",
                    hint: "IP Info будет работать в фоне с момента старта macOS",
                    isDark: isDark, sub: sub
                ) {
                    SettingsToggle(isOn: $draft.autostartEnabled, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "Флаг страны", hint: "", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showFlag, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "Код страны", hint: "", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showCountry, isDark: isDark)
                }
                SettingsDivider(isDark: isDark)
                SettingsField(label: "IP-адрес", hint: "", isDark: isDark, sub: sub) {
                    SettingsToggle(isOn: $draft.showIP, isDark: isDark)
                }

                // Live preview
                HStack(spacing: 10) {
                    Text("Превью")
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
                            Text("(пусто)").font(.system(size: 11)).opacity(0.5)
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

            // Update interval section
            SettingsSection(title: "Обновление", panel: panel, stroke: stroke, isDark: isDark) {
                SettingsField(
                    label: "Интервал",
                    hint: "Как часто проверять текущий IP",
                    isDark: isDark, sub: sub
                ) {
                    CustomSegmentedControl(
                        value: $draft.updateInterval,
                        options: [
                            (30, "30 с"),
                            (60, "1 мин"),
                            (300, "5 мин"),
                            (0, "Вручную"),
                        ],
                        isDark: isDark
                    )
                }
            }
        }
        .padding(26)
        .padding(.top, 2)
    }

    // MARK: - Support tab

    private var supportTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection(title: "Поддержать разработчика", panel: panel, stroke: stroke, isDark: isDark) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.08), lineWidth: 0.5))
                            .frame(width: 44, height: 44)
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 20))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Buy me a coffee")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Если приложение полезно — угостите чашкой кофе ☕")
                            .font(.system(size: 12))
                            .opacity(0.75)
                    }
                    Spacer()
                    Button("Поддержать") {
                        NSWorkspace.shared.open(URL(string: "https://buymeacoffee.com")!)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 1, green: 0.87, blue: 0))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 13/255, green: 36/255, blue: 54/255))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.87, blue: 0), Color(red: 1, green: 0.7, blue: 0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(Color(red: 13/255, green: 36/255, blue: 54/255))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
        }
        .padding(26)
        .padding(.top, 2)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Text("Изменения применяются сразу после сохранения")
                .font(.system(size: 11))
                .foregroundStyle(sub)
            Spacer()
            Button("Отменить") {
                draft = SettingsDraft(from: viewModel.settings)
                dismiss()
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

            Button("Сохранить") {
                draft.apply(to: viewModel.settings)
                viewModel.restartAutoRefresh()
                dismiss()
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
    case general, support
    var label: String { self == .general ? "Общие" : "Поддержать" }
    var icon: String { self == .general ? "gearshape" : "cup.and.saucer" }
}

struct SettingsDraft {
    var showFlag: Bool = true
    var showCountry: Bool = true
    var showIP: Bool = false
    var updateInterval: Int = 60
    var autostartEnabled: Bool = false

    init() {}

    @MainActor
    init(from s: AppSettings) {
        showFlag = s.showFlag
        showCountry = s.showCountry
        showIP = s.showIP
        updateInterval = s.updateInterval
        autostartEnabled = s.autostartEnabled
    }

    @MainActor
    func apply(to s: AppSettings) {
        s.showFlag = showFlag
        s.showCountry = showCountry
        s.showIP = showIP
        s.updateInterval = updateInterval
        s.autostartEnabled = autostartEnabled
    }
}

// MARK: - Reusable setting components

struct SettingsSection<Content: View>: View {
    let title: String
    let panel: Color
    let stroke: Color
    let isDark: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
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
    let label: String
    let hint: String
    let isDark: Bool
    let sub: Color
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.85))
                if !hint.isEmpty {
                    Text(hint)
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

struct CustomSegmentedControl: View {
    @Binding var value: Int
    let options: [(Int, String)]
    let isDark: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { opt in
                let active = opt.0 == value
                Text(opt.1)
                    .font(.system(size: 12, weight: active ? .semibold : .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        active
                            ? (isDark ? Color(red: 58/255, green: 61/255, blue: 68/255) : .white)
                            : Color.clear
                    )
                    .foregroundStyle(
                        active
                            ? (isDark ? .white : .black)
                            : (isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.65))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: active ? .black.opacity(0.12) : .clear, radius: 1, y: 1)
                    .onTapGesture { value = opt.0 }
            }
        }
        .padding(2)
        .background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
