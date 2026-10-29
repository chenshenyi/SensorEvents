/// 以一個 task 產生元素的 `AsyncStream`。
///
/// `produce` 在 stream 建立時開始執行，iteration 結束（迴圈 `break`、所在的 task 被取消、
/// stream 被釋放）時取消；`produce` 回傳後 stream 結束。硬體資源在 `produce` 裡開啟、
/// 在它回傳前關閉，所以資源只在有人使用 stream 的期間開啟。
package enum EventStream {
    package static func make<Element: Sendable>(
        of _: Element.Type = Element.self,
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        _ produce: @escaping @Sendable (AsyncStream<Element>.Continuation) async -> Void
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let task = Task {
                await produce(continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// 暫停直到目前的 task 被取消。
package func waitUntilCancelled() async {
    let (stream, continuation) = AsyncStream<Never>.makeStream()
    await withTaskCancellationHandler {
        for await _ in stream {}
    } onCancel: {
        continuation.finish()
    }
}
