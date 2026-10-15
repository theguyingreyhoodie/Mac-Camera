import Testing
@testable import Camera

@MainActor
struct CountdownControllerTests {
    private func makeController(_ duration: CountdownDuration) -> (CountdownController, PhaseLog) {
        let controller = CountdownController(tickInterval: .milliseconds(10))
        controller.duration = duration
        let log = PhaseLog()
        controller.onPhaseChange = { log.phases.append($0) }
        return (controller, log)
    }

    final class PhaseLog { var phases: [CountdownController.Phase] = [] }

    @Test func offFiresImmediatelyWithoutCounting() async {
        let (controller, log) = makeController(.off)
        var fired = 0
        await controller.trigger { fired += 1 }.value
        #expect(fired == 1)
        #expect(log.phases == [.firing, .idle])
        #expect(controller.phase == .idle)
    }

    @Test func threeSecondTimerCountsDownThenFires() async {
        let (controller, log) = makeController(.three)
        var fired = 0
        await controller.trigger { fired += 1 }.value
        #expect(fired == 1)
        #expect(log.phases == [.counting(remaining: 3), .counting(remaining: 2), .counting(remaining: 1), .firing, .idle])
    }

    @Test(arguments: [CountdownDuration.five, .ten])
    func startsAtConfiguredDuration(_ duration: CountdownDuration) async {
        let (controller, log) = makeController(duration)
        await controller.trigger {}.value
        #expect(log.phases.first == .counting(remaining: duration.seconds))
        #expect(log.phases.last == .idle)
        #expect(log.phases.count == duration.seconds + 2)
    }

    @Test func cancelStopsCountdownAndNeverFires() async {
        let (controller, log) = makeController(.five)
        var fired = 0
        let task = controller.trigger { fired += 1 }
        try? await Task.sleep(for: .milliseconds(25))
        #expect(controller.isCounting)
        controller.cancel()
        #expect(controller.phase == .idle)
        await task.value
        try? await Task.sleep(for: .milliseconds(80))
        #expect(fired == 0)
        #expect(log.phases.last == .idle)
        #expect(!log.phases.contains(.firing))
    }

    @Test func triggeringDuringCountdownCancelsIt() async {
        let (controller, _) = makeController(.three)
        var fired = 0
        let task = controller.trigger { fired += 1 }
        controller.trigger { fired += 1 }   // second shutter press
        await task.value
        try? await Task.sleep(for: .milliseconds(60))
        #expect(fired == 0)
        #expect(controller.phase == .idle)
    }

    @Test func canTriggerAgainAfterCancel() async {
        let (controller, _) = makeController(.three)
        var fired = 0
        controller.trigger { fired += 1 }
        controller.cancel()
        await controller.trigger { fired += 1 }.value
        #expect(fired == 1)
        #expect(controller.phase == .idle)
    }

    @Test func timerButtonCyclesThroughAllChoices() {
        var duration = CountdownDuration.off
        var seen: [Int] = []
        for _ in 0..<5 { seen.append(duration.seconds); duration = duration.next }
        #expect(seen == [0, 3, 5, 10, 0])
    }
}
