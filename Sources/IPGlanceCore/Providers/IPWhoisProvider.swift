import Foundation

/// https://ipwhois.app/json/ — fallback, unlimited free
struct IPWhoisProvider: IPGeolocationProvider {
    private let session: any HTTPSession
    private let url = URL(string: "https://ipwhois.app/json/")!

    init(session: any HTTPSession) { self.session = session }

    func fetchCountryInfo() async throws -> CountryInfo {
        let (data, resp) = try await session.data(from: url)
        try validateHTTP(resp)
        let r = try JSONDecoder().decode(Response.self, from: data)
        guard r.success == true else { throw URLError(.badServerResponse) }
        let asn = r.asn ?? ""
        let isp = r.isp ?? r.org ?? ""
        return CountryInfo(
            ip: r.ip,
            countryCode: r.country_code ?? "",
            countryName: r.country ?? "",
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
        let success: Bool?
        let country: String?
        let country_code: String?
        let city: String?
        let region: String?
        let asn: String?
        let org: String?
        let isp: String?
        let timezone: String?
        let latitude: Double?
        let longitude: Double?
    }
}
