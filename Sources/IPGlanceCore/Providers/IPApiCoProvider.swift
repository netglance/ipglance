import Foundation

/// https://ipapi.co/json/ — original provider
struct IPApiCoProvider: IPGeolocationProvider {
    private let session: any HTTPSession
    private let url = URL(string: "https://ipapi.co/json/")!

    init(session: any HTTPSession) { self.session = session }

    func fetchCountryInfo() async throws -> CountryInfo {
        let (data, resp) = try await session.data(from: url)
        try validateHTTP(resp)
        let r = try JSONDecoder().decode(Response.self, from: data)
        if let error = r.error, error { throw URLError(.badServerResponse) }
        let (asn, isp) = parseOrg(r.org)
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

    private struct Response: Decodable {
        let ip: String
        let country_code: String
        let country_name: String
        let city: String?
        let region: String?
        let org: String?
        let timezone: String?
        let latitude: Double?
        let longitude: Double?
        let error: Bool?
    }
}
