import XCTest
@testable import TippyTappyCore

final class TypingMuteControllerTests: XCTestCase {
    private var muter: SpyMuter!
    private var scheduler: ManualScheduler!
    private var settings: Settings!
    private var controller: TypingMuteController!
    private var stateChanges: [TypingMuteController.State] = []

    override func setUp() {
        super.setUp()
        muter = SpyMuter()
        scheduler = ManualScheduler()
        settings = Settings(defaults: makeTestDefaults())
        controller = TypingMuteController(muter: muter, scheduler: scheduler, settings: settings)
        stateChanges = []
        controller.onStateChange = { [weak self] in self?.stateChanges.append($0) }
    }

    // MARK: Initial state

    func testStartsLive() {
        XCTAssertEqual(controller.state, .live)
        XCTAssertFalse(controller.isPaused)
    }

    func testStartsPausedIfSettingsSaySo() {
        settings.isPaused = true
        XCTAssertEqual(controller.state, .paused)
    }

    // MARK: Typing mutes

    func testFirstKeyMutes() {
        controller.keyPressed()
        XCTAssertEqual(muter.muteCalls, 1)
        XCTAssertEqual(controller.state, .muted)
    }

    func testFirstKeySchedulesUnmuteWithConfiguredDelay() {
        settings.unmuteDelay = 2.0
        controller.keyPressed()
        XCTAssertEqual(scheduler.pendingJobs.count, 1)
        XCTAssertEqual(scheduler.pendingJobs.first?.delay, 2.0)
    }

    func testFirstKeyEmitsMutedState() {
        controller.keyPressed()
        XCTAssertEqual(stateChanges, [.muted])
    }

    func testSubsequentKeysDoNotReMute() {
        controller.keyPressed()
        controller.keyPressed()
        controller.keyPressed()
        XCTAssertEqual(muter.muteCalls, 1)
    }

    func testSubsequentKeysDoNotEmitDuplicateStates() {
        controller.keyPressed()
        controller.keyPressed()
        XCTAssertEqual(stateChanges, [.muted])
    }

    func testEachKeyRestartsCountdown() {
        controller.keyPressed()
        let first = scheduler.pendingJobs.first
        controller.keyPressed()
        XCTAssertTrue(first?.isCancelled ?? false, "first countdown should be cancelled")
        XCTAssertEqual(scheduler.pendingJobs.count, 1)
        XCTAssertEqual(scheduler.jobs.count, 2)
    }

    func testDelayChangeAppliesToNextKeystroke() {
        settings.unmuteDelay = 0.5
        controller.keyPressed()
        settings.unmuteDelay = 3.0
        controller.keyPressed()
        XCTAssertEqual(scheduler.pendingJobs.first?.delay, 3.0)
    }

    // MARK: Countdown unmutes

    func testCountdownFiringUnmutes() {
        controller.keyPressed()
        scheduler.fireAll()
        XCTAssertEqual(muter.unmuteCalls, 1)
        XCTAssertEqual(controller.state, .live)
    }

    func testCountdownFiringEmitsLiveState() {
        controller.keyPressed()
        scheduler.fireAll()
        XCTAssertEqual(stateChanges, [.muted, .live])
    }

    func testCancelledCountdownDoesNotUnmute() {
        controller.keyPressed()
        controller.keyPressed()   // cancels first job
        scheduler.jobs.first?.fire()
        XCTAssertEqual(muter.unmuteCalls, 0)
        XCTAssertEqual(controller.state, .muted)
    }

    func testTypingAgainAfterUnmuteMutesAgain() {
        controller.keyPressed()
        scheduler.fireAll()
        controller.keyPressed()
        XCTAssertEqual(muter.muteCalls, 2)
        XCTAssertEqual(stateChanges, [.muted, .live, .muted])
    }

    func testLongTypingBurstProducesOneMuteAndOneUnmute() {
        for _ in 0..<50 { controller.keyPressed() }
        scheduler.fireAll()
        XCTAssertEqual(muter.muteCalls, 1)
        XCTAssertEqual(muter.unmuteCalls, 1)
        XCTAssertEqual(scheduler.jobs.count, 50)
        XCTAssertEqual(scheduler.jobs.filter { $0.isCancelled }.count, 49)
    }

