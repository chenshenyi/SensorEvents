#if os(iOS)
import CoreMotion
import Foundation
import SensorEventsCore

/// 加速度計（`CMMotionManager`）。
///
/// 每個 stream 使用自己的 `CMMotionManager`，iteration 結束時停止更新。
/// Apple 建議一個 App 只用一個 `CMMotionManager`，請避免同時開很多個 stream。
public enum AccelerometerEvents {
    public static var isAvailable: Bool {
        CMMotionManager().isAccelerometerAvailable
    }

    /// 以 `interval` 的間隔送出加速度；消費者跟不上時只保留最新一筆。
    ///
    /// - Throws: 裝置沒有加速度計時丟出 `MotionError.unavailable`。
    public static func updates(interval: Duration = .milliseconds(100)) throws(MotionError) -> AsyncStream<Acceleration> {
        guard isAvailable else { throw .unavailable }
        let seconds = interval.timeInterval
        return EventStream.make(of: Acceleration.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            let manager = CMMotionManager()
            manager.accelerometerUpdateInterval = seconds
            manager.startAccelerometerUpdates(to: OperationQueue()) { @Sendable data, error in
                guard let data else {
                    if error != nil { continuation.finish() }
                    return
                }
                let value = data.acceleration
                continuation.yield(Acceleration(x: value.x, y: value.y, z: value.z, timestamp: data.timestamp))
            }
            await waitUntilCancelled()
            manager.stopAccelerometerUpdates()
        }
    }
}

/// 陀螺儀（`CMMotionManager`）。
///
/// 每個 stream 使用自己的 `CMMotionManager`，iteration 結束時停止更新。
public enum GyroscopeEvents {
    public static var isAvailable: Bool {
        CMMotionManager().isGyroAvailable
    }

    /// 以 `interval` 的間隔送出未經校正的角速度；消費者跟不上時只保留最新一筆。
    ///
    /// - Throws: 裝置沒有陀螺儀時丟出 `MotionError.unavailable`。
    public static func updates(interval: Duration = .milliseconds(100)) throws(MotionError) -> AsyncStream<RotationRate> {
        guard isAvailable else { throw .unavailable }
        let seconds = interval.timeInterval
        return EventStream.make(of: RotationRate.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            let manager = CMMotionManager()
            manager.gyroUpdateInterval = seconds
            manager.startGyroUpdates(to: OperationQueue()) { @Sendable data, error in
                guard let data else {
                    if error != nil { continuation.finish() }
                    return
                }
                let value = data.rotationRate
                continuation.yield(RotationRate(x: value.x, y: value.y, z: value.z, timestamp: data.timestamp))
            }
            await waitUntilCancelled()
            manager.stopGyroUpdates()
        }
    }
}

/// 氣壓計的相對高度（`CMAltimeter`），需要 `NSMotionUsageDescription`。
public enum AltimeterEvents {
    public static var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    /// 送出相對於開始時的高度變化與氣壓（約每秒一次）；權限被拒時 stream 結束。
    ///
    /// - Throws: 沒有氣壓計時丟出 `.unavailable`；權限已被拒時丟出 `.notAuthorized`。
    public static func updates() throws(MotionError) -> AsyncStream<AltitudeSample> {
        guard isAvailable else { throw .unavailable }
        try MotionError.check(CMAltimeter.authorizationStatus())
        return EventStream.make(of: AltitudeSample.self) { continuation in
            let altimeter = CMAltimeter()
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue()) { @Sendable data, error in
                guard let data else {
                    if error != nil { continuation.finish() }
                    return
                }
                continuation.yield(
                    AltitudeSample(
                        relativeAltitude: data.relativeAltitude.doubleValue,
                        pressure: data.pressure.doubleValue,
                        timestamp: data.timestamp
                    )
                )
            }
            await waitUntilCancelled()
            altimeter.stopRelativeAltitudeUpdates()
        }
    }
}

/// 走路、跑步、開車等活動（`CMMotionActivityManager`），需要 `NSMotionUsageDescription`。
public enum MotionActivityEvents {
    public static var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    /// 先送出目前的活動，之後活動改變時送出新值。
    ///
    /// - Throws: 裝置不支援時丟出 `.unavailable`；權限已被拒時丟出 `.notAuthorized`。
    public static func activities() throws(MotionError) -> AsyncStream<MotionActivity> {
        guard isAvailable else { throw .unavailable }
        try MotionError.check(CMMotionActivityManager.authorizationStatus())
        return EventStream.make(of: MotionActivity.self) { continuation in
            let manager = CMMotionActivityManager()
            manager.startActivityUpdates(to: OperationQueue()) { @Sendable activity in
                guard let activity else { return }
                continuation.yield(MotionActivity(activity))
            }
            await waitUntilCancelled()
            manager.stopActivityUpdates()
        }
    }
}

/// 計步器（`CMPedometer`），需要 `NSMotionUsageDescription`。
public enum PedometerEvents {
    public static var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    /// 送出從 `start` 起累計的步數等資料（系統決定更新頻率）；權限被拒時 stream 結束。
    ///
    /// - Throws: 裝置不支援計步時丟出 `.unavailable`；權限已被拒時丟出 `.notAuthorized`。
    public static func updates(from start: Date) throws(MotionError) -> AsyncStream<PedometerSample> {
        guard isAvailable else { throw .unavailable }
        try MotionError.check(CMPedometer.authorizationStatus())
        return EventStream.make(of: PedometerSample.self) { continuation in
            let pedometer = CMPedometer()
            pedometer.startUpdates(from: start) { @Sendable data, error in
                guard let data else {
                    if error != nil { continuation.finish() }
                    return
                }
                continuation.yield(PedometerSample(data))
            }
            await waitUntilCancelled()
            pedometer.stopUpdates()
        }
    }
}

extension MotionError {
    /// 已被拒絕的權限在開始前就丟出錯誤；尚未決定時交給系統在開始時詢問。
    static func check(_ status: CMAuthorizationStatus) throws(MotionError) {
        switch status {
        case .denied, .restricted:
            throw .notAuthorized
        case .notDetermined, .authorized:
            return
        @unknown default:
            return
        }
    }
}

extension MotionActivity {
    init(_ activity: CMMotionActivity) {
        self.init(
            kinds: Kinds(
                stationary: activity.stationary,
                walking: activity.walking,
                running: activity.running,
                automotive: activity.automotive,
                cycling: activity.cycling,
                unknown: activity.unknown
            ),
            confidence: Confidence(activity.confidence),
            startDate: activity.startDate
        )
    }
}

extension MotionActivity.Confidence {
    init(_ confidence: CMMotionActivityConfidence) {
        switch confidence {
        case .low: self = .low
        case .medium: self = .medium
        case .high: self = .high
        @unknown default: self = .low
        }
    }
}

extension PedometerSample {
    init(_ data: CMPedometerData) {
        self.init(
            startDate: data.startDate,
            endDate: data.endDate,
            steps: data.numberOfSteps.intValue,
            distance: data.distance?.doubleValue,
            floorsAscended: data.floorsAscended?.intValue,
            floorsDescended: data.floorsDescended?.intValue,
            currentPace: data.currentPace?.doubleValue,
            currentCadence: data.currentCadence?.doubleValue
        )
    }
}
#endif
