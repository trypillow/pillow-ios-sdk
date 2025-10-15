# Pillow iOS SDK

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/trypillow/pillow-ios-sdk/releases)
[![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-4BC51D.svg)](https://cocoapods.org/pods/PillowSDK)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

The Pillow iOS SDK provides iOS support for Pillow campaigns.

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trypillow/pillow-ios-sdk.git", from: "1.0.0")
]
```

Or in Xcode:

1. Go to `File > Add Package Dependencies...`
2. Enter the repository URL: `https://github.com/trypillow/pillow-ios-sdk.git`
3. Select the version or branch
4. Click "Add Package"

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'PillowSDK', '~> 1.0.1'
```

Then run:

```bash
pod install
```

## Quick Start

### 1. Import the SDK

```swift
import PillowSDK
```

### 2. Configure the SDK

Configure the SDK with your Pillow campaign url, typically in your `AppDelegate` or `@main` App struct:

```swift
import SwiftUI
import PillowSDK

@main
struct YourApp: App {
    init() {
        do {
            try PillowSDK.shared.configure(
                url: "YOUR_CAMPAIGN_URL",
                logLevel: .info,
                bannerDismissDelay: 5.0
            )
        } catch {
            print("Failed to configure PillowSDK: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Present the Chat Interface

```swift
import SwiftUI
import PillowSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Talk with us") {
                do {
                    try PillowSDK.shared.present()
                } catch {
                    print("Failed to present chat: \(error)")
                }
            }
        }
    }
}
```

## API Reference

### Configuration

#### `configure(url:logLevel:bannerDismissDelay:)`

Configures the SDK with your Pillow campaign url and options.

```swift
try PillowSDK.shared.configure(
    url: "YOUR_CAMPAIGN_URL",
    logLevel: .info,              // .debug, .info, .warning, .error
    bannerDismissDelay: 5.0       // Auto-dismiss time in seconds
)
```

**Parameters:**
- `url`: The URL for your Pillow campaign
- `logLevel`: Logging level (default: `.info`)
- `bannerDismissDelay`: Auto-dismiss time for banners in seconds (default: `5.0`)

**Throws:**
- `PillowSDKError.invalidURL` - If the URL is malformed

### Presentation

#### `present()`

Presents the Pillow chat interface in a full-screen modal.

```swift
try PillowSDK.shared.present()
```

**Throws:**
- `PillowSDKError.notConfigured` - If the SDK hasn't been configured
- `PillowSDKError.noRootViewController` - If no root view controller is available
- `PillowSDKError.unsupportedPlatform` - If running on an unsupported platform

### Properties

#### `version`

The current SDK version.

```swift
let version = PillowSDK.shared.version
print("SDK Version: \(version)") // "1.0.0"
```

#### `logLevel`

The current logging level. Can be changed at runtime.

```swift
PillowSDK.shared.logLevel = .debug
```

#### `bannerDismissDelay`

The auto-dismiss delay for message banners. Can be changed at runtime.

```swift
PillowSDK.shared.bannerDismissDelay = 3.0
```

## Error Handling

The SDK provides a `PillowSDKError` enum with the following cases:

- `notConfigured` - SDK hasn't been configured with a URL
- `invalidURL` - The provided URL is invalid
- `noRootViewController` - No root view controller available for presentation
- `unsupportedPlatform` - Platform is not supported (macOS, etc.)

## Requirements

- iOS 16.0 or later
- Swift 5.9 or later
- Xcode 15.0 or later

## License

PillowSDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Support

For issues, feature requests, or questions:
- 📧 Email: hi@trypillow.ai
- 🐛 Issues: [GitHub Issues](https://github.com/trypillow/pillow-ios-sdk/issues)