    // MARK: Pause / resume

    func testPauseSetsState() {
        controller.pause()
        XCTAssertEqual(controller.state, .paused)
        XCTAssertTrue(controller.isPaused)
    }

    func testPausePersistsToSettings() {
        controller.pause()
        XCTAssertTrue(settings.isPaused)
    }

    func testPauseEmitsPausedState() {
        controller.pause()
        XCTAssertEqual(stateChanges, [.paused])
    }

    func testPauseWhileMutedUnmutesImmediately() {
        controller.keyPressed()
        controller.pause()
        XCTAssertEqual(muter.unmuteCalls, 1)
        XCTAssertFalse(muter.isMuted)
    }

    func testPauseWhileMutedCancelsCountdown() {
        controller.keyPressed()
        controller.pause()
        XCTAssertTrue(scheduler.pendingJobs.isEmpty)
    }

    func testPauseWhileLiveDoesNotCallMuteOrExtraUnmute() {
        controller.pause()
        XCTAssertEqual(muter.muteCalls, 0)
        // unmute() is called defensively; the spy records it, but state stays unmuted.
        XCTAssertFalse(muter.isMuted)
    }

    func testKeysWhilePausedAreIgnored() {
        controller.pause()
        controller.keyPressed()
        controller.keyPressed()
        XCTAssertEqual(muter.muteCalls, 0)
        XCTAssertTrue(scheduler.jobs.isEmpty)
        XCTAssertEqual(controller.state, .paused)
    }

    func testPauseTwiceIsIdempotent() {
        controller.pause()
        controller.pause()
        XCTAssertEqual(stateChanges, [.paused])
    }

    func testResumeReturnsToLive() {
        controller.pause()
        controller.resume()
        XCTAssertEqual(controller.state, .live)
        XCTAssertFalse(settings.isPaused)
        XCTAssertEqual(stateChanges, [.paused, .live])
    }

    func testResumeWhenNotPausedIsNoOp() {
        controller.resume()
        XCTAssertTrue(stateChanges.isEmpty)
    }

    func testTypingAfterResumeMutesAgain() {
        controller.pause()
        controller.resume()
        controller.keyPressed()
        XCTAssertEqual(controller.state, .muted)
        XCTAssertEqual(muter.muteCalls, 1)
    }

    func testTogglePauseFlipsBothWays() {
        controller.togglePause()
        XCTAssertTrue(controller.isPaused)
        controller.togglePause()
        XCTAssertFalse(controller.isPaused)
    }

    // MARK: Shutdown

    func testShutdownUnmutesAndCancelsCountdown() {
        controller.keyPressed()
        controller.shutdown()
        XCTAssertEqual(muter.unmuteCalls, 1)
        XCTAssertFalse(muter.isMuted)
        XCTAssertTrue(scheduler.pendingJobs.isEmpty)
    }

    func testShutdownWhenLiveIsSafe() {
        controller.shutdown()
        XCTAssertEqual(controller.state, .live)
    }

    // MARK: Integration with the real MicMuter

    func testEndToEndWithRealMuterRestoresVolume() {
        let control = FakeInputVolume(volume: 0.6)
        let realMuter = MicMuter(control: control)
        let c = TypingMuteController(muter: realMuter, scheduler: scheduler, settings: settings)
        c.keyPressed()
        XCTAssertEqual(control.volume, 0)
        c.keyPressed()
        scheduler.fireAll()
        XCTAssertEqual(control.volume, 0.6)
        XCTAssertEqual(control.writes, [0, 0.6])
    }

    func testEndToEndPauseRestoresVolume() {
        let control = FakeInputVolume(volume: 0.6)
        let c = TypingMuteController(muter: MicMuter(control: control), scheduler: scheduler, settings: settings)
        c.keyPressed()
        c.pause()
        XCTAssertEqual(control.volume, 0.6)
    }

    // MARK: Memory

    func testControllerIsReleasedWithPendingCountdown() {
        weak var weakController: TypingMuteController?
        autoreleasepool {
            let c = TypingMuteController(muter: muter, scheduler: scheduler, settings: settings)
            weakController = c
            c.keyPressed()
        }
        XCTAssertNil(weakController, "the scheduled closure must not retain the controller")
        scheduler.fireAll()   // must not crash
    }
}
