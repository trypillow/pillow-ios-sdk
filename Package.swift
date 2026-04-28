// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PillowSDK",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "PillowSDK",
            targets: ["PillowSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "PillowSDKCore",
            url: "https://github.com/trypillow/pillow-ios-sdk/releases/download/v0.1.6/PillowSDKCore.xcframework.zip",
            checksum: "537fec02f4f6e954c699957a9ce1f002e0e1c27f345d21e7d97d8b824399a121"
        ),
        .target(
            name: "PillowSDK",
            dependencies: ["PillowSDKCore"],
            path: "Sources/PillowSDK",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
