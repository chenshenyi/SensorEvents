#if os(iOS)
import Foundation
import SensorEventsCore
import UIKit

/// 近距離感測器（聽筒旁的感測器，靠近臉或被遮住時為 `true`）。
///
/// 只在有人 iterate `states()` 的期間開啟 `UIDevice.isProximityMonitoringEnabled`，
/// 最後一個使用者結束時還原成原本的值。開啟期間被遮住時系統會關閉螢幕。
public enum ProximityEvents {
    /// 這台裝置是否有近距離感測器（暫時開啟監測確認後立刻還原）。
    @MainActor
    public static var isAvailable: Bool {
        let device = UIDevice.current
        guard !device.isProximityMonitoringEnabled else { return true }
        device.isProximityMonitoringEnabled = true
        let isAvailable = device.isProximityMonitoringEnabled
        device.isProximityMonitoringEnabled = false
        return isAvailable
    }

    /// 近距離狀態的 async sequence：先送出目前的狀態，之後每次改變送出新狀態（`true` 為靠近）。
    ///
    /// - Throws: 裝置沒有近距離感測器時丟出 `SensorError.unavailable`。
    @MainActor
    public static func states() throws(SensorError) -> AsyncStream<Bool> {
        guard isAvailable else { throw .unavailable }
        return EventStream.make(of: Bool.self) { @MainActor continuation in
            let device = UIDevice.current
            if let value = ProximityMonitoring.activation.acquire(currentValue: device.isProximityMonitoringEnabled) {
                device.isProximityMonitoringEnabled = value
            }
            defer {
                if let value = ProximityMonitoring.activation.release() {
                    device.isProximityMonitoringEnabled = value
                }
            }
            continuation.yield(device.proximityState)
            let changes = NotificationCenter.default.notifications(
                named: UIDevice.proximityStateDidChangeNotification,
                object: device
            )
            for await _ in changes {
                continuation.yield(device.proximityState)
            }
        }
    }
}

/// 所有 `ProximityEvents.states()` 共用的監測開關計數。
@MainActor
private enum ProximityMonitoring {
    static var activation = SharedActivation()
}
#endif
