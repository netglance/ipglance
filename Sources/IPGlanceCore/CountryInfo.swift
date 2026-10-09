public struct CountryInfo: Sendable, Codable {
    public let ip: String
    public let countryCode: String
    public let countryName: String
    public let city: String
    public let region: String
    public let isp: String
    public let asn: String
    public let timezone: String

    public init(
        ip: String, countryCode: String, countryName: String,
        city: String = "", region: String = "", isp: String = "",
        asn: String = "", timezone: String = ""
    ) {
        self.ip = ip
        self.countryCode = countryCode.uppercased()
        self.countryName = countryName
        self.city = city
        self.region = region
        self.isp = isp
        self.asn = asn
        self.timezone = timezone
    }

    public var flagEmoji: String {
        let scalars = countryCode.unicodeScalars
        guard scalars.count == 2, scalars.allSatisfy({ ("A"..."Z").contains($0) }) else { return "🌐" }
        return scalars.compactMap { Unicode.Scalar(127397 + $0.value).map { String($0) } }.joined()
    }

    /// "Europe/New_York" → "New York"; "—" when unknown.
    public var shortTimezone: String {
        guard !timezone.isEmpty else { return "—" }
        return timezone.split(separator: "/").last
            .map { $0.replacingOccurrences(of: "_", with: " ") } ?? timezone
    }
}
