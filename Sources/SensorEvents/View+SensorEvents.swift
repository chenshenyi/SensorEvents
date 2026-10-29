import SwiftUI

extension View {
    /// 低耗電模式切換時執行 `action`（出現時先以目前的值執行一次）。
    public func onLowPowerModeChange(perform action: @escaping @MainActor (Bool) -> Void) -> some View {
        task { @MainActor in
            for await isEnabled in LowPowerModeEvents.states() {
                action(isEnabled)
            }
        }
    }

    /// 熱狀態改變時執行 `action`（出現時先以目前的值執行一次）。
    public func onThermalStateChange(perform action: @escaping @MainActor (ThermalState) -> Void) -> some View {
        task { @MainActor in
            for await state in ThermalEvents.states() {
                action(state)
            }
        }
    }
}

#if os(iOS)
extension View {
    /// 近距離狀態改變時執行 `action`（`true` 為靠近；出現時先以目前的值執行一次）。
    ///
    /// View 出現期間開啟近距離監測（被遮住時螢幕會關閉），消失時還原。
    /// 裝置沒有近距離感測器時不會執行；需要知道原因時改用 `ProximityEvents.states()`。
    public func onProximityChange(perform action: @escaping @MainActor (Bool) -> Void) -> some View {
        task { @MainActor in
            let states: AsyncStream<Bool>
            do {
                states = try ProximityEvents.states()
            } catch {
                return
            }
            for await isNear in states {
                action(isNear)
            }
        }
    }

    /// 搖晃裝置時執行 `action`。
    public func onShake(perform action: @escaping @MainActor () -> Void) -> some View {
        task { @MainActor in
            for await _ in ShakeEvents.shakes() {
                action()
            }
        }
    }

    /// 使用者截圖後執行 `action`。
    public func onScreenshot(perform action: @escaping @MainActor () -> Void) -> some View {
        task { @MainActor in
            for await _ in ScreenshotEvents.screenshots() {
                action()
            }
        }
    }

    /// 電量或充電狀態改變時執行 `action`（出現時先以目前的值執行一次）。
    public func onBatteryChange(perform action: @escaping @MainActor (BatteryStatus) -> Void) -> some View {
        task { @MainActor in
            for await status in BatteryEvents.statuses() {
                action(status)
            }
        }
    }
}
#endif
