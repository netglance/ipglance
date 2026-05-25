public struct CountryInfo: Sendable, Codable {
    public let ip: String
    public let countryCode: String
    public let countryName: String
    public let city: String
    public let region: String
    public let isp: String
    public let asn: String
    public let timezone: String
    public let latitude: Double
    public let longitude: Double

    public init(
        ip: String, countryCode: String, countryName: String,
        city: String = "", region: String = "", isp: String = "",
        asn: String = "", timezone: String = "",
        latitude: Double = 0, longitude: Double = 0
    ) {
        self.ip = ip
        self.countryCode = countryCode.uppercased()
        self.countryName = countryName
        self.city = city
        self.region = region
        self.isp = isp
        self.asn = asn
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
    }

    public var flagEmoji: String {
        countryCode.unicodeScalars.compactMap { scalar in
            Unicode.Scalar(127397 + scalar.value).map { String($0) }
        }.joined()
    }

    public var displayText: String {
        "\(flagEmoji) \(countryName)"
    }
}
