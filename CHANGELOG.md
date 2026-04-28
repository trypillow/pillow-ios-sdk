# Changelog

All notable changes to `pillow-ios-sdk` will be documented in this file.

## [Unreleased]

## [0.1.5] - 2026-04-28

- Fix installation_id rotating on every launch when the app was force-quit (Xcode "Stop", iOS jetsam, force-quit before NSUserDefaults flushes). The SDK now treats the local SQLite installation row as the source of truth and no longer relies on a separate sentinel.
- Report the Pillow SDK version in audience telemetry instead of the host app's `CFBundleShortVersionString`.

## [0.1.4] - 2026-04-17

- Add `presentLaunchStudyIfAvailable(delegate:)` and `onReadyToPresentStudy()` to support audience-targeted launch studies.

## [0.1.3] - 2026-04-10

- Use ephemeral WKWebsiteDataStore and dedicated WKProcessPool so webview memory is fully released on dismiss.

## [0.1.2] - 2026-04-10

- Fix study presenter cleanup to prevent retain cycles and release web view resources on dismiss.

## [0.1.1] - 2026-04-10

- Initial iOS distribution scaffold for the new mobile SDK.
