# Tippy Tappy

A tiny macOS menu bar utility that mutes your microphone while you type and un-mutes it when you stop — so your clicky keyboard stays out of the call.

- **Automatic** — first keystroke mutes, the mic comes back a moment after you stop.
- **Works everywhere** — it drives the system input volume, so Zoom, Teams, Meet, Discord, FaceTime all benefit. Any mic.
- **Pause when you need to be loud** — one click in the menu bar for pair-programming sessions.
- **Yours to tweak** — three icon styles, optional mute indicator, adjustable unmute delay, launch at login.

Requires macOS 13 Ventura or later.

## Install

Grab `Tippy Tappy.app` from the latest release (or build it yourself, below), drop it in `/Applications` and open it.

On first launch macOS will ask for **Input Monitoring** permission (System Settings → Privacy & Security → Input Monitoring). The app needs it to see keystrokes in other apps; it never records what you type. The menu bar status line tells you if the permission is missing or if your current mic doesn't expose a volume control.

## Build from source

```bash
git clone https://github.com/<you>/tippy-tappy.git
cd tippy-tappy
./build.sh          # runs the tests, then builds dist/Tippy Tappy.app (universal, ad-hoc signed)
```

Needs the Xcode Command Line Tools (`xcode-select --install`). You can also open `Package.swift` in Xcode.

## Tests

```bash
swift test
```

The logic lives in `TippyTappyCore`, a plain Swift library with no AppKit or CoreAudio dependencies at its boundaries — the audio device and the timer are injected behind protocols, so the whole mute/unmute state machine, the settings store and the menu bar presentation are covered by fast XCTest unit tests (`Tests/TippyTappyCoreTests`). CI runs them on every push.

## Releasing

Releases are built on GitHub's macOS runners. Tag a commit and push the tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `Release` workflow runs the tests, builds a universal app with that version stamped into `Info.plist`, and attaches `TippyTappy-1.0.0.dmg`, `TippyTappy-1.0.0.zip` and `SHA256SUMS.txt` to the GitHub release, with auto-generated release notes. You can also re-run it for an existing tag from the Actions tab (*Run workflow*).

### Signing and notarisation

Without any secrets configured, releases are ad-hoc signed and users see a Gatekeeper warning on first open. To ship properly signed, notarised builds you need a paid Apple Developer account. Then:

1. In Xcode (Settings → Accounts → Manage Certificates) or at developer.apple.com, create a **Developer ID Application** certificate.
2. In Keychain Access, export that certificate *with its private key* as a `.p12`, setting a password.
3. At appleid.apple.com → Sign-In and Security → App-Specific Passwords, create one for "GitHub Actions".
4. Add these repository secrets (Settings → Secrets and variables → Actions):

   | Secret | Value |
   |---|---|
   | `MACOS_CERTIFICATE_P12` | `base64 -i cert.p12 \| pbcopy` |
   | `MACOS_CERTIFICATE_PWD` | the .p12 export password |
   | `APPLE_ID` | your Apple ID email |
   | `APPLE_TEAM_ID` | 10-character team ID from the Membership page |
   | `APPLE_APP_PASSWORD` | the app-specific password |

The next tagged release will be signed with the hardened runtime, submitted to Apple's notary service (`notarytool`), stapled, and the DMG signed and notarised too. The workflow detects the secrets automatically — no other change needed.

## How it works

```
KeyMonitor ──keystroke──▶ TypingMuteController ──mute/unmute──▶ MicMuter ──volume──▶ CoreAudioInputVolume
                                   │
                              Scheduling (unmute countdown)
```

1. `KeyMonitor` (app target) watches global key events via `NSEvent` monitors.
2. `TypingMuteController` (core) mutes on the first key, restarts a countdown on every key, and unmutes when the countdown fires. Pausing cancels the countdown and restores the mic.
3. `MicMuter` (core) remembers the mic's level before muting so it's restored exactly, and never restores to zero.
4. `CoreAudioInputVolume` (app target) sets `kAudioDevicePropertyVolumeScalar` on the default input device.

The mic is always restored on quit.

## Project layout

```
Package.swift
Sources/
  TippyTappyCore/      pure logic (tested)
    MicMuter.swift
    TypingMuteController.swift
    Settings.swift
    MenuBarPresenter.swift
    Scheduling.swift
  TippyTappy/          the app (thin AppKit/CoreAudio wiring)
    main.swift
    AppDelegate.swift
    KeyMonitor.swift
    CoreAudioInputVolume.swift
Tests/TippyTappyCoreTests/
Info.plist
AppIcon.iconset/
build.sh
.github/workflows/ci.yml
```

## Known limitations

- Some professional USB/Thunderbolt audio interfaces don't expose a software input volume; those can't be muted this way. The menu will tell you.
- The app is ad-hoc signed. Gatekeeper may ask you to allow it in System Settings → Privacy & Security the first time.

## Licence

MIT — see [LICENSE](LICENSE).
