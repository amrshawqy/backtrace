// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Backtrace",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Backtrace", targets: ["Backtrace"])
    ],
    targets: [
        .executableTarget(
            name: "Backtrace",
            path: "Sources/Backtrace"
        ),
        .testTarget(
            name: "BacktraceTests",
            dependencies: ["Backtrace"],
            path: "Tests/BacktraceTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
