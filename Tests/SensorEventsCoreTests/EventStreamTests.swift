import Testing
@testable import SensorEventsCore

@Suite(.timeLimit(.minutes(1)))
struct EventStreamTests {
    @Test func yieldsProducedElementsThenFinishes() async {
        let stream = EventStream.make(of: Int.self) { continuation in
            for value in 1 ... 3 {
                continuation.yield(value)
            }
        }
        var received: [Int] = []
        for await value in stream {
            received.append(value)
        }
        #expect(received == [1, 2, 3])
    }

    @Test func stoppingIterationCancelsProducer() async {
        let (cleanups, cleanupContinuation) = AsyncStream<Void>.makeStream()
        // stream 只被 for-in 持有，break 後釋放，視為 iteration 結束
        for await _ in EventStream.make(of: Int.self, { continuation in
            continuation.yield(1)
            await waitUntilCancelled()
            cleanupContinuation.yield()
            cleanupContinuation.finish()
        }) {
            break
        }
        var cleanupCount = 0
        for await _ in cleanups {
            cleanupCount += 1
        }
        #expect(cleanupCount == 1)
    }

    @Test func cancellingConsumerTaskCancelsProducer() async {
        let (cleanups, cleanupContinuation) = AsyncStream<Void>.makeStream()
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()
        let consumer = Task {
            let stream = EventStream.make(of: Int.self) { _ in
                startedContinuation.finish()
                await waitUntilCancelled()
                cleanupContinuation.finish()
            }
            for await _ in stream {}
        }
        for await _ in started {}
        consumer.cancel()
        for await _ in cleanups {}
        await consumer.value
    }

    @Test func waitUntilCancelledReturnsAfterCancellation() async {
        let task = Task { await waitUntilCancelled() }
        task.cancel()
        await task.value
    }
}
