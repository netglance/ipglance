import Foundation

/// Outcome of the most recent update check.
/// Lives in IPGlanceCore so it has no Sparkle/AppKit dependency.
public enum UpdateCheckResult: Equatable, Sendable {
    case idle
    case checking
    case upToDate
    case available(version: String)
    case failed(Failure)

    public enum Failure: Equatable, Sendable {
        case network
        case signatureInvalid
        case other(message: String)
    }
}
