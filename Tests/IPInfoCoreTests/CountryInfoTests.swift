import XCTest
@testable import IPInfoCore

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

    func testDisplayText() {
        let info = CountryInfo(ip: "8.8.8.8", countryCode: "US", countryName: "United States")
        XCTAssertEqual(info.displayText, "🇺🇸 United States")
    }

    func testLowercaseCodeNormalized() {
        let info = CountryInfo(ip: "1.1.1.1", countryCode: "gb", countryName: "United Kingdom")
        XCTAssertEqual(info.flagEmoji, "🇬🇧")
    }
}
