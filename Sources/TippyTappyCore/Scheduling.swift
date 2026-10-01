import Foundation

/// A cancellable piece of scheduled work.
public protocol Cancellable {
    func cancel()
}

/// Schedules a closure to run once after a delay. The app uses `TimerScheduler`;
/// tests use a manual scheduler they can advance by hand.
public protocol Scheduling {
    func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable
}

/// Real scheduler backed by `Timer` on the main run loop.
public final class TimerScheduler: Scheduling {
    public init() {}

    public func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable {
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in work() }
        return TimerToken(timer: timer)
    }

    private struct TimerToken: Cancellable {
        let timer: Timer
        func cancel() { timer.invalidate() }
    }
}
