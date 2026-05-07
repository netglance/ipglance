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
        let r = try JSONDecoder().decode(IPAPIResponse.self, from: data)

        let org = r.org ?? ""
        let spaceIdx = org.firstIndex(of: " ") ?? org.endIndex
        let asn = String(org[org.startIndex..<spaceIdx])
        let isp = spaceIdx < org.endIndex ? String(org[org.index(after: spaceIdx)...]) : org

        return CountryInfo(
            ip: r.ip,
            countryCode: r.country_code,
            countryName: r.country_name,
            city: r.city ?? "",
            region: r.region ?? "",
            isp: isp,
            asn: asn,
            timezone: r.timezone ?? "",
            latitude: r.latitude ?? 0,
            longitude: r.longitude ?? 0
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
