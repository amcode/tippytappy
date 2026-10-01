import Foundation

/// Abstracts the system's input-volume control so the muting logic can be tested
/// without touching real audio hardware.
public protocol InputVolumeControlling {
    /// Whether the current default input device exposes a settable volume.
    var isAvailable: Bool { get }
    /// Current input volume, 0…1, or nil if unavailable.
    func readVolume() -> Float?
    /// Sets the input volume. Returns false if the device rejected it.
    @discardableResult
    func writeVolume(_ volume: Float) -> Bool
}

/// Anything that can be muted and unmuted. `MicMuter` is the real one;
/// tests use a spy.
public protocol Muting: AnyObject {
    var isMuted: Bool { get }
    func mute()
    func unmute()
}

/// Mutes the microphone by driving its input volume to zero, remembering the
/// previous level so it can be restored exactly.
public final class MicMuter: Muting {
    public static let fallbackVolume: Float = 1.0

    private let control: InputVolumeControlling
    public private(set) var savedVolume: Float?
    public private(set) var isMuted = false

    public init(control: InputVolumeControlling) {
        self.control = control
    }

    public var isAvailable: Bool { control.isAvailable }

    public func mute() {
        guard !isMuted, let volume = control.readVolume() else { return }
        // If the user already has the mic at zero, keep whatever we saved earlier
        // (or fall back to full) so an unmute never "restores" to silence.
        savedVolume = volume > 0 ? volume : (savedVolume ?? Self.fallbackVolume)
        if control.writeVolume(0) { isMuted = true }
    }

    public func unmute() {
        guard isMuted else { return }
        if control.writeVolume(savedVolume ?? Self.fallbackVolume) { isMuted = false }
    }
}
