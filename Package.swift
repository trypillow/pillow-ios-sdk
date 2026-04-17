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
            url: "https://github.com/trypillow/pillow-ios-sdk/releases/download/v0.1.4/PillowSDKCore.xcframework.zip",
            checksum: "b2027e697442163240eba908496e0b7ae52aaf08cfa985f47de1b308305258fb"
        ),
        .target(
            name: "PillowSDK",
            dependencies: ["PillowSDKCore"],
            path: "Sources/PillowSDK",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
