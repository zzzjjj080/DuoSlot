// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DuoCore",
    defaultLocalization: "ja",
    platforms: [.macOS(.v14), .iOS(.v18), .watchOS(.v11)],
    products: [.library(name: "DuoCore", targets: ["DuoCore"])],
    targets: [
        .target(name: "DuoCore"),
        .testTarget(name: "DuoCoreTests", dependencies: ["DuoCore"]),
    ]
)
