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
        countryCode.unicodeScalars.compactMap { scalar in
            Unicode.Scalar(127397 + scalar.value).map { String($0) }
        }.joined()
    }
}
