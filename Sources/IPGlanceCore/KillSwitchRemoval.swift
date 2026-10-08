/// Whether removing a country from the allowed list must be confirmed:
/// only when it would block the internet right away.
public enum KillSwitchRemoval {
    public static func needsConfirmation(removing code: String, current: String?,
                                         allowed: [String], killSwitchEnabled: Bool) -> Bool {
        guard killSwitchEnabled, let current, current.uppercased() == code.uppercased() else { return false }
        // Removing the last country turns the kill switch off instead of blocking.
        return allowed.count > 1
    }
}
