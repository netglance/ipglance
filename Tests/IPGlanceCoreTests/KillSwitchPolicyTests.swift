import XCTest
@testable import IPGlanceCore

final class KillSwitchPolicyTests: XCTestCase {
    private let allowed: Set<String> = ["DE", "NL"]

    func testFailedCheckChangesNothing() {
        XCTAssertEqual(KillSwitchPolicy.action(country: nil, allowed: allowed, isBlocked: false), .none)
        XCTAssertEqual(KillSwitchPolicy.action(country: nil, allowed: allowed, isBlocked: true), .none)
    }

    func testForeignCountryBlocks() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: allowed, isBlocked: false), .block)
    }

    func testForeignCountryAlreadyBlockedDoesNothing() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: allowed, isBlocked: true), .none)
    }

    func testAllowedCountryUnblocks() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "DE", allowed: allowed, isBlocked: true), .unblock)
    }

    func testAllowedCountryNotBlockedDoesNothing() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "NL", allowed: allowed, isBlocked: false), .none)
    }

    func testEmptyListNeverBlocks() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: [], isBlocked: false), .none)
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: [], isBlocked: true), .unblock)
    }

    func testCaseInsensitive() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "de", allowed: allowed, isBlocked: true), .unblock)
        XCTAssertEqual(KillSwitchPolicy.action(country: "DE", allowed: ["de"], isBlocked: true), .unblock)
    }

    func testPausedForeignDoesNothing() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: allowed, isBlocked: false, isPaused: true), .none)
    }

    func testPausedAllowedResumes() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "DE", allowed: allowed, isBlocked: false, isPaused: true), .resume)
    }

    func testPausedFailedCheckDoesNothing() {
        XCTAssertEqual(KillSwitchPolicy.action(country: nil, allowed: allowed, isBlocked: false, isPaused: true), .none)
    }

    func testPausedEmptyListResumes() {
        XCTAssertEqual(KillSwitchPolicy.action(country: "US", allowed: [], isBlocked: false, isPaused: true), .resume)
    }
}
