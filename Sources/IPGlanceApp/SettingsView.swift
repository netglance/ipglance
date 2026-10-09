import SwiftUI
import IPGlanceCore

struct SettingsView: View {
    let viewModel: IPViewModel
    let updater: UpdaterController
    @AppStorage("settingsTab") private var tab = "general"

    var body: some View {
        TabView(selection: $tab) {
            GeneralTab(viewModel: viewModel)
                .tabItem { Label { Text("tab_general", bundle: .module) } icon: { Image(systemName: "gearshape") } }
                .tag("general")
            KillSwitchTab(viewModel: viewModel)
                .tabItem { Label { Text("section_killswitch", bundle: .module) } icon: { Image(systemName: "lock.shield") } }
                .tag("killswitch")
            AboutTab(updater: updater)
                .tabItem { Label { Text("about", bundle: .module) } icon: { Image(systemName: "info.circle") } }
                .tag("about")
        }
    }
}

// MARK: - General

private struct GeneralTab: View {
    let viewModel: IPViewModel

    var body: some View {
        @Bindable var settings = viewModel.settings
        Form {
            Section {
                Toggle(isOn: $settings.autostartEnabled) { Text("autostart_label", bundle: .module) }
            } footer: {
                Text("autostart_hint", bundle: .module)
            }
            Section {
                Toggle(isOn: $settings.showFlag) { Text("show_flag", bundle: .module) }
                Toggle(isOn: $settings.showCountry) { Text("show_country", bundle: .module) }
                Toggle(isOn: $settings.showIP) { Text("show_ip", bundle: .module) }
                LabeledContent {
                    Text(viewModel.statusText)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                } label: {
                    Text("preview", bundle: .module)
                }
            } header: {
                Text("section_menubar", bundle: .module)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 300)
        .onAppear { viewModel.settings.refreshAutostartFromSystem() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.settings.refreshAutostartFromSystem()
        }
    }
}

// MARK: - Kill switch

private struct KillSwitchTab: View {
    let viewModel: IPViewModel
    @State private var rulesInstalled = KillSwitch.isInstalled
    @State private var pendingRemoval: String?
    @State private var picking = false

    private var currentCode: String? {
        guard let code = viewModel.countryInfo?.countryCode.uppercased(), code.count == 2 else { return nil }
        return code
    }

