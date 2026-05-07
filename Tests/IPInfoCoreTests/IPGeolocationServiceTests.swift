import XCTest
@testable import IPInfoCore

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
        {"ip":"8.8.8.8","country_code":"US","country_name":"United States","city":"Mountain View"}
        """.data(using: .utf8)!
        let session = MockHTTPSession()
        session.mockData = json
        let service = IPGeolocationService(session: session)

        let info = try await service.fetchCountryInfo()

        XCTAssertEqual(info.ip, "8.8.8.8")
        XCTAssertEqual(info.countryCode, "US")
        XCTAssertEqual(info.countryName, "United States")
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
