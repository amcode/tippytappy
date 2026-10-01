import CoreAudio
import Foundation
import TippyTappyCore

/// Drives the input volume of the system default microphone through CoreAudio.
/// Works with any app because it changes the device itself, not a particular stream.
final class CoreAudioInputVolume: InputVolumeControlling {
    private var defaultInputDevice: AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return (status == noErr && deviceID != 0) ? deviceID : nil
    }

    private func volumeAddress(_ element: UInt32) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: element)
    }

    /// Elements with a settable input volume: the main element if present, else channels 1 & 2.
    private func volumeElements(for device: AudioDeviceID) -> [UInt32] {
        var found: [UInt32] = []
        for element in [kAudioObjectPropertyElementMain, UInt32(1), UInt32(2)] {
            var address = volumeAddress(element)
            guard AudioObjectHasProperty(device, &address) else { continue }
            var settable = DarwinBoolean(false)
            if AudioObjectIsPropertySettable(device, &address, &settable) == noErr, settable.boolValue {
                found.append(element)
            }
        }
        if found.contains(kAudioObjectPropertyElementMain) { return [kAudioObjectPropertyElementMain] }
        return found
    }

    var isAvailable: Bool {
        guard let device = defaultInputDevice else { return false }
        return !volumeElements(for: device).isEmpty
    }

    func readVolume() -> Float? {
        guard let device = defaultInputDevice,
              let element = volumeElements(for: device).first else { return nil }
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = volumeAddress(element)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume) == noErr ? volume : nil
    }

    @discardableResult
    func writeVolume(_ volume: Float) -> Bool {
        guard let device = defaultInputDevice else { return false }
        var ok = false
        for element in volumeElements(for: device) {
            var value = Float32(volume)
            var address = volumeAddress(element)
            if AudioObjectSetPropertyData(device, &address, 0, nil,
                                          UInt32(MemoryLayout<Float32>.size), &value) == noErr {
                ok = true
            }
        }
        return ok
    }
}
