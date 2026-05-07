// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPInfoApp",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "IPInfoCore",
            path: "Sources/IPInfoCore"
        ),
        .executableTarget(
            name: "IPInfoApp",
            dependencies: ["IPInfoCore"],
            path: "Sources/IPInfoApp"
        ),
        .testTarget(
            name: "IPInfoCoreTests",
            dependencies: ["IPInfoCore"],
            path: "Tests/IPInfoCoreTests"
        )
    ]
)
