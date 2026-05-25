import XCTest
@testable import IPGlanceCore

final class UpdateCheckResultTests: XCTestCase {
    func testIdleEquatable() {
        XCTAssertEqual(UpdateCheckResult.idle, UpdateCheckResult.idle)
    }

    func testAvailableCarriesVersion() {
        let a = UpdateCheckResult.available(version: "1.0.1")
        let b = UpdateCheckResult.available(version: "1.0.1")
        let c = UpdateCheckResult.available(version: "1.0.2")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testFailureCasesDistinct() {
        XCTAssertNotEqual(
            UpdateCheckResult.failed(.network),
            UpdateCheckResult.failed(.signatureInvalid)
        )
    }

    func testOtherFailureCarriesMessage() {
        let a = UpdateCheckResult.failed(.other(message: "boom"))
        let b = UpdateCheckResult.failed(.other(message: "boom"))
        let c = UpdateCheckResult.failed(.other(message: "different"))
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
