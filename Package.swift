// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AITestScout",
    platforms: [
        .macOS("26.0"),  // Required for Foundation Models framework
        .iOS("26.0")
    ],
    products: [
        .library(
            name: "AITestScout",
            targets: ["AITestScout"]),
    ],
    targets: [
        .target(
            name: "AITestScout",
            dependencies: []),
        .testTarget(
            name: "AITestScoutTests",
            dependencies: ["AITestScout"]),
    ]
)
