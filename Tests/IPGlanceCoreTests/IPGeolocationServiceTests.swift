import XCTest
@testable import IPGlanceCore

/// Responds per URL; unknown URLs fail like a dead host.
struct MockHTTPSession: HTTPSession {
    var responses: [String: (status: Int, body: String)] = [:]

    func data(from url: URL) async throws -> (Data, URLResponse) {
        guard let r = responses[url.absoluteString] else { throw URLError(.cannotFindHost) }
        let response = HTTPURLResponse(url: url, statusCode: r.status, httpVersion: nil, headerFields: nil)!
        return (Data(r.body.utf8), response)
    }
}

private let ipapi = "https://ipapi.co/json/"
private let ipinfo = "https://ipinfo.io/json"
private let ipwhois = "https://ipwhois.app/json/"

private let ipinfoJSON = """
{"ip":"9.9.9.9","city":"Berkeley","region":"California","country":"US",
 "org":"AS19281 Quad9","timezone":"America/Los_Angeles"}
"""
private let ipwhoisJSON = """
{"success":true,"ip":"1.1.1.1","country":"Australia","country_code":"AU","region":"Queensland",
 "city":"Brisbane","asn":"AS13335","org":"APNIC and Cloudflare DNS Resolver project",
 "isp":"Cloudflare, Inc.","timezone":"Australia/Brisbane"}
"""

final class IPGeolocationServiceTests: XCTestCase {
    private func fetch(_ responses: [String: (status: Int, body: String)]) async throws -> CountryInfo {
        try await IPGeolocationService(session: MockHTTPSession(responses: responses)).fetchCountryInfo()
    }

    func testFetchDecodes() async throws {
        let info = try await fetch([ipapi: (200, """
        {"ip":"8.8.8.8","country_code":"US","country_name":"United States",
         "city":"Mountain View","org":"AS15169 Google LLC"}
        """)])

        XCTAssertEqual(info.ip, "8.8.8.8")
        XCTAssertEqual(info.countryCode, "US")
        XCTAssertEqual(info.countryName, "United States")
        XCTAssertEqual(info.city, "Mountain View")
    }

    func testFetchDecodesExtendedFields() async throws {
        let info = try await fetch([ipapi: (200, """
        {"ip":"8.8.8.8","country_code":"US","country_name":"United States",
         "city":"Mountain View","region":"California",
         "org":"AS15169 Google LLC","timezone":"America/Los_Angeles"}
        """)])

        XCTAssertEqual(info.region, "California")
        XCTAssertEqual(info.asn, "AS15169")
        XCTAssertEqual(info.isp, "Google LLC")
        XCTAssertEqual(info.timezone, "America/Los_Angeles")
    }

    func testOrgParsingNoSpace() async throws {
        let info = try await fetch([ipapi: (200, """
        {"ip":"1.1.1.1","country_code":"AU","country_name":"Australia","org":"AS13335"}
        """)])

        XCTAssertEqual(info.asn, "AS13335")
        XCTAssertEqual(info.isp, "AS13335")
    }

    func testFetchNetworkError() async {
        do {
            _ = try await fetch([:])
            XCTFail("expected an error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testFetchInvalidJSON() async {
        do {
            _ = try await fetch([ipapi: (200, "not json"), ipinfo: (200, "not json"), ipwhois: (200, "not json")])
            XCTFail("expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFallsBackToSecondProviderWhenFirstFails() async throws {
        let info = try await fetch([ipinfo: (200, ipinfoJSON), ipwhois: (200, ipwhoisJSON)])
        XCTAssertEqual(info.ip, "9.9.9.9")
    }

    func testFirstSuccessfulProviderWins() async throws {
        let info = try await fetch([
            ipapi: (200, #"{"ip":"8.8.8.8","country_code":"US","country_name":"United States"}"#),
            ipinfo: (200, ipinfoJSON),
        ])
        XCTAssertEqual(info.ip, "8.8.8.8")
    }

    func testNon2xxFallsThrough() async throws {
        let info = try await fetch([ipapi: (429, "{}"), ipinfo: (200, ipinfoJSON)])
        XCTAssertEqual(info.ip, "9.9.9.9")
    }

    func testIPApiErrorFlagFallsThrough() async throws {
        let info = try await fetch([
            ipapi: (200, #"{"ip":"8.8.8.8","country_code":"US","country_name":"United States","error":true}"#),
            ipinfo: (200, ipinfoJSON),
        ])
        XCTAssertEqual(info.ip, "9.9.9.9")
    }

    func testIPInfoDecoding() async throws {
        let info = try await fetch([ipinfo: (200, ipinfoJSON)])
        XCTAssertEqual(info.countryCode, "US")
        XCTAssertEqual(info.city, "Berkeley")
        XCTAssertEqual(info.region, "California")
        XCTAssertEqual(info.asn, "AS19281")
        XCTAssertEqual(info.isp, "Quad9")
        XCTAssertEqual(info.timezone, "America/Los_Angeles")
    }

    func testIPWhoisDecoding() async throws {
        let info = try await fetch([ipwhois: (200, ipwhoisJSON)])
        XCTAssertEqual(info.ip, "1.1.1.1")
        XCTAssertEqual(info.countryCode, "AU")
        XCTAssertEqual(info.countryName, "Australia")
        XCTAssertEqual(info.asn, "AS13335")
        XCTAssertEqual(info.isp, "Cloudflare, Inc.")
        XCTAssertEqual(info.timezone, "Australia/Brisbane")
    }

    func testIPWhoisSuccessFalseFails() async {
        do {
            _ = try await fetch([ipwhois: (200, #"{"success":false,"ip":"1.1.1.1","message":"limit"}"#)])
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }
}
