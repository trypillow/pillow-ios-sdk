# Pillow iOS SDK

Identify users, set properties, and present Pillow studies in your iOS app.

Shared Kotlin Multiplatform source and architecture are published separately in `https://github.com/trypillow/pillow-core-sdk`. iOS integration happens through the binary Swift Package in this repository.

## Requirements

- iOS 16+
- Xcode 15+

## Installation

Add the package in Xcode:

```text
https://github.com/trypillow/pillow-ios-sdk.git
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trypillow/pillow-ios-sdk.git", from: "0.1.0")
]
```

Then import the SDK:

```swift
import PillowSDK
```

You only need to add the Swift Package and import `PillowSDK`. Do not copy the facade source files into your app.

## Quick start

```swift
import PillowSDK

PillowSDK.shared.initialize(publishableKey: "pk_live_...")
PillowSDK.shared.setExternalId(externalId: "user_123")
PillowSDK.shared.setUserProperty(key: "plan", stringValue: "pro")
PillowSDK.shared.present(study: PillowStudy(id: "demo"))
PillowSDK.shared.present(
    study: PillowStudy(id: "demo"),
    options: PillowStudyPresentationOptions(
        forceFreshSession: false,
        skipIfAlreadyExposed: true
    )
)
```

## API reference

### `initialize(publishableKey:)`

Starts the SDK. Call once during app startup.

```swift
import PillowSDK

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

Presents a Pillow study. Resumes an in-progress session if one exists for the same study ID unless you override that behavior in `options`. Pass an optional `PillowStudyDelegate` to receive lifecycle callbacks. The delegate is held weakly, so keep your own strong reference if you need callbacks after the call returns.

```swift
// Fire and forget
PillowSDK.shared.present(study: PillowStudy(id: "demo"))

// With lifecycle delegate
PillowSDK.shared.present(study: PillowStudy(id: "demo"), delegate: myDelegate)
```

In SwiftUI, the common pattern is to retain a small coordinator object in view state and pass that object as the delegate.

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

Use `skipIfAlreadyExposed: true` to ask the backend to no-op when the current SDK user was already exposed to the same study.

### `PillowStudyDelegate`

A native Swift protocol with three lifecycle methods. All have default no-op implementations — implement only the ones you need.

| Method | Description |
|--------|-------------|
| `studyDidPresent(_:)` | The study modal appeared on screen |
| `studyDidSkip(_:)` | The study was intentionally skipped and not presented |
| `studyDidFinish(_:)` | The user finished or dismissed the study |
| `studyDidFailToLoad(_:error:)` | The study could not be loaded or presented. Access `error.localizedDescription` for the cause |

All delegate methods are invoked on the main thread.

The SDK intentionally keeps this API UIKit-style so it works in both UIKit and SwiftUI apps. In SwiftUI, prefer a retained coordinator or view model that conforms to `PillowStudyDelegate` instead of making the `View` itself the delegate.

### `reset()`

Clears the user identity and all properties, then starts a fresh anonymous session. Call on logout.

```swift
PillowSDK.shared.reset()
```

## Microphone permission

Pillow studies may use voice-based conversations that require microphone access. Add the following to your app's `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for voice-based research conversations.</string>
```

If this key is missing, the microphone button will not appear in the study. Customize the description string to match your app's tone.

## Support

Use GitHub Issues in this repository for SDK bugs, integration questions, and feature requests.

## Source layout

- `Package.swift` is the install surface for iOS apps and exposes the `PillowSDK` binary target.
- Shared Kotlin source and architecture live in `https://github.com/trypillow/pillow-core-sdk`.
