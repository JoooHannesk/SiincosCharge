// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SiincosChargeEdge",
    platforms: [
        .macOS(.v13),
        .custom("Linux", versionString: "6.12.34+rpt-rpi-v8")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SiincosChargeEdge"
        ),
        .testTarget(
            name: "SiincosChargeEdgeTests",
            dependencies: [],
            path: "Tests"
        )
    ]
)
