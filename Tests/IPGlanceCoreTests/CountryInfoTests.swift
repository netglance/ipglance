import XCTest
@testable import IPGlanceCore

final class CountryInfoTests: XCTestCase {
    func testFlagEmojiUS() {
        let info = CountryInfo(ip: "8.8.8.8", countryCode: "US", countryName: "United States")
        XCTAssertEqual(info.flagEmoji, "🇺🇸")
    }

    func testFlagEmojiRU() {
        let info = CountryInfo(ip: "1.2.3.4", countryCode: "RU", countryName: "Russia")
        XCTAssertEqual(info.flagEmoji, "🇷🇺")
    }

    func testFlagEmojiDE() {
        let info = CountryInfo(ip: "5.6.7.8", countryCode: "DE", countryName: "Germany")
        XCTAssertEqual(info.flagEmoji, "🇩🇪")
    }

    func testLowercaseCodeNormalized() {
        let info = CountryInfo(ip: "1.1.1.1", countryCode: "gb", countryName: "United Kingdom")
        XCTAssertEqual(info.flagEmoji, "🇬🇧")
    }

    func testFlagEmojiFallsBackToGlobe() {
        for code in ["", "U", "12", "U1", "USA", "é"] {
            XCTAssertEqual(CountryInfo(ip: "1.1.1.1", countryCode: code, countryName: "").flagEmoji, "🌐", code)
        }
    }

    func testShortTimezone() {
        func tz(_ s: String) -> String { CountryInfo(ip: "", countryCode: "US", countryName: "", timezone: s).shortTimezone }
        XCTAssertEqual(tz("America/New_York"), "New York")
        XCTAssertEqual(tz("UTC"), "UTC")
        XCTAssertEqual(tz(""), "—")
    }

    func testNewFieldsDefault() {
        let info = CountryInfo(ip: "1.1.1.1", countryCode: "AU", countryName: "Australia")
        XCTAssertEqual(info.city, "")
        XCTAssertEqual(info.isp, "")
        XCTAssertEqual(info.asn, "")
        XCTAssertEqual(info.timezone, "")
    }

    func testNewFieldsExplicit() {
        let info = CountryInfo(
            ip: "1.1.1.1", countryCode: "AU", countryName: "Australia",
            city: "Sydney", region: "NSW", isp: "Cloudflare",
            asn: "AS13335", timezone: "Australia/Sydney"
        )
        XCTAssertEqual(info.city, "Sydney")
        XCTAssertEqual(info.region, "NSW")
        XCTAssertEqual(info.isp, "Cloudflare")
        XCTAssertEqual(info.asn, "AS13335")
        XCTAssertEqual(info.timezone, "Australia/Sydney")
    }
}
