/// CoreMotion 感測器無法使用的原因。
public enum MotionError: Error, Sendable, Equatable {
    /// 這台裝置沒有這個感測器，或目前的平台不支援。
    case unavailable
    /// 使用者或系統拒絕了「動作與健身」權限（`NSMotionUsageDescription`）。
    case notAuthorized
}
