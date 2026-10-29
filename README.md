# SensorEvents

> **English summary** — SensorEvents wraps iOS device events that SwiftUI does not support natively — proximity, shake, screenshots, battery, Low Power Mode, thermal state, and CoreMotion sensors — as Swift-concurrency-first `AsyncStream` APIs plus thin SwiftUI view modifiers (`.onShake { }`, `.onProximityChange { }` …). It is split into two products, so an app only links the frameworks it imports. Swift 6 language mode, iOS 17+, MIT licensed.

把 SwiftUI 沒有原生支援的**非觸控**裝置事件包成 Swift Concurrency 優先的 API：每個事件都是一個 `AsyncStream`，另外提供建立在 `.task` 上的 SwiftUI modifier。API 風格參考 Daniel Saidi 的 [SwiftUIKit](https://github.com/danielsaidi/SwiftUIKit)（例如 `.onShake`），但只收非觸控事件。

- Swift 6 language mode（strict concurrency），iOS 17+；macOS 14+ 可以 `swift build`／`swift test`（只有 iOS 才有的部分以 `#if os(iOS)` 排除）。
- 公開型別都是 `Sendable` 的 enum／struct；有錯誤的地方用 typed throws。
- 硬體只在有人使用 stream 的期間開啟，iteration 結束（迴圈 `break`、task 取消、stream 被釋放）時關閉。

## 安裝

```swift
.package(url: "https://github.com/chenshenyi/SensorEvents.git", from: "0.1.0")
```

依需要選擇 product：

| Product | 連結的系統框架 | 內容 |
| --- | --- | --- |
| `SensorEvents` | Foundation、UIKit、SwiftUI | 近距離感測、搖晃、截圖、電池、低耗電模式、熱狀態 |
| `MotionEvents` | Foundation、CoreMotion、SwiftUI | 加速度計、陀螺儀、高度計（氣壓）、活動、計步 |

兩個 product 共用一個內部 target `SensorEventsCore`（只用 Swift 標準函式庫，API 為 `package` 層級、不對外公開）。只 import `SensorEvents` 不會連結 CoreMotion。

## SensorEvents

| 事件 | AsyncStream | SwiftUI modifier | 平台 |
| --- | --- | --- | --- |
| 近距離感測器 | `try ProximityEvents.states()` → `AsyncStream<Bool>` | `.onProximityChange { isNear in }` | iOS |
| 搖晃 | `ShakeEvents.shakes()` → `AsyncStream<Void>` | `.onShake { }` | iOS |
| 截圖 | `ScreenshotEvents.screenshots()` → `AsyncStream<Void>` | `.onScreenshot { }` | iOS |
| 電池電量與充電狀態 | `BatteryEvents.statuses()` → `AsyncStream<BatteryStatus>` | `.onBatteryChange { status in }` | iOS |
| 低耗電模式 | `LowPowerModeEvents.states()` → `AsyncStream<Bool>` | `.onLowPowerModeChange { isOn in }` | iOS、macOS |
| 熱狀態 | `ThermalEvents.states()` → `AsyncStream<ThermalState>` | `.onThermalStateChange { state in }` | iOS、macOS |

「狀態」類的 stream（近距離、電池、低耗電、熱狀態）會先送出目前的值，之後每次改變再送出。

### 近距離感測器

```swift
import SensorEvents

// async sequence
do {
    for await isNear in try ProximityEvents.states() {   // @MainActor
        print(isNear ? "靠近" : "離開")
    }
} catch {
    // SensorError.unavailable：這台裝置沒有近距離感測器（例如 iPad）
}

// SwiftUI
Text("把手機靠近臉")
    .onProximityChange { isNear in
        print(isNear)
    }
```

- 以 `NotificationCenter.notifications(named:object:)`（async sequence）觀察 `UIDevice.proximityStateDidChangeNotification`，在 main actor 讀取 `UIDevice.proximityState`，不使用 `addObserver` 的 callback 寫法。
- `UIDevice.isProximityMonitoringEnabled` 只在 stream 存在期間開啟；多個 stream 共用參考計數，最後一個結束時還原成原本的值。
- ⚠️ **開啟監測時，感測器被遮住螢幕就會關閉**（系統行為，和通話時一樣）。只在需要時使用。
- 裝置沒有感測器時 `states()` 丟出 `SensorError.unavailable`；modifier 則不做任何事。可先用 `ProximityEvents.isAvailable` 檢查。
- iOS 26 起 UIKit 也提供 typed 的 `UIDevice.ProximityStateDidChangeMessage`，但它是 `MainActorMessage`，Foundation 只提供 `addObserver` 的 callback 形式（async 的 `messages(of:for:)` 只給 `AsyncMessage`），而且需要 iOS 26，所以這裡沒有採用。

### 搖晃

```swift
for await _ in ShakeEvents.shakes() { undo() }

Text("搖一搖").onShake { undo() }
```

實作方式與取捨：系統的 shake 是 motion event，只會沿著 responder chain 傳遞，SwiftUI 沒有對應的 API。SwiftUI App 沒有自己的 `UIWindow` 子類別，因此本套件和 SwiftUIKit 一樣在 `extension UIWindow` 覆寫 `motionEnded(_:with:)`：收到 `.motionShake` 時發出內部通知，**並呼叫 `super`** 讓事件照常往上傳（UIKit 的 `UIWindow` 本身沒有實作這個方法，覆寫不會取代系統行為，搖動以還原仍然有效）。

- 不用 method swizzling，也不需要 AppDelegate 或自訂 window。
- 取捨：只要連結了 `SensorEvents`，這個覆寫就對所有 window 生效；如果 App 或其他套件也在 extension 覆寫同一個方法，Objective-C runtime 只會採用其中一個（行為未定義）。
- 如果 responder chain 中更前面的 responder（例如自訂的 `UIViewController`）覆寫 `motionEnded` 且沒有呼叫 `super`，事件不會到達 window。
- 也可以用加速度計自行判斷搖晃（`MotionEvents`），但那不是系統定義的 shake，耗電也較高，所以沒有採用。

### 截圖

`UIApplication.userDidTakeScreenshotNotification`：截圖**完成後**才通知，無法阻止或取得截圖內容。

### 電池

`BatteryStatus` 包含 `level`（0–1，無法取得時為 `nil`）與 `state`（`.unknown`、`.unplugged`、`.charging`、`.full`）。`UIDevice.isBatteryMonitoringEnabled` 同樣只在 stream 存在期間開啟並以參考計數還原。模擬器上一律是 `.unknown`。

### 低耗電模式、熱狀態

來自 `ProcessInfo`，iOS 與 macOS 都可用。`ThermalState` 可比較大小（`.nominal < .fair < .serious < .critical`），未知的新值保守地視為 `.critical`。

## MotionEvents

需要在 Info.plist 加上 **`NSMotionUsageDescription`**（高度計、活動、計步會詢問「動作與健身」權限；加速度計與陀螺儀不需要權限）。

| 感測器 | AsyncStream | SwiftUI modifier |
| --- | --- | --- |
| 加速度計 | `try AccelerometerEvents.updates(interval:)` → `AsyncStream<Acceleration>` | `.onAccelerometerUpdate(interval:) { }` |
| 陀螺儀 | `try GyroscopeEvents.updates(interval:)` → `AsyncStream<RotationRate>` | `.onGyroscopeUpdate(interval:) { }` |
| 高度計（氣壓） | `try AltimeterEvents.updates()` → `AsyncStream<AltitudeSample>` | `.onAltitudeUpdate { }` |
| 活動（走路、跑步、開車…） | `try MotionActivityEvents.activities()` → `AsyncStream<MotionActivity>` | `.onMotionActivityChange { }` |
| 計步 | `try PedometerEvents.updates(from:)` → `AsyncStream<PedometerSample>` | `.onPedometerUpdate(from:) { }` |

```swift
import MotionEvents

do {
    for await activity in try MotionActivityEvents.activities() {
        if activity.kinds.isOnFoot, activity.confidence >= .medium { … }
    }
} catch {
    switch error {   // error 的型別是 MotionError（typed throws）
    case .unavailable: break     // 裝置不支援
    case .notAuthorized: break   // 使用者已拒絕「動作與健身」權限
    }
}
```

- 建立 stream 時檢查：裝置不支援丟出 `MotionError.unavailable`、權限已被拒丟出 `MotionError.notAuthorized`；權限尚未決定時由系統在開始時詢問。
- 執行中發生錯誤（例如使用者在詢問時拒絕）時 stream 直接結束；iOS 17 無法宣告帶 typed failure 的 `AsyncSequence`，所以不把錯誤放進 stream。
- 加速度計、陀螺儀在消費者跟不上時只保留最新一筆（`bufferingNewest(1)`）。
- 每個 stream 使用自己的 `CMMotionManager`。Apple 建議一個 App 只用一個 `CMMotionManager`，請避免同時開很多個 stream。
- 只在 iOS 編譯（CoreMotion 的這些類別在 macOS 不可用）；資料型別在 macOS 也可使用。

## 沒有收錄的事件

以 Xcode 27.1 的 iOS 27.1 SDK（`.swiftinterface` 與標頭檔）確認：

| 事件 | 原因 | 替代做法 |
| --- | --- | --- |
| 螢幕錄影／鏡像（screen captured） | SwiftUI 原生支援：`@Environment(\.isSceneCaptured)`（iOS 17+）；UIKit 也有 `UITraitCollection.sceneCaptureState`。舊的 `UIScreen.isCaptured` 已標為即將棄用 | `.onChange(of: isSceneCaptured) { }` |
| 相機控制按鈕（Camera Control） | SwiftUI 原生支援：`import AVKit` 後的 `onCameraCaptureEvent`（iOS 18+） | 直接使用 |
| 動作按鈕（Action button） | 不是 App 可以接收的事件，只能透過 App Intents／App Shortcuts 讓使用者把按鈕指派給 App 的動作 | 提供 `AppIntent` / `AppShortcutsProvider` |
| 音量鍵 | 沒有公開 API 能偵測按鍵。唯一的公開做法是以 KVO 觀察 `AVAudioSession.outputVolume`，但音量已在最大／最小時按鍵不會改變音量、偵測不到；音訊工作階段必須啟用；音量也會因為其他來源（控制中心、耳機）改變而誤判。隱藏 `MPVolumeView` 攔截按鍵屬於未公開行為。不可靠，因此不收錄 | 拍照類 App 可用 AVKit 的 `AVCaptureEventInteraction`（iOS 17.2+）或 SwiftUI 的 `onCameraCaptureEvent`（iOS 18+）在拍攝時接收音量鍵 |
| scenePhase、鍵盤 | SwiftUI 原生支援（`@Environment(\.scenePhase)`、`onKeyPress`、`@FocusState`、鍵盤 safe area） | 直接使用 |

## 授權

MIT，見 [LICENSE](LICENSE)。
