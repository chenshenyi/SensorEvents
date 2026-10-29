import Foundation
import SensorEventsCore

/// 低耗電模式（`ProcessInfo.isLowPowerModeEnabled`），iOS 與 macOS 都可使用。
public enum LowPowerModeEvents {
    /// 先送出目前是否開啟，之後每次切換送出新值。
    public static func states() -> AsyncStream<Bool> {
        EventStream.make(of: Bool.self) { continuation in
            let processInfo = ProcessInfo.processInfo
            continuation.yield(processInfo.isLowPowerModeEnabled)
            let changes = NotificationCenter.default.notifications(named: .NSProcessInfoPowerStateDidChange)
            for await _ in changes {
                continuation.yield(processInfo.isLowPowerModeEnabled)
            }
        }
    }
}
