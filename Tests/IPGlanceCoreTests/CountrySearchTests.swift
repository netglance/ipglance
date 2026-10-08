import XCTest
@testable import IPGlanceCore

final class CountrySearchTests: XCTestCase {
    private let all: [(code: String, name: String)] = [
        ("AT", "Austria"), ("AU", "Australia"), ("DE", "Germany"), ("DK", "Denmark"),
        ("GH", "Ghana"), ("AT2", "Österreich"), ("US", "United States"),
    ]

    private func codes(_ q: String) -> [String] { CountrySearch.filter(all, query: q).map(\.code) }

    func testEmptyAndWhitespaceReturnAll() {
        XCTAssertEqual(codes(""), all.map(\.code))
        XCTAssertEqual(codes("   "), all.map(\.code))
    }
    func testNameSubstringCaseAndDiacriticInsensitive() {
        XCTAssertEqual(codes("osterreich"), ["AT2"])
        XCTAssertEqual(codes("GERM"), ["DE"])
    }
    func testCodePrefix() {
        XCTAssertEqual(codes("de"), ["DE", "DK"]) // DK via name "Denmark"; DE exact code first
        XCTAssertEqual(codes("gh"), ["GH"])
        XCTAssertEqual(codes("d"), ["DE", "DK", "US"]) // codes DE, DK by prefix; US via "United"
    }
    func testExactCodeMatchFirst() {
        // "us" also matches names containing "us" (Austria, Australia); US must lead.
        XCTAssertEqual(codes("us"), ["US", "AT", "AU"])
    }
    func testNoMatchIsEmpty() {
        XCTAssertTrue(codes("zzz").isEmpty)
    }
}
