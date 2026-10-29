#if os(iOS)
import Foundation
import SensorEventsCore
import UIKit

/// 電池電量與充電狀態。
///
/// 只在有人 iterate `statuses()` 的期間開啟 `UIDevice.isBatteryMonitoringEnabled`，
/// 最後一個使用者結束時還原。模擬器上一律是 `.unknown`、電量 `nil`。
public enum BatteryEvents {
    /// 先送出目前的狀態，之後電量或充電狀態改變時送出新狀態。
    @MainActor
    public static func statuses() -> AsyncStream<BatteryStatus> {
        EventStream.make(of: BatteryStatus.self) { @MainActor continuation in
            let device = UIDevice.current
            if let value = BatteryMonitoring.activation.acquire(currentValue: device.isBatteryMonitoringEnabled) {
                device.isBatteryMonitoringEnabled = value
            }
            defer {
                if let value = BatteryMonitoring.activation.release() {
                    device.isBatteryMonitoringEnabled = value
                }
            }
            continuation.yield(device.batteryStatus)
            // 兩個通知各自 iterate：充電狀態在另一個 task，電量在這裡，結束時一併取消
            let stateChanges = Task { @MainActor in
                let changes = NotificationCenter.default.notifications(
                    named: UIDevice.batteryStateDidChangeNotification,
                    object: device
                )
                for await _ in changes {
                    continuation.yield(device.batteryStatus)
                }
            }
            defer { stateChanges.cancel() }
            let levelChanges = NotificationCenter.default.notifications(
                named: UIDevice.batteryLevelDidChangeNotification,
                object: device
            )
            for await _ in levelChanges {
                continuation.yield(device.batteryStatus)
            }
        }
    }
}

/// 所有 `BatteryEvents.statuses()` 共用的監測開關計數。
@MainActor
private enum BatteryMonitoring {
    static var activation = SharedActivation()
}

extension UIDevice {
    fileprivate var batteryStatus: BatteryStatus {
        BatteryStatus(rawLevel: batteryLevel, state: .init(batteryState))
    }
}

extension BatteryState {
    init(_ state: UIDevice.BatteryState) {
        switch state {
        case .unknown: self = .unknown
        case .unplugged: self = .unplugged
        case .charging: self = .charging
        case .full: self = .full
        @unknown default: self = .unknown
        }
    }
}
#endif
