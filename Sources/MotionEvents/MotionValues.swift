import Foundation

/// 加速度（單位 g，含重力），裝置座標系。
public struct Acceleration: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public var z: Double
    /// 開機後經過的秒數（`CMLogItem.timestamp`）。
    public var timestamp: TimeInterval

    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// 向量長度（靜止時約為 1 g）。
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }
}

/// 角速度（單位 rad/s），繞裝置座標系的三個軸。
public struct RotationRate: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public var z: Double
    /// 開機後經過的秒數（`CMLogItem.timestamp`）。
    public var timestamp: TimeInterval

    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// 向量長度（rad/s）。
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }
}

/// 氣壓計的相對高度與氣壓。
public struct AltitudeSample: Sendable, Hashable {
    /// 相對於開始監測時的高度變化（公尺）。
    public var relativeAltitude: Double
    /// 氣壓（kPa）。
    public var pressure: Double
    /// 開機後經過的秒數（`CMLogItem.timestamp`）。
    public var timestamp: TimeInterval

    public init(relativeAltitude: Double, pressure: Double, timestamp: TimeInterval) {
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
        self.timestamp = timestamp
    }

    /// 氣壓（hPa，即 mbar）。
    public var pressureInHectopascals: Double {
        pressure * 10
    }
}

/// 計步器累計的資料（從開始時間到 `endDate`）。
public struct PedometerSample: Sendable, Hashable {
    public var startDate: Date
    public var endDate: Date
    public var steps: Int
    /// 距離（公尺）；裝置不支援時為 `nil`。
    public var distance: Double?
    public var floorsAscended: Int?
    public var floorsDescended: Int?
    /// 目前配速（秒／公尺）。
    public var currentPace: Double?
    /// 目前步頻（步／秒）。
    public var currentCadence: Double?

    public init(
        startDate: Date,
        endDate: Date,
        steps: Int,
        distance: Double? = nil,
        floorsAscended: Int? = nil,
        floorsDescended: Int? = nil,
        currentPace: Double? = nil,
        currentCadence: Double? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.steps = steps
        self.distance = distance
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
        self.currentPace = currentPace
        self.currentCadence = currentCadence
    }
}

extension Duration {
    /// 換算成秒數（CoreMotion 的 update interval 以秒為單位）。
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
