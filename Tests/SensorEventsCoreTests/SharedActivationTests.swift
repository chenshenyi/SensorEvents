import Testing
@testable import SensorEventsCore

struct SharedActivationTests {
    @Test func firstAcquireEnablesAndLastReleaseRestoresOriginal() {
        var activation = SharedActivation()
        #expect(activation.acquire(currentValue: false) == true)
        #expect(activation.acquire(currentValue: true) == nil)
        #expect(activation.release() == nil)
        #expect(activation.release() == false)
        #expect(activation.activeCount == 0)
    }

    @Test func restoresEnabledWhenItWasAlreadyEnabled() {
        var activation = SharedActivation()
        #expect(activation.acquire(currentValue: true) == true)
        #expect(activation.release() == true)
    }

    @Test func releaseWithoutAcquireDoesNothing() {
        var activation = SharedActivation()
        #expect(activation.release() == nil)
        #expect(activation.activeCount == 0)
    }

    @Test func remembersOriginalValueOfEachSession() {
        var activation = SharedActivation()
        _ = activation.acquire(currentValue: true)
        _ = activation.release()
        _ = activation.acquire(currentValue: false)
        #expect(activation.release() == false)
    }
}
