// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SensorEvents",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // UIKit + Foundation + SwiftUI：近距離感測、搖晃、截圖、電池、低耗電模式、熱狀態
        .library(name: "SensorEvents", targets: ["SensorEvents"]),
        // CoreMotion + SwiftUI：加速度計、陀螺儀、高度計、活動、計步
        .library(name: "MotionEvents", targets: ["MotionEvents"]),
    ],
    targets: [
        // 只用 Swift 標準函式庫的共用工具（package 層級可見，不對外公開）
        .target(name: "SensorEventsCore"),
        .target(name: "SensorEvents", dependencies: ["SensorEventsCore"]),
        .target(name: "MotionEvents", dependencies: ["SensorEventsCore"]),
        .testTarget(name: "SensorEventsCoreTests", dependencies: ["SensorEventsCore"]),
        .testTarget(name: "SensorEventsTests", dependencies: ["SensorEvents"]),
        .testTarget(name: "MotionEventsTests", dependencies: ["MotionEvents"]),
    ],
    swiftLanguageModes: [.v6]
)
