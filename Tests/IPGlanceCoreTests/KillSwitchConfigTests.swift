import XCTest
@testable import IPGlanceCore

final class KillSwitchConfigTests: XCTestCase {
    func testValidUserNames() {
        XCTAssertTrue(KillSwitchConfig.isValidUserName("vlad"))
        XCTAssertTrue(KillSwitchConfig.isValidUserName("_test.user-1"))
        XCTAssertTrue(KillSwitchConfig.isValidUserName("Vlad"))
        XCTAssertTrue(KillSwitchConfig.isValidUserName("1user"))
        XCTAssertNotNil(KillSwitchConfig.sudoers(user: "Vlad"))
    }

    func testRejectsUnsafeUserNames() {
        for name in ["", "bob; rm -rf /", "bob ALL", "bob\nroot", "bob\n", "bob,root", "bob#", "bob:x", "bob=x", "bob\\x"] {
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

    func testRulesStartWithVersionedHeader() {
        XCTAssertTrue(KillSwitchConfig.rules.hasPrefix(KillSwitchConfig.rulesHeader + "\n"))
        XCTAssertTrue(KillSwitchConfig.rulesHeader.contains(" v2 "))
    }

    func testPassRulesAreStateless() {
        let passLines = KillSwitchConfig.rules.split(separator: "\n").filter { $0.hasPrefix("pass") }
        XCTAssertEqual(passLines.count, 5)
        for line in passLines { XCTAssertTrue(line.hasSuffix("no state"), String(line)) }
    }

    func testInstallScriptEmbedsFilesAsBase64() throws {
        let script = try XCTUnwrap(KillSwitchConfig.installScript(user: "vlad"))
        let rules64 = Data(KillSwitchConfig.rules.utf8).base64EncodedString()
        let sudoers64 = Data(try XCTUnwrap(KillSwitchConfig.sudoers(user: "vlad")).utf8).base64EncodedString()
        XCTAssertTrue(script.contains(rules64))
        XCTAssertTrue(script.contains(sudoers64))
        XCTAssertTrue(script.contains("/usr/sbin/visudo -cf"))
        XCTAssertTrue(script.contains("/etc/sudoers.d/ipglance"))
        // The temp dir is removed even when a step fails.
        XCTAssertTrue(script.contains("trap '/bin/rm -rf $T' EXIT"))
        XCTAssertFalse(script.contains(" && /bin/rm -rf $T"))
        // Root must never read files the user could have prepared.
        XCTAssertFalse(script.contains(NSHomeDirectory()))
    }
}
