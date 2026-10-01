import Foundation

/// The heart of the app: turns a stream of keystrokes into mute/unmute decisions.
///
/// - First keystroke mutes.
/// - Every keystroke restarts the unmute countdown.
/// - When the countdown fires, the mic is restored.
/// - Pausing cancels any countdown and restores the mic immediately.
public final class TypingMuteController {
    public enum State: Equatable {
        case live
        case muted
        case paused
    }

    private let muter: Muting
    private let scheduler: Scheduling
    private let settings: Settings
    private var pending: Cancellable?

    /// Called whenever `state` changes (on the same thread as the trigger).
    public var onStateChange: ((State) -> Void)?

    public init(muter: Muting, scheduler: Scheduling, settings: Settings) {
        self.muter = muter
        self.scheduler = scheduler
        self.settings = settings
    }

    public var state: State {
        if settings.isPaused { return .paused }
        return muter.isMuted ? .muted : .live
    }

    public var isPaused: Bool { settings.isPaused }

    /// Feed a keystroke in.
    public func keyPressed() {
        guard !settings.isPaused else { return }
        let before = state
        if !muter.isMuted { muter.mute() }
        restartCountdown()
        notifyIfChanged(from: before)
    }

    public func pause() {
        guard !settings.isPaused else { return }
        let before = state
        settings.isPaused = true
        cancelCountdown()
        muter.unmute()
        notifyIfChanged(from: before)
    }

    public func resume() {
        guard settings.isPaused else { return }
        let before = state
        settings.isPaused = false
        notifyIfChanged(from: before)
    }

    public func togglePause() {
        settings.isPaused ? resume() : pause()
    }

    /// Restore the mic and cancel any countdown; call on quit.
    public func shutdown() {
        cancelCountdown()
        muter.unmute()
    }

    // MARK: - Private

    private func restartCountdown() {
        cancelCountdown()
        pending = scheduler.schedule(after: settings.unmuteDelay) { [weak self] in
            self?.countdownFired()
        }
    }

    private func cancelCountdown() {
        pending?.cancel()
        pending = nil
    }

    private func countdownFired() {
        pending = nil
        let before = state
        muter.unmute()
        notifyIfChanged(from: before)
    }

    private func notifyIfChanged(from before: State) {
        let now = state
        if now != before { onStateChange?(now) }
    }
}
