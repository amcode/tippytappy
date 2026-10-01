import XCTest
@testable import TippyTappyCore

final class MicMuterTests: XCTestCase {
    private var control: FakeInputVolume!
    private var muter: MicMuter!

    override func setUp() {
        super.setUp()
        control = FakeInputVolume(volume: 0.75)
        muter = MicMuter(control: control)
    }

    // MARK: Initial state

    func testStartsUnmuted() {
        XCTAssertFalse(muter.isMuted)
        XCTAssertNil(muter.savedVolume)
    }

    func testIsAvailableMirrorsControl() {
        control.isAvailable = true
        XCTAssertTrue(muter.isAvailable)
        control.isAvailable = false
        XCTAssertFalse(muter.isAvailable)
    }

    // MARK: Mute

    func testMuteWritesZero() {
        muter.mute()
        XCTAssertEqual(control.writes, [0])
        XCTAssertEqual(control.volume, 0)
    }

    func testMuteSetsIsMuted() {
        muter.mute()
        XCTAssertTrue(muter.isMuted)
    }

    func testMuteSavesPreviousVolume() {
        muter.mute()
        XCTAssertEqual(muter.savedVolume, 0.75)
    }

    func testMuteTwiceOnlyWritesOnce() {
        muter.mute()
        muter.mute()
        XCTAssertEqual(control.writes, [0])
    }

    func testMuteDoesNothingWhenVolumeUnreadable() {
        control.volume = nil
        muter.mute()
        XCTAssertFalse(muter.isMuted)
        XCTAssertTrue(control.writes.isEmpty)
    }

    func testMuteStaysUnmutedIfWriteRejected() {
        control.rejectWrites = true
        muter.mute()
        XCTAssertFalse(muter.isMuted)
        XCTAssertEqual(control.writes, [0], "it should still have tried")
    }

    func testMuteWhenAlreadyAtZeroUsesFallbackVolume() {
        control.volume = 0
        muter.mute()
        XCTAssertEqual(muter.savedVolume, MicMuter.fallbackVolume)
    }

    func testMuteWhenAlreadyAtZeroKeepsEarlierSavedVolume() {
        muter.mute()            // saves 0.75
        muter.unmute()
        control.volume = 0      // user dragged it to zero themselves
        muter.mute()
        XCTAssertEqual(muter.savedVolume, 0.75)
    }

    // MARK: Unmute

    func testUnmuteRestoresSavedVolume() {
        muter.mute()
        muter.unmute()
        XCTAssertEqual(control.writes, [0, 0.75])
        XCTAssertEqual(control.volume, 0.75)
    }

    func testUnmuteClearsIsMuted() {
        muter.mute()
        muter.unmute()
        XCTAssertFalse(muter.isMuted)
    }

    func testUnmuteWhenNotMutedIsNoOp() {
        muter.unmute()
        XCTAssertTrue(control.writes.isEmpty)
        XCTAssertFalse(muter.isMuted)
    }

    func testUnmuteStaysMutedIfWriteRejected() {
        muter.mute()
        control.rejectWrites = true
        muter.unmute()
        XCTAssertTrue(muter.isMuted)
    }

    func testUnmuteAfterRejectedWriteCanRetry() {
        muter.mute()
        control.rejectWrites = true
        muter.unmute()
        control.rejectWrites = false
        muter.unmute()
        XCTAssertFalse(muter.isMuted)
        XCTAssertEqual(control.volume, 0.75)
    }

    // MARK: Round trips

    func testRepeatedCyclesPreserveOriginalVolume() {
        for _ in 0..<5 {
            muter.mute()
            muter.unmute()
        }
        XCTAssertEqual(control.volume, 0.75)
        XCTAssertEqual(control.writes.count, 10)
    }

    func testVolumeChangedBetweenCyclesIsTracked() {
        muter.mute(); muter.unmute()
        control.volume = 0.3
        muter.mute()
        XCTAssertEqual(muter.savedVolume, 0.3)
        muter.unmute()
        XCTAssertEqual(control.volume, 0.3)
    }

    func testFullVolumeRoundTrip() {
        control.volume = 1.0
        muter.mute(); muter.unmute()
        XCTAssertEqual(control.volume, 1.0)
    }

    func testVeryLowNonZeroVolumeIsPreserved() {
        control.volume = 0.01
        muter.mute()
        XCTAssertEqual(muter.savedVolume, 0.01)
        muter.unmute()
        XCTAssertEqual(control.volume, 0.01)
    }
}
