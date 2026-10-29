/// 多個使用者共用一個系統開關（例如 `UIDevice.isProximityMonitoringEnabled`）時的參考計數。
///
/// 第一個使用者開啟時記下原本的值，最後一個使用者結束時還原。
package struct SharedActivation: Sendable, Equatable {
    package private(set) var activeCount = 0
    private var originalValue = false

    package init() {}

    /// 登記一個使用者；回傳開關應設定的值（第一個使用者時為 `true`，其餘為 `nil` 表示不需變更）。
    package mutating func acquire(currentValue: Bool) -> Bool? {
        defer { activeCount += 1 }
        guard activeCount == 0 else { return nil }
        originalValue = currentValue
        return true
    }

    /// 移除一個使用者；最後一個使用者結束時回傳要還原的值，其餘回傳 `nil`。
    package mutating func release() -> Bool? {
        guard activeCount > 0 else { return nil }
        activeCount -= 1
        return activeCount == 0 ? originalValue : nil
    }
}
