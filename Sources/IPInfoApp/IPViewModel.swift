import Foundation
import IPInfoCore

@Observable
@MainActor
final class IPViewModel {
    var countryInfo: CountryInfo?
    var isLoading = false
    var errorMessage: String?
    // Last 5 previous IPs (excludes current)
    var history: [CountryInfo] = []

    let settings: AppSettings
    private let service: IPGeolocationService
    private var refreshTask: Task<Void, Never>?

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
        startAutoRefresh()
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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Call after changing settings.updateInterval to apply immediately
    func restartAutoRefresh() {
        startAutoRefresh()
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        guard settings.updateInterval > 0 else { return }
        let interval = Double(settings.updateInterval)
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }
}
