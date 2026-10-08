import XCTest
@testable import IPGlanceCore

final class KillSwitchConfigTests: XCTestCase {
    func testValidUserNames() {
        XCTAssertTrue(KillSwitchConfig.isValidUserName("vlad"))
        XCTAssertTrue(KillSwitchConfig.isValidUserName("_test.user-1"))
    }

    func testRejectsUnsafeUserNames() {
        for name in ["", "Bob", "bob; rm -rf /", "bob ALL", "bob\nroot", "bob\n", "1bob", "bob,root"] {
            XCTAssertFalse(KillSwitchConfig.isValidUserName(name), name)
            XCTAssertNil(KillSwitchConfig.sudoers(user: name), name)
            XCTAssertNil(KillSwitchConfig.installScript(user: name), name)
        }
    }

    func testSudoersGrantsExactlyFourCommands() {
        XCTAssertEqual(
            KillSwitchConfig.sudoers(user: "vlad"),
            "vlad ALL=(root) NOPASSWD: /sbin/pfctl -E, "
            + "/sbin/pfctl -a com.apple/ipglance -f /etc/pf.anchors/ipglance, "
            + "/sbin/pfctl -a com.apple/ipglance -F all, "
            + "/sbin/pfctl -a com.apple/ipglance -s rules\n"
        )
    }

    func testRulesAllowProviderHostsAndBlockTheRest() {
        let rules = KillSwitchConfig.rules
        for host in ["ipapi.co", "ipinfo.io", "ipwhois.app"] {
            XCTAssertTrue(rules.contains(host), host)
        }
        XCTAssertTrue(rules.contains("pass quick on lo0 all"))
        XCTAssertTrue(rules.hasSuffix("block drop out quick all\n"))
    }

    func testInstallScriptEmbedsFilesAsBase64() throws {
        let script = try XCTUnwrap(KillSwitchConfig.installScript(user: "vlad"))
        let rules64 = Data(KillSwitchConfig.rules.utf8).base64EncodedString()
        let sudoers64 = Data(try XCTUnwrap(KillSwitchConfig.sudoers(user: "vlad")).utf8).base64EncodedString()
        XCTAssertTrue(script.contains(rules64))
        XCTAssertTrue(script.contains(sudoers64))
        XCTAssertTrue(script.contains("/usr/sbin/visudo -cf"))
        XCTAssertTrue(script.contains("/etc/sudoers.d/ipglance"))
        // Root must never read files the user could have prepared.
        XCTAssertFalse(script.contains(NSHomeDirectory()))
    }
}
