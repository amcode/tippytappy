import Foundation

/// The menu bar icon designs the user can pick from.
public enum IconStyle: Int, CaseIterable, Codable {
    case keyboard = 0
    case microphone = 1
    case waveform = 2

    public var displayName: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .microphone: return "Microphone"
        case .waveform: return "Waveform"
        }
    }

    /// SF Symbol shown when the mic is live.
    public var idleSymbol: String {
        switch self {
        case .keyboard: return "keyboard"
        case .microphone: return "mic"
        case .waveform: return "waveform"
        }
    }

    /// SF Symbol shown while the mic is muted.
    public var mutedSymbol: String {
        switch self {
        case .keyboard: return "keyboard.badge.ellipsis"
        case .microphone: return "mic.slash"
        case .waveform: return "waveform.slash"
        }
    }
}

/// User-tunable settings. Backed by `UserDefaults` so they persist, but the suite is
/// injectable so tests don't pollute the real preferences.
public final class Settings {
    public static let delayOptions: [TimeInterval] = [0.5, 1.0, 1.5, 2.0, 3.0]
    public static let defaultDelay: TimeInterval = 1.0

    enum Key {
        static let paused = "paused"
        static let unmuteDelay = "unmuteDelay"
        static let iconStyle = "iconStyle"
        static let showMuteIndicator = "showMuteIndicator"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isPaused: Bool {
        get { defaults.bool(forKey: Key.paused) }
        set { defaults.set(newValue, forKey: Key.paused) }
    }

    /// Seconds after the last keystroke before the mic is restored. Never zero.
    public var unmuteDelay: TimeInterval {
        get {
            let stored = defaults.double(forKey: Key.unmuteDelay)
            return stored > 0 ? stored : Self.defaultDelay
        }
        set { defaults.set(max(newValue, 0.1), forKey: Key.unmuteDelay) }
    }

    public var iconStyle: IconStyle {
        get { IconStyle(rawValue: defaults.integer(forKey: Key.iconStyle)) ?? .keyboard }
        set { defaults.set(newValue.rawValue, forKey: Key.iconStyle) }
    }

    /// Whether the icon changes while muted. Defaults to on.
    public var showMuteIndicator: Bool {
        get { defaults.object(forKey: Key.showMuteIndicator) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showMuteIndicator) }
    }
}
