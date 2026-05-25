// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPGlanceApp",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IPGlanceCore", targets: ["IPGlanceCore"]),
    ],
    targets: [
        .target(
            name: "IPGlanceCore",
            path: "Sources/IPGlanceCore"
        ),
        .testTarget(
            name: "IPGlanceCoreTests",
            dependencies: ["IPGlanceCore"],
            path: "Tests/IPGlanceCoreTests"
        )
    ]
)
