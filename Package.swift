// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorMultiCamera",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorMultiCamera",
            targets: ["MultiCameraPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "MultiCameraPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/MultiCameraPlugin"),
        .testTarget(
            name: "MultiCameraPluginTests",
            dependencies: ["MultiCameraPlugin"],
            path: "ios/Tests/MultiCameraPluginTests")
    ]
)