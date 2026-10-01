import AppKit
import ServiceManagement
import TippyTappyCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let settings = Settings()
    private let audio = CoreAudioInputVolume()
    private lazy var muter = MicMuter(control: audio)
    private lazy var controller = TypingMuteController(
        muter: muter, scheduler: TimerScheduler(), settings: settings)
    private let keys = KeyMonitor()
    private var permissionPoll: Timer?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly

        controller.onStateChange = { [weak self] _ in
            self?.updateIcon()
            self?.rebuildMenu()
        }
        keys.onKeyDown = { [weak self] in self?.controller.keyPressed() }

        rebuildMenu()
        updateIcon()

        if KeyMonitor.hasPermission {
            keys.start()
        } else {
            KeyMonitor.requestPermission()
            permissionPoll = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                if KeyMonitor.hasPermission {
                    self.keys.start()
                    self.rebuildMenu()
                    timer.invalidate()
                    self.permissionPoll = nil
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.shutdown()   // never leave the user's mic silenced
    }

    // MARK: Icon

    private func updateIcon() {
        let state = controller.state
        let symbol = MenuBarPresenter.symbol(
            for: state, style: settings.iconStyle, showMuteIndicator: settings.showMuteIndicator)
        let tooltip = MenuBarPresenter.tooltip(for: state)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.appearsDisabled = state == .paused
        statusItem.button?.toolTip = tooltip
    }

    // MARK: Menu

    private func rebuildMenu() {
        let menu = NSMenu()

        let status = NSMenuItem(
            title: MenuBarPresenter.statusLine(
                hasInputPermission: KeyMonitor.hasPermission,
                hasControllableMic: muter.isAvailable,
                isPaused: controller.isPaused),
            action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let pause = NSMenuItem(title: MenuBarPresenter.pauseMenuTitle(isPaused: controller.isPaused),
                               action: #selector(togglePause), keyEquivalent: "p")
        pause.target = self
        menu.addItem(pause)
        menu.addItem(.separator())

        // Unmute delay
        let delayMenu = NSMenu()
        for seconds in Settings.delayOptions {
            let item = NSMenuItem(title: MenuBarPresenter.delayLabel(seconds),
                                  action: #selector(setDelay(_:)), keyEquivalent: "")
            item.representedObject = seconds
            item.target = self
            item.state = seconds == settings.unmuteDelay ? .on : .off
            delayMenu.addItem(item)
        }
        let delayItem = NSMenuItem(title: "Unmute delay", action: nil, keyEquivalent: "")
        delayItem.submenu = delayMenu
        menu.addItem(delayItem)

        // Icon style
        let iconMenu = NSMenu()
        for style in IconStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(setIconStyle(_:)), keyEquivalent: "")
            item.representedObject = style.rawValue
            item.target = self
            item.state = style == settings.iconStyle ? .on : .off
            item.image = NSImage(systemSymbolName: style.idleSymbol, accessibilityDescription: nil)
            iconMenu.addItem(item)
        }
        iconMenu.addItem(.separator())
        let indicator = NSMenuItem(title: "Show mute indicator", action: #selector(toggleIndicator), keyEquivalent: "")
        indicator.target = self
        indicator.state = settings.showMuteIndicator ? .on : .off
        iconMenu.addItem(indicator)
        let iconItem = NSMenuItem(title: "Menu bar icon", action: nil, keyEquivalent: "")
        iconItem.submenu = iconMenu
        menu.addItem(iconItem)

        let login = NSMenuItem(title: "Launch at login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        if !KeyMonitor.hasPermission {
            menu.addItem(.separator())
            let perm = NSMenuItem(title: "Open Input Monitoring settings…",
                                  action: #selector(openPermissions), keyEquivalent: "")
            perm.target = self
            menu.addItem(perm)
        }

        menu.addItem(.separator())
        let about = NSMenuItem(title: "About \(MenuBarPresenter.appName)", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit \(MenuBarPresenter.appName)",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: Actions

    @objc private func togglePause() {
        controller.togglePause()
        rebuildMenu()
        updateIcon()
    }

    @objc private func setDelay(_ sender: NSMenuItem) {
        if let seconds = sender.representedObject as? TimeInterval { settings.unmuteDelay = seconds }
        rebuildMenu()
    }

    @objc private func setIconStyle(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? Int, let style = IconStyle(rawValue: raw) {
            settings.iconStyle = style
        }
        rebuildMenu()
        updateIcon()
    }

    @objc private func toggleIndicator() {
        settings.showMuteIndicator.toggle()
        rebuildMenu()
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Launch at login failed: \(error)")
        }
        rebuildMenu()
    }

    @objc private func openPermissions() {
        KeyMonitor.requestPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = MenuBarPresenter.appName
        alert.informativeText = "Mutes your microphone while you type and unmutes when you stop.\n\nWorks with any app and any mic by driving the system input volume."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
