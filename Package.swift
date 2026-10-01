// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TippyTappy",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TippyTappyCore", targets: ["TippyTappyCore"]),
        .executable(name: "TippyTappy", targets: ["TippyTappy"]),
    ],
    targets: [
        // Pure logic: no AppKit UI, no CoreAudio calls at the boundary. Fully unit-tested.
        .target(
            name: "TippyTappyCore",
            path: "Sources/TippyTappyCore"),
        // The menu bar app. Thin wiring over the core.
        .executableTarget(
            name: "TippyTappy",
            dependencies: ["TippyTappyCore"],
            path: "Sources/TippyTappy",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("ServiceManagement"),
            ]),
        .testTarget(
            name: "TippyTappyCoreTests",
            dependencies: ["TippyTappyCore"],
            path: "Tests/TippyTappyCoreTests"),
    ]
)
