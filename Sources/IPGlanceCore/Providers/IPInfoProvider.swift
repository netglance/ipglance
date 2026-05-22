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
        let (lat, lon) = parseLoc(r.loc)
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
            timezone: r.timezone ?? "",
            latitude: lat,
            longitude: lon
        )
    }

    private struct Response: Decodable {
        let ip: String
        let country: String?
        let city: String?
        let region: String?
        let org: String?
        let loc: String?
        let timezone: String?
    }
}

private func parseLoc(_ loc: String?) -> (Double, Double) {
    guard let parts = loc?.split(separator: ","), parts.count == 2 else { return (0, 0) }
    return (Double(parts[0]) ?? 0, Double(parts[1]) ?? 0)
}
