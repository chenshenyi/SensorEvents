/// 電池的充電狀態。
public enum BatteryState: Sendable, Hashable, CaseIterable {
    /// 無法取得（模擬器、或監測未開啟）。
    case unknown
    /// 未接電源，放電中。
    case unplugged
    /// 接上電源，充電中。
    case charging
    /// 接上電源，已充滿。
    case full
}

/// 電池的電量與充電狀態。
public struct BatteryStatus: Sendable, Hashable {
    /// 電量，0–1；無法取得時為 `nil`。
    public var level: Double?
    public var state: BatteryState

    public init(level: Double?, state: BatteryState) {
        self.level = level
        self.state = state
    }

    /// 由 `UIDevice.batteryLevel` 的原始值建立：負值（`-1`）表示無法取得。
    public init(rawLevel: Float, state: BatteryState) {
        self.init(level: rawLevel < 0 ? nil : Double(min(rawLevel, 1)), state: state)
    }
}
