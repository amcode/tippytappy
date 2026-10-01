import Foundation
import XCTest
@testable import TippyTappyCore

/// In-memory stand-in for the system input volume. Records every write.
final class FakeInputVolume: InputVolumeControlling {
    var isAvailable = true
    var volume: Float? = 0.75
    var rejectWrites = false
    private(set) var writes: [Float] = []
    private(set) var readCount = 0

    init(volume: Float? = 0.75) { self.volume = volume }

    func readVolume() -> Float? {
        readCount += 1
        return volume
    }

    @discardableResult
    func writeVolume(_ new: Float) -> Bool {
        writes.append(new)
        if rejectWrites { return false }
        volume = new
        return true
    }
}

/// Records mute/unmute calls without touching audio.
final class SpyMuter: Muting {
    private(set) var isMuted = false
    private(set) var muteCalls = 0
    private(set) var unmuteCalls = 0

    func mute() { muteCalls += 1; isMuted = true }
    func unmute() { unmuteCalls += 1; isMuted = false }
}

/// A scheduler tests can advance by hand.
final class ManualScheduler: Scheduling {
    final class Job: Cancellable {
        let delay: TimeInterval
        let work: () -> Void
        private(set) var isCancelled = false
        private(set) var fired = false
        init(delay: TimeInterval, work: @escaping () -> Void) { self.delay = delay; self.work = work }
        func cancel() { isCancelled = true }
        func fire() {
            guard !isCancelled, !fired else { return }
            fired = true
            work()
        }
    }

    private(set) var jobs: [Job] = []

    /// Jobs that are still waiting to run.
    var pendingJobs: [Job] { jobs.filter { !$0.isCancelled && !$0.fired } }

    func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable {
        let job = Job(delay: seconds, work: work)
        jobs.append(job)
        return job
    }

    /// Runs every live job as though its delay had elapsed.
    func fireAll() {
        for job in pendingJobs { job.fire() }
    }
}

/// Fresh, isolated defaults per test.
func makeTestDefaults(_ name: String = #function) -> UserDefaults {
    let suite = "TippyTappyTests.\(name).\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}
