// Sources/IPInfoApp/IPViewModel.swift
import Foundation
import IPInfoCore

@Observable
@MainActor
final class IPViewModel {
    var countryInfo: CountryInfo?
    var isLoading = false
    var errorMessage: String?

    private let service: IPGeolocationService
    private var refreshTask: Task<Void, Never>?

    var statusText: String {
        if isLoading { return "🌐 ..." }
        if let info = countryInfo { return info.displayText }
        if errorMessage != nil { return "🌐 ?" }
        return "🌐 ..."
    }

    init(service: IPGeolocationService = IPGeolocationService()) {
        self.service = service
        Task { await self.refresh() }
        startAutoRefresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            countryInfo = try await service.fetchCountryInfo()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }
}
