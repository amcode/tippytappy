import Foundation

/// Pure presentation logic for the menu bar: which symbol to show and what the
/// status line should say. Kept free of AppKit so it can be unit-tested.
public enum MenuBarPresenter {
    public static let pausedSymbol = "pause.circle"
    public static let appName = "Tippy Tappy"

    /// Which SF Symbol the status item should display.
    public static func symbol(for state: TypingMuteController.State,
                              style: IconStyle,
                              showMuteIndicator: Bool) -> String {
        switch state {
        case .paused: return pausedSymbol
        case .muted: return showMuteIndicator ? style.mutedSymbol : style.idleSymbol
        case .live: return style.idleSymbol
        }
    }

    /// Accessibility description / tooltip for the status item.
    public static func tooltip(for state: TypingMuteController.State) -> String {
        switch state {
        case .paused: return "\(appName) (paused)"
        case .muted: return "\(appName) (muted)"
        case .live: return appName
        }
    }

    /// The disabled first line of the menu explaining what's going on.
    public static func statusLine(hasInputPermission: Bool,
                                  hasControllableMic: Bool,
                                  isPaused: Bool) -> String {
        if !hasInputPermission { return "⚠︎ Needs Input Monitoring permission" }
        if !hasControllableMic { return "⚠︎ Current mic has no volume control" }
        return isPaused ? "Paused — mic will not be muted" : "Active — muting mic while you type"
    }

    public static func pauseMenuTitle(isPaused: Bool) -> String {
        isPaused ? "Resume \(appName)" : "Pause \(appName)"
    }

    /// "1 s", "0.5 s", "3 s".
    public static func delayLabel(_ seconds: TimeInterval) -> String {
        if seconds == seconds.rounded(.towardZero) {
            return String(format: "%.0f s", seconds)
        }
        return String(format: "%.1f s", seconds)
    }
}
