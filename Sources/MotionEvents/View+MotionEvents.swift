#if os(iOS)
import Foundation
import SwiftUI

extension View {
    /// 以 `interval` 的間隔收到加速度時執行 `action`。裝置沒有加速度計時不會執行。
    public func onAccelerometerUpdate(
        interval: Duration = .milliseconds(100),
        perform action: @escaping @MainActor (Acceleration) -> Void
    ) -> some View {
        observe(id: interval, { () throws(MotionError) in try AccelerometerEvents.updates(interval: interval) }, perform: action)
    }

    /// 以 `interval` 的間隔收到角速度時執行 `action`。裝置沒有陀螺儀時不會執行。
    public func onGyroscopeUpdate(
        interval: Duration = .milliseconds(100),
        perform action: @escaping @MainActor (RotationRate) -> Void
    ) -> some View {
        observe(id: interval, { () throws(MotionError) in try GyroscopeEvents.updates(interval: interval) }, perform: action)
    }

    /// 收到相對高度與氣壓時執行 `action`。沒有氣壓計或沒有權限時不會執行。
    public func onAltitudeUpdate(perform action: @escaping @MainActor (AltitudeSample) -> Void) -> some View {
        observe(id: 0, { () throws(MotionError) in try AltimeterEvents.updates() }, perform: action)
    }

    /// 活動（走路、跑步、開車…）改變時執行 `action`。不支援或沒有權限時不會執行。
    public func onMotionActivityChange(perform action: @escaping @MainActor (MotionActivity) -> Void) -> some View {
        observe(id: 0, { () throws(MotionError) in try MotionActivityEvents.activities() }, perform: action)
    }

    /// 收到從 `start` 起累計的計步資料時執行 `action`。不支援或沒有權限時不會執行。
    public func onPedometerUpdate(
        from start: Date,
        perform action: @escaping @MainActor (PedometerSample) -> Void
    ) -> some View {
        observe(id: start, { () throws(MotionError) in try PedometerEvents.updates(from: start) }, perform: action)
    }

    /// View 出現期間 iterate `makeStream` 建立的 stream；`id` 改變時重新開始，無法建立時不做事。
    private func observe<ID: Equatable & Sendable, Element: Sendable>(
        id: ID,
        _ makeStream: @escaping @Sendable () throws(MotionError) -> AsyncStream<Element>,
        perform action: @escaping @MainActor (Element) -> Void
    ) -> some View {
        task(id: id) { @MainActor in
            let stream: AsyncStream<Element>
            do {
                stream = try makeStream()
            } catch {
                return
            }
            for await element in stream {
                action(element)
            }
        }
    }
}
#endif
