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
            url: "https://github.com/trypillow/pillow-ios-sdk/releases/download/v0.1.2/PillowSDKCore.xcframework.zip",
            checksum: "8a32dec46bf263e504bf017b1d0b47f11df7df5652edefcadfce1c7e2107bd85"
        ),
        .target(
            name: "PillowSDK",
            dependencies: ["PillowSDKCore"],
            path: "Sources/PillowSDK",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