    var body: some View {
        @Bindable var settings = viewModel.settings
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { settings.killSwitchEnabled },
                    set: { v in Task { await viewModel.setKillSwitch(enabled: v) } }
                )) {
                    Text("killswitch_label", bundle: .module)
                }
                .disabled(settings.allowedCountries.isEmpty)
            } footer: {
                Text("killswitch_hint", bundle: .module)
            }

            Section {
                if settings.allowedCountries.isEmpty {
                    Text("killswitch_empty", bundle: .module)
                        .foregroundStyle(.secondary)
                }
                ForEach(settings.allowedCountries, id: \.self) { code in
                    let removeLabel = String(format: String(localized: "killswitch_remove_country", bundle: .module), Self.regionName(code))
                    HStack(spacing: 8) {
                        Text(verbatim: Self.flag(code)).accessibilityHidden(true)
                        Text(verbatim: Self.regionName(code))
                        Text(verbatim: code)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Spacer()
                        Button { requestRemoval(code) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(Text(verbatim: removeLabel))
                            .help(removeLabel)
                    }
                }
                HStack(spacing: 8) {
                    Button { addCountry(currentCode) } label: { Text("killswitch_add_current", bundle: .module) }
                        .disabled(currentCode.map(settings.allowedCountries.contains) ?? true)
                    Button { picking = true } label: { Text("killswitch_add", bundle: .module) }
                        .popover(isPresented: $picking, arrowEdge: .bottom) {
                            CountryPicker(codes: Self.allRegions.filter { !settings.allowedCountries.contains($0) }) {
                                addCountry($0)
                                picking = false
                            }
                        }
                }
            } header: {
                Text("killswitch_allowed", bundle: .module)
            }

            if rulesInstalled || viewModel.killSwitchError != nil {
                Section {
                    if rulesInstalled {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.uninstallKillSwitch()
                                rulesInstalled = KillSwitch.isInstalled
                            }
                        } label: {
                            Text("killswitch_uninstall", bundle: .module)
                        }
                    }
                    if let error = viewModel.killSwitchError {
                        Text(verbatim: error)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 440)
        .onAppear { rulesInstalled = KillSwitch.isInstalled }
        .onChange(of: settings.killSwitchEnabled) { rulesInstalled = KillSwitch.isInstalled }
        .onChange(of: settings.allowedCountries) {
            Task {
                if settings.allowedCountries.isEmpty && settings.killSwitchEnabled {
                    await viewModel.setKillSwitch(enabled: false)
                } else {
                    await viewModel.applyKillSwitch()
                }
            }
        }
        .confirmationDialog(
            Text("killswitch_remove_current_title", bundle: .module),
            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
            titleVisibility: .visible,
            presenting: pendingRemoval
        ) { code in
            Button(role: .destructive) { remove(code) } label: {
                Text("killswitch_remove_current_confirm", bundle: .module)
            }
            Button(role: .cancel) {} label: { Text("cancel", bundle: .module) }
        } message: { code in
            Text(String(format: String(localized: "killswitch_remove_current_message", bundle: .module), Self.regionName(code)))
        }
    }

    private func addCountry(_ code: String?) {
        let settings = viewModel.settings
        guard let code = code?.uppercased(), code.count == 2, !settings.allowedCountries.contains(code) else { return }
        settings.allowedCountries.append(code)
    }

    private func requestRemoval(_ code: String) {
        let settings = viewModel.settings
        if KillSwitchRemoval.needsConfirmation(removing: code, current: viewModel.countryInfo?.countryCode,
                                               allowed: settings.allowedCountries,
                                               killSwitchEnabled: settings.killSwitchEnabled) {
            pendingRemoval = code
        } else {
            remove(code)
        }
    }

    private func remove(_ code: String) {
        viewModel.settings.allowedCountries.removeAll { $0 == code }
    }

    private static let allRegions: [String] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) && Locale.current.localizedString(forRegionCode: $0) != nil }
        .sorted { regionName($0).localizedCompare(regionName($1)) == .orderedAscending }

    fileprivate static func regionName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    // Reuses CountryInfo's regional-indicator math instead of duplicating it.
    fileprivate static func flag(_ code: String) -> String {
        CountryInfo(ip: "", countryCode: code, countryName: "").flagEmoji
    }
}

private struct CountryPicker: View {
    let codes: [String]
    let onPick: (String) -> Void
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [String] {
        CountrySearch.filter(codes.map { (code: $0, name: KillSwitchTab.regionName($0)) }, query: query).map(\.code)
    }

    var body: some View {
        let results = results
        let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        VStack(spacing: 0) {
            TextField(text: $query, prompt: Text("killswitch_search_prompt", bundle: .module)) {
                Text("killswitch_search_prompt", bundle: .module)
            }
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
                shape.fill(.quaternary.opacity(0.5))
                    .overlay(shape.strokeBorder(focused ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1),
                                                lineWidth: focused ? 1.5 : 0.5))
            }
            .focused($focused)
            .focusEffectDisabled()
            .padding(10)
            // ponytail: no up/down arrows in the field; typing narrows to 1-3 rows. Upgrade: @State index + onKeyPress.
            .onSubmit { if searching, let first = results.first { onPick(first) } }
            if results.isEmpty {
                Text("killswitch_search_empty", bundle: .module)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(results, id: \.self) { code in
                    Button { onPick(code) } label: {
                        HStack(spacing: 8) {
                            Text(verbatim: KillSwitchTab.flag(code)).accessibilityHidden(true)
                            Text(verbatim: KillSwitchTab.regionName(code))
                            Spacer()
                            Text(verbatim: code)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: KillSwitchTab.regionName(code)))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                    .listRowBackground(
                        searching && code == results.first
                            ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15)).padding(.horizontal, 6)
                            : nil
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 280, height: 320)
        .onAppear { focused = true }
        .onChange(of: results.isEmpty) { _, empty in
            if empty { AccessibilityNotification.Announcement(String(localized: "killswitch_search_empty", bundle: .module)).post() }
        }
    }
}
