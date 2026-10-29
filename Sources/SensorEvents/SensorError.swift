/// 感測器無法使用的原因。
public enum SensorError: Error, Sendable, Equatable {
    /// 這台裝置沒有這個感測器（例如 iPad 沒有近距離感測器）。
    case unavailable
}
