# Pillow iOS SDK

Identify users, set properties, and present Pillow studies in your iOS app.

Shared Kotlin Multiplatform source and architecture are published separately in `https://github.com/trypillow/pillow-core-sdk`. iOS integration happens through the binary Swift Package in this repository.

## Requirements

- iOS 16+
- Xcode 15+

## Prerequisites

- A **publishable API key** from the [Developer section](https://app.trypillow.ai) of your dashboard
- A **study** set to live mode — copy its ID from the **Integration** tab

## Installation

In Xcode, go to **File > Add Package Dependencies** and enter the repository URL:

```text
https://github.com/trypillow/pillow-ios-sdk.git
```

Select version `0.1.3` or later, then add `PillowSDK` to your target.

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trypillow/pillow-ios-sdk.git", from: "0.1.3")
]
```

Then import the SDK:

```swift
import PillowSDK
```

You only need to add the Swift Package and import `PillowSDK`. Do not copy the facade source files into your app.

## Quick start

### 1. Initialize the SDK

Call `initialize()` once at app startup — in your `App` `init()` (SwiftUI) or `AppDelegate` (UIKit). Do not call it repeatedly from view code.

**SwiftUI:**

```swift
import SwiftUI
import PillowSDK

@main
struct MyApp: App {
    init() {
        PillowSDK.shared.initialize(publishableKey: "pk_live_...")
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**UIKit:**

```swift
import PillowSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        PillowSDK.shared.initialize(publishableKey: "pk_live_...")
        return true
    }
}
```

### 2. Identify the user

Call after login or when you know who the user is. You can also set properties to segment users in the dashboard.

```swift
PillowSDK.shared.setExternalId(externalId: "user_123")
PillowSDK.shared.setUserProperty(key: "plan", stringValue: "pro")
```

### 3. Present a study

```swift
PillowSDK.shared.present(study: PillowStudy(id: "your-study-id-here"))
```

The study opens as a modal overlay. The user can complete the conversation and dismiss it when done.

Once your app UI is ready to let Pillow present over it, call:

```swift
PillowSDK.shared.onReadyToPresentStudy()
```

After this is called for the current ready UI state, the SDK can automatically present pending backend-driven `launch_study` instructions while the app stays active and presentation-safe. Native mobile presentation stays the same; any `web_display` payload is forwarded to the hosted web experience only.

If you need to force an immediate manual check, `PillowSDK.shared.presentLaunchStudyIfAvailable()` is still available.

### 4. Enable microphone (optional)

If your study uses voice input, add the microphone usage description to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for voice-based research conversations.</string>
```

If this key is missing, the microphone button will not appear in the study.

## Full example (SwiftUI)

```swift
import SwiftUI
import PillowSDK

@main
struct MyApp: App {
    init() {
        PillowSDK.shared.initialize(publishableKey: "pk_live_...")
        PillowSDK.shared.setExternalId(externalId: "user_123")
        PillowSDK.shared.setUserProperty(key: "plan", stringValue: "pro")
    }

    var body: some Scene {
        WindowGroup { ContentView().modifier(ReadyToPresentStudyModifier()) }
    }
}

struct ContentView: View {
    @State private var coordinator: StudyCoordinator?

    var body: some View {
        Button("Start feedback") {
            let coord = StudyCoordinator()
            coordinator = coord
            PillowSDK.shared.present(
                study: PillowStudy(id: "your-study-id-here"),
                options: PillowStudyPresentationOptions(skipIfAlreadyExposed: true),
                delegate: coord
            )
        }
    }
}

private final class StudyCoordinator: PillowStudyDelegate {
    func studyDidPresent(_ study: PillowStudy) {
        print("Study presented")
    }
    func studyDidFinish(_ study: PillowStudy) {
        print("Study finished")
    }
    func studyDidFailToLoad(_ study: PillowStudy, error: Error) {
        print("Study failed: \(error.localizedDescription)")
    }
}

private struct ReadyToPresentStudyModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: scenePhase) { _, newPhase in
                notifySdkIfNeeded(for: newPhase)
            }
        } else {
            content.onChange(of: scenePhase) { newPhase in
                notifySdkIfNeeded(for: newPhase)
            }
        }
    }

    private func notifySdkIfNeeded(for phase: ScenePhase) {
        if phase == .active {
            PillowSDK.shared.onReadyToPresentStudy()
        }
    }
}
```

In SwiftUI, retain the coordinator in `@State` so it stays alive for the duration of the study. The delegate is held weakly.

## Full example (UIKit)

```swift
import UIKit
import PillowSDK

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        PillowSDK.shared.initialize(publishableKey: "pk_live_...")
        PillowSDK.shared.setExternalId(externalId: "user_123")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PillowSDK.shared.onReadyToPresentStudy()
    }

    @IBAction func startStudy() {
        PillowSDK.shared.present(
            study: PillowStudy(id: "your-study-id-here")
        )
    }
}
```

## API reference

### `initialize(publishableKey:)`

Starts the SDK. Call once during app startup — subsequent calls are ignored.

```swift
PillowSDK.shared.initialize(publishableKey: "pk_live_...")
```

### `setExternalId(externalId:)`

Identifies the current user. Call after login or when you know who the user is.

```swift
PillowSDK.shared.setExternalId(externalId: "user_123")
```

### `setUserProperty(key:...Value:)`

Sets a property on the current user. Use the typed label matching your value.

```swift
PillowSDK.shared.setUserProperty(key: "plan", stringValue: "pro")
PillowSDK.shared.setUserProperty(key: "email_verified", booleanValue: true)
PillowSDK.shared.setUserProperty(key: "login_count", intValue: 7)
PillowSDK.shared.setUserProperty(key: "lifetime_value", doubleValue: 49.5)
```

### `clearUserProperty(key:)`

Removes a property from the current user.

```swift
PillowSDK.shared.clearUserProperty(key: "plan")
```

### `clearAllProperties()`

Removes all properties from the current user.

```swift
PillowSDK.shared.clearAllProperties()
```

### `present(study:options:delegate:)`

Presents a Pillow study. Resumes an in-progress session if one exists for the same study ID unless you override that behavior in `options`. Pass an optional `PillowStudyDelegate` to receive lifecycle callbacks.

```swift
PillowSDK.shared.present(
    study: PillowStudy(id: "demo"),
    options: PillowStudyPresentationOptions(
        forceFreshSession: true,
        skipIfAlreadyExposed: true
    ),
    delegate: myDelegate
)
```

Use `forceFreshSession: true` to always start a new session.

Use `skipIfAlreadyExposed: true` to only show the study once per user.

### `onReadyToPresentStudy()`

Tells the SDK the current app UI is ready for automatic study presentation. Call it whenever the app returns to a safe UI state where Pillow is allowed to present.

```swift
PillowSDK.shared.onReadyToPresentStudy()
```

### `presentLaunchStudyIfAvailable(delegate:)`

Manually checks whether the backend returned a `launch_study` instruction for the current SDK user and presents it if available.

```swift
PillowSDK.shared.presentLaunchStudyIfAvailable()
```

The method checks asynchronously for a pending launch study instruction. If one is available, the study is presented and the delegate receives `studyDidPresent`. If the study was already shown, the delegate receives `studyDidSkip`. If no instruction is available, no delegate method is called.

Any `launch_study.web_display` payload is passed through to the hosted web experience only. It does not change the native iOS modal presentation.

### `PillowStudyDelegate`

A native Swift protocol with lifecycle methods. All have default no-op implementations — implement only the ones you need.

| Method | Description |
|--------|-------------|
| `studyDidPresent(_:)` | The study modal appeared on screen |
| `studyDidSkip(_:)` | The study was intentionally skipped and not presented |
| `studyDidFinish(_:)` | The user finished or dismissed the study |
| `studyDidFailToLoad(_:error:)` | The study could not be loaded or presented |

All delegate methods are invoked on the main thread. The delegate is held weakly — keep your own strong reference.

### `reset()`

Clears the user identity and all properties, then starts a fresh anonymous session. Call on logout.

```swift
PillowSDK.shared.reset()
```

## Documentation

Full integration guides are available at [docs.trypillow.ai/sdk](https://docs.trypillow.ai/sdk/overview).

## Source layout

- `Package.swift` is the install surface for iOS apps and exposes the `PillowSDK` binary target.
- Shared Kotlin source and architecture live in `https://github.com/trypillow/pillow-core-sdk`.

## Support

Use GitHub Issues in this repository for SDK bugs, integration questions, and feature requests.
