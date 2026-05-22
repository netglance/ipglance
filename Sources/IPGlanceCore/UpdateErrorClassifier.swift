import Foundation

/// Maps Sparkle-style `NSError`s onto our `UpdateCheckResult.Failure`.
///
/// Implemented as a pure function over `(domain, code, localizedDescription)`
/// so that IPGlanceCore stays Sparkle-free. The numeric codes correspond to
/// constants in Sparkle 2's `SUErrors.h` (`SUSignatureError = 3001`,
/// appcast/download family `1000`, `2000`, `2001`, `2002`).
public enum UpdateErrorClassifier {
    public static func classify(
        domain: String,
        code: Int,
        localizedDescription: String
    ) -> UpdateCheckResult.Failure {
        guard domain == "SUSparkleErrorDomain" else {
            return .other(message: localizedDescription)
        }
        switch code {
        case 3001:
            return .signatureInvalid
        case 1000, 2000, 2001, 2002:
            return .network
        default:
            return .other(message: localizedDescription)
        }
    }
}
