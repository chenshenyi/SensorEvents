import Foundation
import Testing
@testable import SensorEvents

struct BatteryStatusTests {
    @Test func negativeRawLevelMeansUnknown() {
        #expect(BatteryStatus(rawLevel: -1, state: .unknown).level == nil)
    }

    @Test func rawLevelIsKeptBetweenZeroAndOne() {
        #expect(BatteryStatus(rawLevel: 0.5, state: .charging).level == 0.5)
        #expect(BatteryStatus(rawLevel: 0, state: .unplugged).level == 0)
        #expect(BatteryStatus(rawLevel: 1.5, state: .full).level == 1)
    }
}

struct ThermalStateTests {
    @Test(arguments: [
        (ProcessInfo.ThermalState.nominal, ThermalState.nominal),
        (.fair, .fair),
        (.serious, .serious),
        (.critical, .critical),
    ])
    func mapsProcessInfoState(source: ProcessInfo.ThermalState, expected: ThermalState) {
        #expect(ThermalState(source) == expected)
    }

    @Test func isOrderedFromCoolToHot() {
        #expect(ThermalState.allCases.sorted() == [.nominal, .fair, .serious, .critical])
        #expect(ThermalState.serious > .fair)
    }
}

struct ProcessInfoEventsTests {
    @Test func thermalStatesStartWithCurrentState() async {
        var iterator = ThermalEvents.states().makeAsyncIterator()
        #expect(await iterator.next() == ThermalState(ProcessInfo.processInfo.thermalState))
    }

    @Test func lowPowerModeStatesStartWithCurrentValue() async {
        var iterator = LowPowerModeEvents.states().makeAsyncIterator()
        #expect(await iterator.next() == ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
}
