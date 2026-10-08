public enum KillSwitchAction: Equatable, Sendable {
    case block, unblock, resume, none
}

/// Decides what the kill switch should do after an IP check.
public enum KillSwitchPolicy {
    /// - Parameters:
    ///   - country: ISO code from the latest check, `nil` if the check failed (fail-open).
    ///   - allowed: ISO codes the user allows; an empty list never blocks.
    ///   - isBlocked: whether the pf block is currently loaded.
    ///   - isPaused: the user unblocked manually; foreign countries don't block until an allowed one is seen (`.resume`).
    public static func action(country: String?, allowed: Set<String>, isBlocked: Bool, isPaused: Bool = false) -> KillSwitchAction {
        guard let country else { return .none }
        let allowedUpper = Set(allowed.map { $0.uppercased() })
        let isAllowed = allowedUpper.isEmpty || allowedUpper.contains(country.uppercased())
        if isPaused { return isAllowed ? .resume : .none }
        if isAllowed { return isBlocked ? .unblock : .none }
        return isBlocked ? .none : .block
    }
}
