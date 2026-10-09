import Foundation
import ServiceManagement
import os

@Observable
@MainActor
final class AppSettings {
    var showFlag: Bool = true {
        didSet { UserDefaults.standard.set(showFlag, forKey: "showFlag") }
    }
    var showCountry: Bool = true {
        didSet { UserDefaults.standard.set(showCountry, forKey: "showCountry") }
    }
    var showIP: Bool = false {
        didSet { UserDefaults.standard.set(showIP, forKey: "showIP") }
    }
    var killSwitchEnabled: Bool = false {
        didSet { UserDefaults.standard.set(killSwitchEnabled, forKey: "killSwitchEnabled") }
    }
    var allowedCountries: [String] = [] {
        didSet { UserDefaults.standard.set(allowedCountries, forKey: "allowedCountries") }
    }

    private var isSyncingAutostart = false
    var autostartEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(autostartEnabled, forKey: "autostartEnabled")
            guard !isSyncingAutostart else { return }
            applyAutostart(autostartEnabled)
        }
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "showFlag": true,
            "showCountry": true,
            "showIP": false,
            "killSwitchEnabled": false,
            "allowedCountries": [String](),
            "autostartEnabled": false,
        ])
        let d = UserDefaults.standard
        showFlag = d.bool(forKey: "showFlag")
        showCountry = d.bool(forKey: "showCountry")
        showIP = d.bool(forKey: "showIP")
        killSwitchEnabled = d.bool(forKey: "killSwitchEnabled")
        allowedCountries = d.stringArray(forKey: "allowedCountries") ?? []

        // System (Login Items) is the source of truth — the user may have
        // toggled autostart there independently of the in-app switch.
        isSyncingAutostart = true
        autostartEnabled = Self.systemAutostartIsActive()
        isSyncingAutostart = false
    }

    /// Re-reads the live SMAppService state. Call when reopening settings so
    /// the UI reflects changes the user made in System Settings → Login Items.
    func refreshAutostartFromSystem() {
        let actual = Self.systemAutostartIsActive()
        guard actual != autostartEnabled else { return }
        isSyncingAutostart = true
        autostartEnabled = actual
        isSyncingAutostart = false
    }

    private func applyAutostart(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else if service.status != .notRegistered {
                try service.unregister()
            }
        } catch {
            Logger(subsystem: "com.ipglance.app", category: "settings")
                .error("SMAppService \(enabled ? "register" : "unregister") failed: \(error.localizedDescription, privacy: .public)")
            let actual = Self.systemAutostartIsActive()
            if actual != autostartEnabled {
                isSyncingAutostart = true
                autostartEnabled = actual
                isSyncingAutostart = false
            }
        }
    }

    private static func systemAutostartIsActive() -> Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }
}
