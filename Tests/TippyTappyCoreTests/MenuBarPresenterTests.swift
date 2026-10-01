import XCTest
@testable import TippyTappyCore

final class MenuBarPresenterTests: XCTestCase {
    // MARK: Symbol

    func testLiveShowsIdleSymbolForEveryStyle() {
        for style in IconStyle.allCases {
            XCTAssertEqual(MenuBarPresenter.symbol(for: .live, style: style, showMuteIndicator: true), style.idleSymbol)
            XCTAssertEqual(MenuBarPresenter.symbol(for: .live, style: style, showMuteIndicator: false), style.idleSymbol)
        }
    }

    func testMutedShowsMutedSymbolWhenIndicatorOn() {
        for style in IconStyle.allCases {
            XCTAssertEqual(MenuBarPresenter.symbol(for: .muted, style: style, showMuteIndicator: true), style.mutedSymbol)
        }
    }

    func testMutedShowsIdleSymbolWhenIndicatorOff() {
        for style in IconStyle.allCases {
            XCTAssertEqual(MenuBarPresenter.symbol(for: .muted, style: style, showMuteIndicator: false), style.idleSymbol)
        }
    }

    func testPausedShowsPauseSymbolRegardlessOfStyleOrIndicator() {
        for style in IconStyle.allCases {
            for indicator in [true, false] {
                XCTAssertEqual(MenuBarPresenter.symbol(for: .paused, style: style, showMuteIndicator: indicator),
                               MenuBarPresenter.pausedSymbol)
            }
        }
    }

    func testPausedSymbolIsNotAnyStyleSymbol() {
        for style in IconStyle.allCases {
            XCTAssertNotEqual(MenuBarPresenter.pausedSymbol, style.idleSymbol)
            XCTAssertNotEqual(MenuBarPresenter.pausedSymbol, style.mutedSymbol)
        }
    }

    // MARK: Tooltip

    func testTooltipsContainAppName() {
        for state in [TypingMuteController.State.live, .muted, .paused] {
            XCTAssertTrue(MenuBarPresenter.tooltip(for: state).contains(MenuBarPresenter.appName))
        }
    }

    func testTooltipsAreDistinctPerState() {
        let tips = [MenuBarPresenter.tooltip(for: .live),
                    MenuBarPresenter.tooltip(for: .muted),
                    MenuBarPresenter.tooltip(for: .paused)]
        XCTAssertEqual(Set(tips).count, 3)
    }

    func testMutedTooltipMentionsMuted() {
        XCTAssertTrue(MenuBarPresenter.tooltip(for: .muted).lowercased().contains("muted"))
    }

    func testPausedTooltipMentionsPaused() {
        XCTAssertTrue(MenuBarPresenter.tooltip(for: .paused).lowercased().contains("paused"))
    }

    // MARK: Status line

    func testMissingPermissionTakesPriority() {
        let line = MenuBarPresenter.statusLine(hasInputPermission: false, hasControllableMic: false, isPaused: true)
        XCTAssertTrue(line.contains("Input Monitoring"))
    }

    func testUncontrollableMicIsReportedWhenPermissionGranted() {
        let line = MenuBarPresenter.statusLine(hasInputPermission: true, hasControllableMic: false, isPaused: false)
        XCTAssertTrue(line.contains("volume control"))
    }

    func testPausedStatus() {
        let line = MenuBarPresenter.statusLine(hasInputPermission: true, hasControllableMic: true, isPaused: true)
        XCTAssertTrue(line.hasPrefix("Paused"))
    }

    func testActiveStatus() {
        let line = MenuBarPresenter.statusLine(hasInputPermission: true, hasControllableMic: true, isPaused: false)
        XCTAssertTrue(line.hasPrefix("Active"))
    }

    func testWarningsCarryWarningGlyph() {
        XCTAssertTrue(MenuBarPresenter.statusLine(hasInputPermission: false, hasControllableMic: true, isPaused: false).hasPrefix("⚠︎"))
        XCTAssertTrue(MenuBarPresenter.statusLine(hasInputPermission: true, hasControllableMic: false, isPaused: false).hasPrefix("⚠︎"))
        XCTAssertFalse(MenuBarPresenter.statusLine(hasInputPermission: true, hasControllableMic: true, isPaused: false).hasPrefix("⚠︎"))
    }

    // MARK: Pause menu title

    func testPauseTitleWhenActive() {
        XCTAssertEqual(MenuBarPresenter.pauseMenuTitle(isPaused: false), "Pause Tippy Tappy")
    }

    func testResumeTitleWhenPaused() {
        XCTAssertEqual(MenuBarPresenter.pauseMenuTitle(isPaused: true), "Resume Tippy Tappy")
    }

    // MARK: Delay label

    func testWholeSecondsHaveNoDecimal() {
        XCTAssertEqual(MenuBarPresenter.delayLabel(1), "1 s")
        XCTAssertEqual(MenuBarPresenter.delayLabel(2.0), "2 s")
        XCTAssertEqual(MenuBarPresenter.delayLabel(3), "3 s")
    }

    func testFractionalSecondsShowOneDecimal() {
        XCTAssertEqual(MenuBarPresenter.delayLabel(0.5), "0.5 s")
        XCTAssertEqual(MenuBarPresenter.delayLabel(1.5), "1.5 s")
    }

    func testEveryDelayOptionHasAUniqueLabel() {
        let labels = Settings.delayOptions.map(MenuBarPresenter.delayLabel)
        XCTAssertEqual(Set(labels).count, labels.count)
        XCTAssertEqual(labels, ["0.5 s", "1 s", "1.5 s", "2 s", "3 s"])
    }
}
