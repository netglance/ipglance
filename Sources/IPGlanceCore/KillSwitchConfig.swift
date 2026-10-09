import Foundation

/// Fixed pf rules, sudoers grant and root scripts for the kill switch.
/// Everything is constant except the validated user name — nothing else user-controlled reaches root.
public enum KillSwitchConfig {
    public static let anchor = "com.apple/ipglance"
    public static let rulesPath = "/etc/pf.anchors/ipglance"
    // No dot in the name: sudo silently skips sudoers.d files containing '.'.
    public static let sudoersPath = "/etc/sudoers.d/ipglance"
    public static let pfctl = "/sbin/pfctl"

    /// Bump when `rules` changes: installed rules without this exact header are treated as stale.
    public static let rulesHeader = "# IPGlance kill switch rules v2 — managed by IPGlance, do not edit"

    // Hosts must match the provider URLs in Providers/.
    public static let rules = """
    \(rulesHeader)
    pass quick on lo0 all no state
    pass out quick inet to { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 224.0.0.0/4, 255.255.255.255 } no state
    pass out quick inet6 to { fe80::/10, ff00::/8, fc00::/7 } no state
    pass out quick proto { udp, tcp } to any port 53 no state
    pass out quick proto tcp to { ipapi.co, ipinfo.io, ipwhois.app } port 443 no state
    block drop out quick all

    """

    /// pfctl argument lists the app runs via `sudo -n`; sudoers grants exactly these.
    public static let enableArgs = ["-E"]
    public static let blockArgs = ["-a", anchor, "-f", rulesPath]
    public static let unblockArgs = ["-a", anchor, "-F", "all"]
    public static let statusArgs = ["-a", anchor, "-s", "rules"]

    public static func isValidUserName(_ user: String) -> Bool {
        // All-caps words are sudoers aliases (`ALL` would grant every user): reject them.
        user.range(of: #"\A[A-Za-z0-9_][A-Za-z0-9_.-]*\z"#, options: .regularExpression) != nil
            && user.range(of: #"\A[A-Z][A-Z0-9_]*\z"#, options: .regularExpression) == nil
    }

    /// `nil` if the user name is not safe to put into sudoers.
    public static func sudoers(user: String) -> String? {
        guard isValidUserName(user) else { return nil }
        let commands = [enableArgs, blockArgs, unblockArgs, statusArgs]
            .map { ([pfctl] + $0).joined(separator: " ") }
            .joined(separator: ", ")
        return "\(user) ALL=(root) NOPASSWD: \(commands)\n"
    }

    /// Shell script run as root. File contents travel base64-encoded inside the script,
    /// so root never copies a file the user could swap in between.
    public static func installScript(user: String) -> String? {
        guard let sudoers = sudoers(user: user) else { return nil }
        let rules64 = Data(rules.utf8).base64EncodedString()
        let sudoers64 = Data(sudoers.utf8).base64EncodedString()
        return [
            "T=$(/usr/bin/mktemp -d /tmp/ipglance.XXXXXX)",
            "trap '/bin/rm -rf $T' EXIT",
            "echo \(rules64) | /usr/bin/base64 -D > $T/rules",
            "echo \(sudoers64) | /usr/bin/base64 -D > $T/sudoers",
            "/usr/sbin/visudo -cf $T/sudoers",
            "/usr/bin/install -m 644 -o root -g wheel $T/rules \(rulesPath)",
            "/usr/bin/install -m 440 -o root -g wheel $T/sudoers \(sudoersPath)",
        ].joined(separator: " && ")  // stops at the first failure; the trap removes $T either way
    }

    public static let uninstallScript =
        "\(pfctl) -a \(anchor) -F all 2>/dev/null; /bin/rm -f \(rulesPath) \(sudoersPath)"
}
