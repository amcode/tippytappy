import XCTest
@testable import TippyTappyCore

final class TimerSchedulerTests: XCTestCase {
    func testWorkRunsAfterDelay() {
        let scheduler = TimerScheduler()
        let done = expectation(description: "fired")
        _ = scheduler.schedule(after: 0.05) { done.fulfill() }
        wait(for: [done], timeout: 1)
    }

    func testCancelPreventsWork() {
        let scheduler = TimerScheduler()
        let notFired = expectation(description: "not fired")
        notFired.isInverted = true
        let token = scheduler.schedule(after: 0.05) { notFired.fulfill() }
        token.cancel()
        wait(for: [notFired], timeout: 0.3)
    }

    func testWorkRunsOnlyOnce() {
        let scheduler = TimerScheduler()
        let fired = expectation(description: "fired once")
        var count = 0
        _ = scheduler.schedule(after: 0.05) {
            count += 1
            fired.fulfill()
        }
        wait(for: [fired], timeout: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(count, 1)
    }

    func testMultipleJobsAllRun() {
        let scheduler = TimerScheduler()
        let all = expectation(description: "three jobs")
        all.expectedFulfillmentCount = 3
        for i in 1...3 {
            _ = scheduler.schedule(after: 0.02 * Double(i)) { all.fulfill() }
        }
        wait(for: [all], timeout: 1)
    }
}

final class ManualSchedulerTests: XCTestCase {
    /// The test double itself has behaviour worth pinning down, since every controller test leans on it.

    func testScheduleRecordsDelay() {
        let s = ManualScheduler()
        _ = s.schedule(after: 1.5) {}
        XCTAssertEqual(s.jobs.first?.delay, 1.5)
    }

    func testFireAllRunsPendingWork() {
        let s = ManualScheduler()
        var ran = false
        _ = s.schedule(after: 1) { ran = true }
        s.fireAll()
        XCTAssertTrue(ran)
    }

    func testCancelledJobIsNotPendingAndDoesNotRun() {
        let s = ManualScheduler()
        var ran = false
        let token = s.schedule(after: 1) { ran = true }
        token.cancel()
        XCTAssertTrue(s.pendingJobs.isEmpty)
        s.fireAll()
        XCTAssertFalse(ran)
    }

    func testFiredJobDoesNotRunTwice() {
        let s = ManualScheduler()
        var count = 0
        _ = s.schedule(after: 1) { count += 1 }
        s.fireAll()
        s.fireAll()
        XCTAssertEqual(count, 1)
        XCTAssertTrue(s.pendingJobs.isEmpty)
    }
}
