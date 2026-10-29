import Foundation

/// 裝置的熱狀態，由低到高排序。
public enum ThermalState: Int, Sendable, Hashable, Comparable, CaseIterable {
    /// 正常。
    case nominal
    /// 稍高：系統可能開始降低背景工作。
    case fair
    /// 偏高：效能受限，應減少 CPU／GPU、相機、定位等工作。
    case serious
    /// 過高：應立即減少負載。
    case critical

    public static func < (lhs: ThermalState, rhs: ThermalState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 由 `ProcessInfo.ThermalState` 建立；未知的新值保守地視為 `.critical`。
    public init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .critical
        }
    }
}
