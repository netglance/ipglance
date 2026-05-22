import XCTest
@testable import IPGlanceCore

final class MockHTTPSession: HTTPSession, @unchecked Sendable {
    var mockData: Data = Data()
    var mockError: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError { throw error }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (mockData, response)
    }
}

final class IPGeolocationServiceTests: XCTestCase {
    func testFetchDecodes() async throws {
        let json = """
        {"ip":"8.8.8.8","country_code":"US","country_name":"United States",
         "city":"Mountain View","org":"AS15169 Google LLC"}
        """.data(using: .utf8)!
        let session = MockHTTPSession()
        session.mockData = json
        let service = IPGeolocationService(session: session)

        let info = try await service.fetchCountryInfo()

        XCTAssertEqual(info.ip, "8.8.8.8")
        XCTAssertEqual(info.countryCode, "US")
        XCTAssertEqual(info.countryName, "United States")
        XCTAssertEqual(info.city, "Mountain View")
    }

    func testFetchDecodesExtendedFields() async throws {
        let json = """
        {"ip":"8.8.8.8","country_code":"US","country_name":"United States",
         "city":"Mountain View","region":"California",
         "org":"AS15169 Google LLC","timezone":"America/Los_Angeles",
         "latitude":37.386,"longitude":-122.0838}
        """.data(using: .utf8)!
        let session = MockHTTPSession()
        session.mockData = json
        let service = IPGeolocationService(session: session)

        let info = try await service.fetchCountryInfo()

        XCTAssertEqual(info.city, "Mountain View")
        XCTAssertEqual(info.region, "California")
        XCTAssertEqual(info.asn, "AS15169")
        XCTAssertEqual(info.isp, "Google LLC")
        XCTAssertEqual(info.timezone, "America/Los_Angeles")
        XCTAssertEqual(info.latitude, 37.386, accuracy: 0.001)
        XCTAssertEqual(info.longitude, -122.0838, accuracy: 0.001)
    }

    func testOrgParsingNoSpace() async throws {
        let json = """
        {"ip":"1.1.1.1","country_code":"AU","country_name":"Australia","org":"AS13335"}
        """.data(using: .utf8)!
        let session = MockHTTPSession()
        session.mockData = json
        let service = IPGeolocationService(session: session)

        let info = try await service.fetchCountryInfo()

        XCTAssertEqual(info.asn, "AS13335")
        XCTAssertEqual(info.isp, "AS13335")
    }

    func testFetchNetworkError() async {
        let session = MockHTTPSession()
        session.mockError = URLError(.networkConnectionLost)
        let service = IPGeolocationService(session: session)

        do {
            _ = try await service.fetchCountryInfo()
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testFetchInvalidJSON() async {
        let session = MockHTTPSession()
        session.mockData = "not json".data(using: .utf8)!
        let service = IPGeolocationService(session: session)

        do {
            _ = try await service.fetchCountryInfo()
            XCTFail("Ожидалась ошибка декодирования")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}
