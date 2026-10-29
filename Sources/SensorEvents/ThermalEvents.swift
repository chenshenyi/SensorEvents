import Foundation
import SensorEventsCore

/// 裝置的熱狀態（`ProcessInfo.thermalState`），iOS 與 macOS 都可使用。
public enum ThermalEvents {
    /// 先送出目前的熱狀態，之後每次改變送出新值。
    public static func states() -> AsyncStream<ThermalState> {
        EventStream.make(of: ThermalState.self) { continuation in
            let processInfo = ProcessInfo.processInfo
            continuation.yield(ThermalState(processInfo.thermalState))
            let changes = NotificationCenter.default.notifications(named: ProcessInfo.thermalStateDidChangeNotification)
            for await _ in changes {
                continuation.yield(ThermalState(processInfo.thermalState))
            }
        }
    }
}
