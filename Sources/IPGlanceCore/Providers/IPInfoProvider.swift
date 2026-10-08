import Foundation

/// https://ipinfo.io/json — 50k req/month free
struct IPInfoProvider: IPGeolocationProvider {
    private let session: any HTTPSession
    private let url = URL(string: "https://ipinfo.io/json")!

    init(session: any HTTPSession) { self.session = session }

    func fetchCountryInfo() async throws -> CountryInfo {
        let (data, resp) = try await session.data(from: url)
        try validateHTTP(resp)
        let r = try JSONDecoder().decode(Response.self, from: data)
        let (asn, isp) = parseOrg(r.org)
        let code = r.country ?? ""
        let name = Locale.current.localizedString(forRegionCode: code) ?? code
        return CountryInfo(
            ip: r.ip,
            countryCode: code,
            countryName: name,
            city: r.city ?? "",
            region: r.region ?? "",
            isp: isp,
            asn: asn,
            timezone: r.timezone ?? ""
        )
    }

    private struct Response: Decodable {
        let ip: String
        let country: String?
        let city: String?
        let region: String?
        let org: String?
        let timezone: String?
    }
}
