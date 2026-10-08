import Foundation
import Network
import WidgetKit
import IPGlanceCore

@Observable
@MainActor
final class IPViewModel {
    var countryInfo: CountryInfo?
    var isLoading = false
    var errorMessage: String?
    var history: [CountryInfo] = []
    var isBlocked = false
    var killSwitchError: String?

    let settings: AppSettings
    private let service: IPGeolocationService
    private var networkRefreshTask: Task<Void, Never>?
    private var periodicRefreshTask: Task<Void, Never>?
    private var pathMonitor: NWPathMonitor?
    private var wasNetworkSatisfied = true

    // Randomized to avoid a perfectly periodic request pattern.
    private let refreshIntervalRange: ClosedRange<Int> = 8...20

    var statusText: String {
        isBlocked ? "🔒 " + baseStatusText : baseStatusText
    }

    private var baseStatusText: String {
        if isLoading && countryInfo == nil { return "🌐 ..." }
        guard let info = countryInfo else {
            return errorMessage != nil ? "🌐 ?" : "🌐 ..."
        }
        var parts: [String] = []
        if settings.showFlag    { parts.append(info.flagEmoji) }
        if settings.showCountry { parts.append(info.countryCode) }
        if settings.showIP      { parts.append(info.ip) }
        return parts.isEmpty ? "🌐" : parts.joined(separator: " ")
    }

    init(settings: AppSettings = AppSettings(),
         service: IPGeolocationService = IPGeolocationService()) {
        self.settings = settings
        self.service = service
        Task {
            // The block outlives the app, so read the real pf state first.
            self.isBlocked = await KillSwitch.isBlocked()
            await self.refresh()
        }
        startNetworkMonitoring()
        startPeriodicRefresh()
    }

    private func startPeriodicRefresh() {
        periodicRefreshTask?.cancel()
        periodicRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let seconds = Int.random(in: self.refreshIntervalRange)
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                await self.refresh()
            }
        }
    }

    func refresh() async {
        isLoading = true
        do {
            let newInfo = try await service.fetchCountryInfo()
            if let current = countryInfo, current.ip != newInfo.ip {
                history.insert(current, at: 0)
                if history.count > 5 { history.removeLast() }
            }
            countryInfo = newInfo
            errorMessage = nil
            SharedStore.write(newInfo)
            WidgetCenter.shared.reloadAllTimelines()
            await applyKillSwitch()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Kill switch

    /// Applies the policy to the last known country. Called after every successful check
    /// and after settings change; failed checks never get here (fail-open).
    /// In-memory only: set by manual unblock, cleared by the next allowed country or by toggling the switch.
    private(set) var isKillSwitchPaused = false

    func applyKillSwitch() async {
        guard settings.killSwitchEnabled, let code = countryInfo?.countryCode, !code.isEmpty else { return }
        switch KillSwitchPolicy.action(country: code,
                                       allowed: Set(settings.allowedCountries),
                                       isBlocked: isBlocked,
                                       isPaused: isKillSwitchPaused) {
        case .block: await setBlocked(true)
        case .unblock: await setBlocked(false)
        case .resume: isKillSwitchPaused = false
        case .none: break
        }
    }

    func setKillSwitch(enabled: Bool) async {
        killSwitchError = nil
        isKillSwitchPaused = false
        guard enabled else {
            settings.killSwitchEnabled = false
            if isBlocked { await setBlocked(false) }
            return
        }
        if !KillSwitch.isInstalled {
            do {
                try await KillSwitch.install()
            } catch {
                settings.killSwitchEnabled = false
                if case KillSwitchError.cancelled = error {} else {
                    killSwitchError = error.localizedDescription
                }
                return
            }
        }
        settings.killSwitchEnabled = true
        await applyKillSwitch()
    }

    /// Unblocks and pauses until an allowed country is seen — otherwise the next check would block again.
    func manualUnblock() async {
        await setBlocked(false)
        if !isBlocked && settings.killSwitchEnabled { isKillSwitchPaused = true }
    }

    func uninstallKillSwitch() async {
        isKillSwitchPaused = false
        settings.killSwitchEnabled = false
        do {
            try await KillSwitch.uninstall()
            isBlocked = false
            killSwitchError = nil
        } catch {
            if case KillSwitchError.cancelled = error {} else {
                killSwitchError = error.localizedDescription
            }
        }
    }

    private func setBlocked(_ block: Bool) async {
        do {
            if block { try await KillSwitch.block() } else { try await KillSwitch.unblock() }
            isBlocked = block
            killSwitchError = nil
        } catch {
            killSwitchError = KillSwitch.isInstalled
                ? error.localizedDescription
                : String(localized: "killswitch_reinstall_hint", bundle: .module)
        }
    }

    private func startNetworkMonitoring() {
        pathMonitor?.cancel()
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            // Only pass a Bool (Sendable) across isolation boundary
            let isSatisfied = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = self.wasNetworkSatisfied
                self.wasNetworkSatisfied = isSatisfied
                // Only react to reconnect (unsatisfied → satisfied)
                guard isSatisfied, !wasConnected else { return }
                self.networkRefreshTask?.cancel()
                self.networkRefreshTask = Task { [weak self] in
                    // Brief pause to let the connection stabilise
                    try? await Task.sleep(for: .milliseconds(1500))
                    guard !Task.isCancelled else { return }
                    await self?.refresh()
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.ipglance.netmon", qos: .utility))
    }
}
