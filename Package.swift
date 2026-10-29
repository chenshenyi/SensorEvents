// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SensorEvents",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
    ],
    targets: [
        // 只用 Swift 標準函式庫的共用工具（package 層級可見，不對外公開）
        .target(name: "SensorEventsCore"),
        .testTarget(name: "SensorEventsCoreTests", dependencies: ["SensorEventsCore"]),
    ],
    swiftLanguageModes: [.v6]
)
