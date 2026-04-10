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
            url: "https://github.com/trypillow/pillow-ios-sdk/releases/download/v0.1.3/PillowSDKCore.xcframework.zip",
            checksum: "d4cac008ea946f36e8925fa69d8bf51dac1525f3c15fc3bdcc48f3ab5765ab20"
        ),
        .target(
            name: "PillowSDK",
            dependencies: ["PillowSDKCore"],
            path: "Sources/PillowSDK",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
