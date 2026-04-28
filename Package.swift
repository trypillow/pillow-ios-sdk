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
            url: "https://github.com/trypillow/pillow-ios-sdk/releases/download/v0.1.5/PillowSDKCore.xcframework.zip",
            checksum: "3375bc0cb06592f0de62dc3f0b61589eac72a5d8ffb4d4c2d7f9212f355f601a"
        ),
        .target(
            name: "PillowSDK",
            dependencies: ["PillowSDKCore"],
            path: "Sources/PillowSDK",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
