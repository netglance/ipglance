import Foundation

// MARK: - HTTP session abstraction

public protocol HTTPSession: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

// MARK: - Provider protocol

public protocol IPGeolocationProvider: Sendable {
    func fetchCountryInfo() async throws -> CountryInfo
}

// MARK: - Multi-provider service

public struct IPGeolocationService: Sendable {
    private let providers: [any IPGeolocationProvider]

    public init(session: any HTTPSession = URLSession.shared) {
        providers = [
            IPApiCoProvider(session: session),
            IPInfoProvider(session: session),
            IPWhoisProvider(session: session),
        ]
    }

    /// Tries providers in order, returning the first successful result.
    public func fetchCountryInfo() async throws -> CountryInfo {
        var lastError: Error = URLError(.unknown)
        for provider in providers {
            do {
                return try await provider.fetchCountryInfo()
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
