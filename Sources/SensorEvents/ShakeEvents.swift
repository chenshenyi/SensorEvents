#if os(iOS)
import Foundation
import SensorEventsCore
import UIKit

/// 搖晃裝置（系統的 shake 手勢，也就是「搖動以還原」用的同一個事件）。
///
/// 事件來自 `UIWindow.motionEnded(_:with:)`：本模組以 extension 覆寫它，
/// 收到 `.motionShake` 時發出通知並交回 `super`，不影響原本的 responder chain。
public enum ShakeEvents {
    /// 每次搖晃結束時送出一個元素。
    public static func shakes() -> AsyncStream<Void> {
        EventStream.make(of: Void.self) { continuation in
            for await _ in NotificationCenter.default.notifications(named: .sensorEventsDeviceDidShake) {
                continuation.yield()
            }
        }
    }
}

extension Notification.Name {
    static let sensorEventsDeviceDidShake = Notification.Name("SensorEvents.deviceDidShake")
}

extension UIWindow {
    // SwiftUI App 沒有自己的 UIWindow 子類別，只能在 extension 覆寫；
    // UIWindow 本身沒有實作這個方法（繼承自 UIResponder），呼叫 super 保留原本行為。
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .sensorEventsDeviceDidShake, object: self)
        }
        super.motionEnded(motion, with: event)
    }
}
#endif
