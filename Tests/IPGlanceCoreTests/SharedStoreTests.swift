import XCTest
@testable import IPGlanceCore

final class SharedStoreTests: XCTestCase {
    private let suite = "test.ipglance.sharedstore"

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
    }

    func testRoundTripKeepsInfoAndFetchTime() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        SharedStore.write(CountryInfo(ip: "8.8.8.8", countryCode: "us", countryName: "United States"),
                          fetchedAt: date, suiteName: suite)
        XCTAssertEqual(SharedStore.read(suiteName: suite)?.ip, "8.8.8.8")
        XCTAssertEqual(SharedStore.read(suiteName: suite)?.countryCode, "US")
        XCTAssertEqual(SharedStore.readFetchedAt(suiteName: suite), date)
    }

    func testEmptyStoreReadsNil() {
        XCTAssertNil(SharedStore.read(suiteName: suite))
        XCTAssertNil(SharedStore.readFetchedAt(suiteName: suite))
    }
}
