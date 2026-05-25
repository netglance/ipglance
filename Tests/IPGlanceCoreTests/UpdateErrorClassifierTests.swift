import XCTest
@testable import IPGlanceCore

final class UpdateErrorClassifierTests: XCTestCase {
    private let domain = "SUSparkleErrorDomain"

    func testSignatureErrorIsClassifiedAsInvalidSignature() {
        let result = UpdateErrorClassifier.classify(
            domain: domain,
            code: 3001,
            localizedDescription: "Signature did not match"
        )
        XCTAssertEqual(result, .signatureInvalid)
    }

    func testAppcastFamilyIsNetwork() {
        for code in [1000, 2000, 2001, 2002] {
            let result = UpdateErrorClassifier.classify(
                domain: domain,
                code: code,
                localizedDescription: "Network blip"
            )
            XCTAssertEqual(result, .network, "code \(code) should be .network")
        }
    }

    func testUnknownSparkleCodeFallsBackToOther() {
        let result = UpdateErrorClassifier.classify(
            domain: domain,
            code: 9999,
            localizedDescription: "Mystery"
        )
        XCTAssertEqual(result, .other(message: "Mystery"))
    }

    func testNonSparkleDomainAlwaysOther() {
        let result = UpdateErrorClassifier.classify(
            domain: "NSURLErrorDomain",
            code: 3001, // would map to signatureInvalid if domain matched
            localizedDescription: "Different domain"
        )
        XCTAssertEqual(result, .other(message: "Different domain"))
    }
}
