import PillowSDKCore

// MARK: - PillowStudyDelegate

/// Delegate protocol for monitoring study presentation lifecycle.
///
/// Implement the methods you need — all have default no-op implementations.
/// Delegate methods are always called on the main thread.
public protocol PillowStudyDelegate: AnyObject {
    /// Called when the study modal appears on screen.
    func studyDidPresent(_ study: PillowStudy)
    /// Called when the study is intentionally skipped and not presented.
    func studyDidSkip(_ study: PillowStudy)
    /// Called when the user finishes or dismisses the study.
    func studyDidFinish(_ study: PillowStudy)
    /// Called when the study could not be loaded or presented.
    func studyDidFailToLoad(_ study: PillowStudy, error: Error)
}

public extension PillowStudyDelegate {
    func studyDidPresent(_ study: PillowStudy) {}
    func studyDidSkip(_ study: PillowStudy) {}
    func studyDidFinish(_ study: PillowStudy) {}
    func studyDidFailToLoad(_ study: PillowStudy, error: Error) {}
}

// MARK: - Internal adapter

/// Bridges the native Swift ``PillowStudyDelegate`` protocol to the
/// Kotlin `PillowStudyDelegateProtocol` interface expected by the core binary.
internal final class _StudyDelegateAdapter: PillowStudyDelegateProtocol {
    private weak var delegate: (any PillowStudyDelegate)?

    init(_ delegate: any PillowStudyDelegate) {
        self.delegate = delegate
    }

    func studyDidPresent(study: PillowStudy) {
        delegate?.studyDidPresent(study)
    }

    func studyDidSkip(study: PillowStudy) {
        delegate?.studyDidSkip(study)
    }

    func studyDidFinish(study: PillowStudy) {
        delegate?.studyDidFinish(study)
    }

    func studyDidFailToLoad(study: PillowStudy, error: KotlinThrowable) {
        let swiftError = NSError(
            domain: "PillowSDK",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: error.message ?? "Unknown error"]
        )
        delegate?.studyDidFailToLoad(study, error: swiftError)
    }
}
