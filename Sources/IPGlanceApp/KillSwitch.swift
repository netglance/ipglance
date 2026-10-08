import Foundation
import IPGlanceCore

enum KillSwitchError: LocalizedError {
    case cancelled
    case invalidUser
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return nil
        case .invalidUser: return "Unsupported user name for sudoers"
        case .commandFailed(let message): return message
        }
    }
}

/// Runs the fixed pf commands from `KillSwitchConfig`.
/// `install()` asks for the admin password once; block/unblock then go through `sudo -n`.
enum KillSwitch {
    static var isInstalled: Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: KillSwitchConfig.rulesPath)
            && fm.fileExists(atPath: KillSwitchConfig.sudoersPath)
    }

    static func install() async throws {
        guard let script = KillSwitchConfig.installScript(user: NSUserName()) else {
            throw KillSwitchError.invalidUser
        }
        try await runAsAdmin(script)
    }

    static func uninstall() async throws {
        try await runAsAdmin(KillSwitchConfig.uninstallScript)
    }

    static func block() async throws {
        try await sudo(KillSwitchConfig.enableArgs)
        try await sudo(KillSwitchConfig.blockArgs)
    }

    static func unblock() async throws {
        try await sudo(KillSwitchConfig.unblockArgs)
    }

    /// `false` when rules are not installed or sudo fails.
    static func isBlocked() async -> Bool {
        guard isInstalled else { return false }
        let output = (try? await sudo(KillSwitchConfig.statusArgs)) ?? ""
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    private static func sudo(_ args: [String]) async throws -> String {
        try await run("/usr/bin/sudo", ["-n", KillSwitchConfig.pfctl] + args)
    }

    private static func runAsAdmin(_ script: String) async throws {
        let escaped = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        do {
            try await run("/usr/bin/osascript",
                          ["-e", "do shell script \"\(escaped)\" with administrator privileges"])
        } catch KillSwitchError.commandFailed(let message) where message.contains("-128") {
            throw KillSwitchError.cancelled  // user pressed Cancel in the password dialog
        }
    }

    // ponytail: reads stdout, then stderr — fine for pfctl/osascript's tiny output;
    // switch to readabilityHandler if a command ever writes >64 KB to stderr.
    @discardableResult
    private static func run(_ path: String, _ args: [String]) async throws -> String {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            let out = Pipe(), err = Pipe()
            process.standardOutput = out
            process.standardError = err
            try process.run()
            let outData = out.fileHandleForReading.readDataToEndOfFile()
            let errData = err.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw KillSwitchError.commandFailed(String(decoding: errData, as: UTF8.self))
            }
            return String(decoding: outData, as: UTF8.self)
        }.value
    }
}
