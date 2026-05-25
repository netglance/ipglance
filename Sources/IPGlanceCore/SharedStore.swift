import Foundation

private let suiteName = "group.com.ipglance.app"
private let key = "cachedCountryInfo"

public enum SharedStore {
    public static func write(_ info: CountryInfo) {
        guard let data = try? JSONEncoder().encode(info) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
    }

    public static func read() -> CountryInfo? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CountryInfo.self, from: data)
    }
}
