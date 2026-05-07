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

        let orgTrimmed = (response.org ?? "").trimmingCharacters(in: .whitespaces)
        let spaceIdx = orgTrimmed.firstIndex(of: " ") ?? orgTrimmed.endIndex
        let asn = String(orgTrimmed[orgTrimmed.startIndex..<spaceIdx])
        let isp = spaceIdx < orgTrimmed.endIndex ? String(orgTrimmed[orgTrimmed.index(after: spaceIdx)...]) : orgTrimmed

        return CountryInfo(
            ip: response.ip,
            countryCode: response.country_code,
            countryName: response.country_name,
            city: response.city ?? "",
            region: response.region ?? "",
            isp: isp,
            asn: asn,
            timezone: response.timezone ?? "",
            latitude: response.latitude ?? 0,
            longitude: response.longitude ?? 0
        )
    }
}

private struct IPAPIResponse: Decodable {
    let ip: String
    let country_code: String
    let country_name: String
    let city: String?
    let region: String?
    let org: String?
    let timezone: String?
    let latitude: Double?
    let longitude: Double?
}
