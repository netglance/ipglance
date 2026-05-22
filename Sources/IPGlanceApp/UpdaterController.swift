import Foundation
import Observation
import os
import Sparkle
import IPGlanceCore

/// Observable façade over Sparkle. The only file in the app target that
/// imports Sparkle — every other file binds to this controller's published
/// state. Replacing Sparkle with a custom implementation later means
/// rewriting only this file.
@MainActor
@Observable
final class UpdaterController {
    private static let logger = Logger(subsystem: "com.ipglance.app", category: "updater")

    /// Sparkle error codes (see `Sparkle/SUErrors.h`).
    private enum SparkleCode {
        static let domain = "SUSparkleErrorDomain"
        /// `SUNoUpdateError` — not actually a failure, Sparkle just reports
        /// "you're already on the latest version" through the error channel
        /// in some scheduled paths.
        static let noUpdateError = 1001
    }

    /// Whether a fresh check can be triggered right now.
    /// Reflects Sparkle's own readiness — flips to `false` while a check
    /// is in flight, back to `true` once it completes.
    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    /// Most recent check outcome, used to drive the About status line.
    private(set) var lastResult: UpdateCheckResult = .idle

    /// Last time Sparkle completed an update check, scheduled or manual.
    var lastCheckDate: Date? {
        controller.updater.lastUpdateCheckDate
    }

    /// Bridges the About-view toggle to Sparkle's persisted setting.
    var automaticChecksEnabled: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    private let controller: SPUStandardUpdaterController
    private let delegate = UpdaterDelegate()

    init() {
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        delegate.owner = self
        Self.logger.info("Sparkle updater initialized")
    }

    /// Triggers a user-initiated check. Sparkle's standard UI takes over
    /// from here (release-notes sheet, progress, install).
    func checkForUpdates() {
        lastResult = .checking
        controller.checkForUpdates(nil)
    }

    // MARK: - Delegate callbacks (called by UpdaterDelegate on the main actor)

    fileprivate func didFindValid(version: String) {
        lastResult = .available(version: version)
    }

    fileprivate func didNotFindUpdate() {
        lastResult = .upToDate
    }

    fileprivate func didAbort(error: NSError) {
        // Sparkle uses noUpdateError for "you're up to date" instead of the
        // didNotFindUpdate callback in some scheduled paths. Treat it as not
        // a failure.
        if error.domain == SparkleCode.domain && error.code == SparkleCode.noUpdateError {
            lastResult = .upToDate
            return
        }
        let failure = UpdateErrorClassifier.classify(
            domain: error.domain,
            code: error.code,
            localizedDescription: error.localizedDescription
        )
        lastResult = .failed(failure)
        Self.logger.error("Sparkle aborted: \(error.domain, privacy: .public) \(error.code) — \(error.localizedDescription, privacy: .public)")
    }
}

/// Sparkle's delegate protocol is `@objc` and not main-actor isolated, so it
/// lives in a non-isolated companion that hops to the main actor before
/// touching the controller.
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    weak var owner: UpdaterController?

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        Task { @MainActor [weak owner] in
            owner?.didFindValid(version: version)
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor [weak owner] in
            owner?.didNotFindUpdate()
        }
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        let nsError = error as NSError
        Task { @MainActor [weak owner] in
            owner?.didAbort(error: nsError)
        }
    }
}
