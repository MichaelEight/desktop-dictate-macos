// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperDictation",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", branch: "master"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "WhisperDictation",
            dependencies: ["SwiftWhisper", "HotKey"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]),
            ]
        ),
        .testTarget(
            name: "WhisperDictationTests",
            dependencies: [
                "WhisperDictation",
                "SwiftWhisper",
                "HotKey",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests"
        ),
    ]
)
