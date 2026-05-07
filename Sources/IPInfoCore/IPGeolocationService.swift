import Foundation

public protocol HTTPSession: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

public struct IPGeolocationService: Sendable {
    private let session: any HTTPSession
    private let apiURL = URL(string: "https://ipapi.co/json/")!

    public init(session: any HTTPSession = URLSession.shared) {
        self.session = session
    }

    public func fetchCountryInfo() async throws -> CountryInfo {
        let (data, urlResponse) = try await session.data(from: apiURL)
        if let http = urlResponse as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let response = try JSONDecoder().decode(IPAPIResponse.self, from: data)
        return CountryInfo(
            ip: response.ip,
            countryCode: response.country_code,
            countryName: response.country_name
        )
    }
}

private struct IPAPIResponse: Decodable {
    let ip: String
    let country_code: String
    let country_name: String
}
