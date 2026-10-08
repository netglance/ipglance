import XCTest
@testable import IPGlanceCore

final class KillSwitchRemovalTests: XCTestCase {
    func testConfirmsRemovingCurrentCountryWhenOthersRemain() {
        XCTAssertTrue(KillSwitchRemoval.needsConfirmation(removing: "PL", current: "PL", allowed: ["PL", "DE"], killSwitchEnabled: true))
    }
    func testNoConfirmationWhenKillSwitchOff() {
        XCTAssertFalse(KillSwitchRemoval.needsConfirmation(removing: "PL", current: "PL", allowed: ["PL", "DE"], killSwitchEnabled: false))
    }
    func testNoConfirmationForOtherCountry() {
        XCTAssertFalse(KillSwitchRemoval.needsConfirmation(removing: "DE", current: "PL", allowed: ["PL", "DE"], killSwitchEnabled: true))
    }
    func testNoConfirmationWhenLastCountry() {
        // Emptying the list turns the kill switch off — nothing gets blocked.
        XCTAssertFalse(KillSwitchRemoval.needsConfirmation(removing: "PL", current: "PL", allowed: ["PL"], killSwitchEnabled: true))
    }
    func testNoConfirmationWhenCurrentUnknown() {
        XCTAssertFalse(KillSwitchRemoval.needsConfirmation(removing: "PL", current: nil, allowed: ["PL", "DE"], killSwitchEnabled: true))
    }
    func testCaseInsensitive() {
        XCTAssertTrue(KillSwitchRemoval.needsConfirmation(removing: "pl", current: "PL", allowed: ["PL", "DE"], killSwitchEnabled: true))
    }
}
