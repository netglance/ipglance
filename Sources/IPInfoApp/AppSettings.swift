import Foundation

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
    // Seconds: 30, 60, 300, 0=manual
    var updateInterval: Int = 60 {
        didSet { UserDefaults.standard.set(updateInterval, forKey: "updateInterval") }
    }
    var autostartEnabled: Bool = false {
        didSet { UserDefaults.standard.set(autostartEnabled, forKey: "autostartEnabled") }
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "showFlag": true,
            "showCountry": true,
            "showIP": false,
            "updateInterval": 60,
            "autostartEnabled": false,
        ])
        let d = UserDefaults.standard
        showFlag = d.bool(forKey: "showFlag")
        showCountry = d.bool(forKey: "showCountry")
        showIP = d.bool(forKey: "showIP")
        updateInterval = d.integer(forKey: "updateInterval")
        autostartEnabled = d.bool(forKey: "autostartEnabled")
    }
}
