import Foundation

private let key = "cachedCountryInfo"
private let fetchedAtKey = "cachedFetchedAt"

public enum SharedStore {
    public static let defaultSuiteName = "group.com.ipglance.app"

    public static func write(_ info: CountryInfo, fetchedAt: Date = .now, suiteName: String = defaultSuiteName) {
        guard let data = try? JSONEncoder().encode(info), let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(data, forKey: key)
        defaults.set(fetchedAt, forKey: fetchedAtKey)
    }

    public static func read(suiteName: String = defaultSuiteName) -> CountryInfo? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CountryInfo.self, from: data)
    }

    /// `nil` for caches written before the date was stored.
    public static func readFetchedAt(suiteName: String = defaultSuiteName) -> Date? {
        UserDefaults(suiteName: suiteName)?.object(forKey: fetchedAtKey) as? Date
    }
}
