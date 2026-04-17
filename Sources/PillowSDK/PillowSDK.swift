import PillowSDKCore

// MARK: - PillowSDK public API

public final class PillowSDK {
    public static let shared = PillowSDK()

    private let core = PillowSDKCore.PillowSDK.shared

    private init() {}

    /// Starts the SDK. Call once during app startup.
    public func initialize(publishableKey: String) {
        core.initialize(publishableKey: publishableKey)
    }

    /// Associates an external user ID with the current session.
    public func setExternalId(externalId: String) {
        core.setExternalId(externalId: externalId)
    }

    /// Sets a string user property.
    public func setUserProperty(key: String, stringValue: String) {
        core.setUserProperty(key: key, stringValue: stringValue)
    }

    /// Sets a boolean user property.
    public func setUserProperty(key: String, booleanValue: Bool) {
        core.setUserProperty(key: key, booleanValue: booleanValue)
    }

    /// Sets an integer user property.
    public func setUserProperty(key: String, intValue: Int32) {
        core.setUserProperty(key: key, intValue: intValue)
    }

    /// Sets a double user property.
    public func setUserProperty(key: String, doubleValue: Double) {
        core.setUserProperty(key: key, doubleValue: doubleValue)
    }

    /// Removes a single user property.
    public func clearUserProperty(key: String) {
        core.clearUserProperty(key: key)
    }

    /// Removes all user properties.
    public func clearAllProperties() {
        core.clearAllProperties()
    }

    /// Clears external ID, user properties, and rotates the anonymous identity.
    public func reset() {
        core.reset()
    }

    /// Presents a study with configurable presentation options and optional lifecycle events.
    public func present(
        study: PillowStudy,
        options: PillowStudyPresentationOptions = PillowStudyPresentationOptions(
            forceFreshSession: false,
            skipIfAlreadyExposed: false
        ),
        delegate: (any PillowStudyDelegate)? = nil
    ) {
        guard let delegate else {
            core.presentStudy(study: study, options: options, delegate: nil)
            return
        }
        let adapter = _StudyDelegateAdapter(delegate)
        core.presentStudy(study: study, options: options, delegate: adapter)
    }

    /// Presents the latest backend-provided launch study if one is currently available.
    public func presentLaunchStudyIfAvailable(
        delegate: (any PillowStudyDelegate)? = nil
    ) {
        guard let delegate else {
            core.presentLaunchStudyIfAvailable(delegate: nil)
            return
        }
        let adapter = _StudyDelegateAdapter(delegate)
        core.presentLaunchStudyIfAvailable(delegate: adapter)
    }

    /// Tells the SDK the app UI is now in a safe state for automatic study presentation.
    public func onReadyToPresentStudy() {
        core.onReadyToPresentStudy()
    }
}
