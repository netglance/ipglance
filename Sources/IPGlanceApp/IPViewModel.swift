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

    let settings: AppSettings
    private let service: IPGeolocationService
    private var networkRefreshTask: Task<Void, Never>?
    private var periodicRefreshTask: Task<Void, Never>?
    private var pathMonitor: NWPathMonitor?
    private var wasNetworkSatisfied = true

    // Randomized to avoid a perfectly periodic request pattern.
    private let refreshIntervalRange: ClosedRange<Int> = 8...20

    var statusText: String {
        if isLoading { return "🌐 ..." }
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
        Task { await self.refresh() }
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
        errorMessage = nil
        do {
            let newInfo = try await service.fetchCountryInfo()
            if let current = countryInfo, current.ip != newInfo.ip {
                history.insert(current, at: 0)
                if history.count > 5 { history.removeLast() }
            }
            countryInfo = newInfo
            SharedStore.write(newInfo)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
