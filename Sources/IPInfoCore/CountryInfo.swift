public struct CountryInfo: Sendable {
    public let ip: String
    public let countryCode: String
    public let countryName: String

    public init(ip: String, countryCode: String, countryName: String) {
        self.ip = ip
        self.countryCode = countryCode.uppercased()
        self.countryName = countryName
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
