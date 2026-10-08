public enum KillSwitchAction: Equatable, Sendable {
    case block, unblock, none
}

/// Decides what the kill switch should do after an IP check.
public enum KillSwitchPolicy {
    /// - Parameters:
    ///   - country: ISO code from the latest check, `nil` if the check failed (fail-open).
    ///   - allowed: ISO codes the user allows; an empty list never blocks.
    ///   - isBlocked: whether the pf block is currently loaded.
    public static func action(country: String?, allowed: Set<String>, isBlocked: Bool) -> KillSwitchAction {
        guard let country else { return .none }
        let allowedUpper = Set(allowed.map { $0.uppercased() })
        let isAllowed = allowedUpper.isEmpty || allowedUpper.contains(country.uppercased())
        if isAllowed { return isBlocked ? .unblock : .none }
        return isBlocked ? .none : .block
    }
}
