import Foundation

/// 動作協同處理器判斷的活動（`CMMotionActivity`）。
public struct MotionActivity: Sendable, Hashable {
    /// 活動種類；可能同時有多個（例如開車時停下：`automotive` 與 `stationary`），也可能都沒有。
    public struct Kinds: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let stationary = Kinds(rawValue: 1 << 0)
        public static let walking = Kinds(rawValue: 1 << 1)
        public static let running = Kinds(rawValue: 1 << 2)
        public static let automotive = Kinds(rawValue: 1 << 3)
        public static let cycling = Kinds(rawValue: 1 << 4)
        public static let unknown = Kinds(rawValue: 1 << 5)

        /// 由 `CMMotionActivity` 的各個旗標建立。
        public init(
            stationary: Bool = false,
            walking: Bool = false,
            running: Bool = false,
            automotive: Bool = false,
            cycling: Bool = false,
            unknown: Bool = false
        ) {
            let flags: [(Bool, Kinds)] = [
                (stationary, .stationary),
                (walking, .walking),
                (running, .running),
                (automotive, .automotive),
                (cycling, .cycling),
                (unknown, .unknown),
            ]
            self = flags.reduce(into: []) { kinds, flag in
                if flag.0 { kinds.insert(flag.1) }
            }
        }

        /// 是否正在用腳移動（走路或跑步）。
        public var isOnFoot: Bool {
            !isDisjoint(with: [.walking, .running])
        }
    }

    /// 判斷的可信度。
    public enum Confidence: Int, Sendable, Hashable, Comparable, CaseIterable {
        case low
        case medium
        case high

        public static func < (lhs: Confidence, rhs: Confidence) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public var kinds: Kinds
    public var confidence: Confidence
    public var startDate: Date

    public init(kinds: Kinds, confidence: Confidence, startDate: Date) {
        self.kinds = kinds
        self.confidence = confidence
        self.startDate = startDate
    }
}
