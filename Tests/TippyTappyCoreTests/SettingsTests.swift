import XCTest
@testable import TippyTappyCore

final class SettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var settings: Settings!

    override func setUp() {
        super.setUp()
        defaults = makeTestDefaults()
        settings = Settings(defaults: defaults)
    }

    // MARK: Defaults

    func testDefaultIsNotPaused() {
        XCTAssertFalse(settings.isPaused)
    }

    func testDefaultDelayIsOneSecond() {
        XCTAssertEqual(settings.unmuteDelay, 1.0)
        XCTAssertEqual(Settings.defaultDelay, 1.0)
    }

    func testDefaultIconStyleIsKeyboard() {
        XCTAssertEqual(settings.iconStyle, .keyboard)
    }

    func testDefaultMuteIndicatorIsOn() {
        XCTAssertTrue(settings.showMuteIndicator)
    }

    func testDefaultDelayIsOneOfTheOfferedOptions() {
        XCTAssertTrue(Settings.delayOptions.contains(Settings.defaultDelay))
    }

    func testDelayOptionsAreSortedAndPositive() {
        XCTAssertEqual(Settings.delayOptions, Settings.delayOptions.sorted())
        XCTAssertTrue(Settings.delayOptions.allSatisfy { $0 > 0 })
    }

    // MARK: Persistence

    func testPausedRoundTrips() {
        settings.isPaused = true
        XCTAssertTrue(Settings(defaults: defaults).isPaused)
        settings.isPaused = false
        XCTAssertFalse(Settings(defaults: defaults).isPaused)
    }

    func testDelayRoundTrips() {
        settings.unmuteDelay = 2.5
        XCTAssertEqual(Settings(defaults: defaults).unmuteDelay, 2.5)
    }

    func testIconStyleRoundTrips() {
        for style in IconStyle.allCases {
            settings.iconStyle = style
            XCTAssertEqual(Settings(defaults: defaults).iconStyle, style)
        }
    }

    func testMuteIndicatorRoundTrips() {
        settings.showMuteIndicator = false
        XCTAssertFalse(Settings(defaults: defaults).showMuteIndicator)
        settings.showMuteIndicator = true
        XCTAssertTrue(Settings(defaults: defaults).showMuteIndicator)
    }

    // MARK: Validation

    func testZeroDelayIsClampedToMinimum() {
        settings.unmuteDelay = 0
        XCTAssertGreaterThan(settings.unmuteDelay, 0)
    }

    func testNegativeDelayIsClampedToMinimum() {
        settings.unmuteDelay = -5
        XCTAssertGreaterThan(settings.unmuteDelay, 0)
    }

    func testCorruptDelayInDefaultsFallsBackToDefault() {
        defaults.set(-1.0, forKey: Settings.Key.unmuteDelay)
        XCTAssertEqual(settings.unmuteDelay, Settings.defaultDelay)
    }

    func testUnknownIconStyleRawValueFallsBackToKeyboard() {
        defaults.set(999, forKey: Settings.Key.iconStyle)
        XCTAssertEqual(settings.iconStyle, .keyboard)
    }

    func testNegativeIconStyleRawValueFallsBackToKeyboard() {
        defaults.set(-1, forKey: Settings.Key.iconStyle)
        XCTAssertEqual(settings.iconStyle, .keyboard)
    }

    // MARK: Isolation

    func testSeparateSuitesDoNotShareState() {
        let other = Settings(defaults: makeTestDefaults("other"))
        settings.isPaused = true
        XCTAssertFalse(other.isPaused)
    }
}

final class IconStyleTests: XCTestCase {
    func testThereAreExactlyThreeStyles() {
        XCTAssertEqual(IconStyle.allCases.count, 3)
    }

    func testRawValuesAreStableAndContiguous() {
        XCTAssertEqual(IconStyle.allCases.map(\.rawValue), [0, 1, 2])
    }

    func testDisplayNamesAreUnique() {
        let names = IconStyle.allCases.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testIdleAndMutedSymbolsDiffer() {
        for style in IconStyle.allCases {
            XCTAssertNotEqual(style.idleSymbol, style.mutedSymbol, "\(style)")
        }
    }

    func testSymbolsAreNonEmpty() {
        for style in IconStyle.allCases {
            XCTAssertFalse(style.idleSymbol.isEmpty)
            XCTAssertFalse(style.mutedSymbol.isEmpty)
        }
    }

    func testIdleSymbolsAreUniqueAcrossStyles() {
        let symbols = IconStyle.allCases.map(\.idleSymbol)
        XCTAssertEqual(Set(symbols).count, symbols.count)
    }

    func testCodableRoundTrip() throws {
        for style in IconStyle.allCases {
            let data = try JSONEncoder().encode(style)
            XCTAssertEqual(try JSONDecoder().decode(IconStyle.self, from: data), style)
        }
    }
}
