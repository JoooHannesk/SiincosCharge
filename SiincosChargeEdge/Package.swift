// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SiincosChargeEdge",
    platforms: [
        .macOS(.v26),
        .custom("Linux", versionString: "6.12.34")
    ],
    dependencies: [
        .package(url: "https://github.com/3a4oT/modbus-swift.git", from: "1.0.0"),       // Apache-2.0 license
        .package(url: "https://github.com/JoooHannesk/TinyTBDeviceClient.git", from: "0.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SiincosChargeEdge",
            dependencies: [
                // For Serial RTU/ASCII:
                .product(name: "ModbusSerial", package: "modbus-swift"),
                // MQTT Client for ThingsBoard
                .product(name: "TinyTBDeviceClient", package: "TinyTBDeviceClient"),
            ],

        ),
        .testTarget(
            name: "SiincosChargeEdgeTests",
            dependencies: ["SiincosChargeEdge", ],
            path: "Tests"
        )
    ]
)
