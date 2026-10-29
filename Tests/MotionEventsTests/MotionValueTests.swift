import Foundation
import Testing
@testable import MotionEvents

struct MotionValueTests {
    @Test func accelerationMagnitude() {
        #expect(Acceleration(x: 3, y: 4, z: 0, timestamp: 0).magnitude == 5)
    }

    @Test func rotationRateMagnitude() {
        #expect(RotationRate(x: 0, y: 0, z: -2, timestamp: 0).magnitude == 2)
    }

    @Test func pressureInHectopascals() {
        #expect(AltitudeSample(relativeAltitude: 0, pressure: 101.5, timestamp: 0).pressureInHectopascals == 1015)
    }

    @Test func durationToTimeInterval() {
        #expect(Duration.milliseconds(250).timeInterval == 0.25)
        #expect(Duration.seconds(2).timeInterval == 2)
    }
}

struct MotionActivityKindsTests {
    @Test func buildsFromFlags() {
        let kinds = MotionActivity.Kinds(stationary: true, automotive: true)
        #expect(kinds == [.stationary, .automotive])
    }

    @Test func noFlagsIsEmpty() {
        #expect(MotionActivity.Kinds().isEmpty)
    }

    @Test func onFootWhenWalkingOrRunning() {
        #expect(MotionActivity.Kinds(walking: true).isOnFoot)
        #expect(MotionActivity.Kinds(running: true).isOnFoot)
        #expect(!MotionActivity.Kinds(cycling: true).isOnFoot)
    }

    @Test func confidenceIsOrdered() {
        #expect(MotionActivity.Confidence.allCases.sorted() == [.low, .medium, .high])
    }
}
