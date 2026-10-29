#if os(iOS)
import Foundation
import SensorEventsCore
import UIKit

/// 使用者截圖（`UIApplication.userDidTakeScreenshotNotification`，截圖完成後才通知，無法阻止）。
public enum ScreenshotEvents {
    /// 每次截圖送出一個元素。
    public static func screenshots() -> AsyncStream<Void> {
        EventStream.make(of: Void.self) { continuation in
            let screenshots = NotificationCenter.default.notifications(
                named: UIApplication.userDidTakeScreenshotNotification
            )
            for await _ in screenshots {
                continuation.yield()
            }
        }
    }
}
#endif
