import AppKit
import ApplicationServices

/// Watches for keystrokes system-wide. Requires the Input Monitoring permission.
final class KeyMonitor {
    var onKeyDown: (() -> Void)?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    static var hasPermission: Bool { CGPreflightListenEventAccess() }

    /// Triggers the system prompt and adds the app to the Input Monitoring list.
    static func requestPermission() { CGRequestListenEventAccess() }

    func start() {
        stop()
        let mask: NSEvent.EventTypeMask = [.keyDown, .flagsChanged]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.onKeyDown?()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.onKeyDown?()
            return event
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    deinit { stop() }
}
