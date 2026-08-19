import Cocoa
import FlutterMacOS
import XCTest
@testable import Instant_Chat

class RunnerTests: XCTestCase {
  func testInitialWindowUsesCompactAuthenticationSize() {
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.width, 280)
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.height, 360)
  }

  func testWindowModeTransitionsDoNotAnimate() {
    XCTAssertFalse(MainFlutterWindow.animatesModeTransitions)
  }

  func testMainWindowStartsLargerThanItsMinimumSize() {
    XCTAssertEqual(MainFlutterWindow.mainFrameSize.width, 1150)
    XCTAssertEqual(MainFlutterWindow.mainFrameSize.height, 750)
    XCTAssertEqual(MainFlutterWindow.mainMinimumFrameSize.width, 1050)
    XCTAssertEqual(MainFlutterWindow.mainMinimumFrameSize.height, 680)
    XCTAssertGreaterThan(
      MainFlutterWindow.mainFrameSize.width,
      MainFlutterWindow.mainMinimumFrameSize.width
    )
    XCTAssertGreaterThan(
      MainFlutterWindow.mainFrameSize.height,
      MainFlutterWindow.mainMinimumFrameSize.height
    )
  }

  func testAuthenticationWindowIsFixedAndCompact() {
    let window = makeWindow()

    MainFlutterWindow.configureWindow(
      window,
      for: .authentication,
      animated: false
    )

    XCTAssertEqual(window.frame.size, MainFlutterWindow.authenticationFrameSize)
    XCTAssertEqual(window.minSize, MainFlutterWindow.authenticationFrameSize)
    XCTAssertEqual(window.maxSize, MainFlutterWindow.authenticationFrameSize)
    XCTAssertFalse(window.styleMask.contains(.resizable))
    XCTAssertFalse(window.standardWindowButton(.zoomButton)?.isEnabled ?? true)
  }

  func testMainWindowExpandsAndBecomesResizable() {
    let window = makeWindow()
    MainFlutterWindow.configureWindow(
      window,
      for: .authentication,
      animated: false
    )

    MainFlutterWindow.configureWindow(window, for: .main, animated: false)

    XCTAssertEqual(window.frame.size, MainFlutterWindow.mainFrameSize)
    XCTAssertEqual(window.minSize, MainFlutterWindow.mainMinimumFrameSize)
    XCTAssertTrue(window.styleMask.contains(.resizable))
    XCTAssertTrue(window.standardWindowButton(.zoomButton)?.isEnabled ?? false)
  }

  func testModeChangeRefreshesAndPresentsTheFlutterView() {
    let window = makeWindow()
    let controller = NSViewController()
    controller.view = NSView(frame: window.contentLayoutRect)
    window.contentViewController = controller
    window.orderOut(nil)

    MainFlutterWindow.refreshAfterModeChange(window)

    XCTAssertTrue(controller.view.needsLayout)
    XCTAssertTrue(controller.view.needsDisplay)
    XCTAssertTrue(window.isVisible)
  }

  func testWindowChromeUsesTheFullSizeContentView() {
    let window = NSWindow(
      contentRect: .zero,
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    MainFlutterWindow.configureWindowChrome(window)

    XCTAssertEqual(window.titleVisibility, .hidden)
    XCTAssertTrue(window.titlebarAppearsTransparent)
    XCTAssertTrue(window.styleMask.contains(.fullSizeContentView))
    XCTAssertTrue(window.isMovableByWindowBackground)
  }

  func testWindowControlsHaveExtraSidebarInset() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1180, height: 660),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    let buttons = [
      window.standardWindowButton(.closeButton),
      window.standardWindowButton(.miniaturizeButton),
      window.standardWindowButton(.zoomButton),
    ].compactMap { $0 }
    let originalFrames = buttons.map(\.frame)

    MainFlutterWindow.repositionWindowControls(in: window)

    for (index, button) in buttons.enumerated() {
      XCTAssertEqual(button.frame.minX, originalFrames[index].minX + 12)
      XCTAssertEqual(button.frame.minY, originalFrames[index].minY - 8)
    }

    MainFlutterWindow.repositionWindowControls(in: window)

    for (index, button) in buttons.enumerated() {
      XCTAssertEqual(button.frame.minX, originalFrames[index].minX + 12)
      XCTAssertEqual(button.frame.minY, originalFrames[index].minY - 8)
    }
  }

  func testDockPolicyUpdateSucceedsWhenPolicyIsAlreadyApplied() {
    var setPolicyCallCount = 0

    let succeeded = DockVisibilityChannel.updateActivationPolicy(
      .accessory,
      currentPolicy: { .accessory },
      setPolicy: { _ in
        setPolicyCallCount += 1
        return false
      }
    )

    XCTAssertTrue(succeeded)
    XCTAssertEqual(setPolicyCallCount, 0)
  }

  func testDockPolicyUpdateVerifiesTheResultInsteadOfTheReturnValue() {
    var currentPolicy = NSApplication.ActivationPolicy.accessory

    let succeeded = DockVisibilityChannel.updateActivationPolicy(
      .regular,
      currentPolicy: { currentPolicy },
      setPolicy: { desiredPolicy in
        currentPolicy = desiredPolicy
        return false
      }
    )

    XCTAssertTrue(succeeded)
  }

  func testMessageTranslationLanguagesUseSupportedLocaleIdentifiers() {
    XCTAssertEqual(MessageTranslationLanguage.english.rawValue, "en")
    XCTAssertEqual(MessageTranslationLanguage.simplifiedChinese.rawValue, "zh-Hans")
    XCTAssertEqual(MessageTranslationLanguage.japanese.rawValue, "ja")
    XCTAssertEqual(MessageTranslationLanguage.traditionalChinese.rawValue, "zh-Hant")
    XCTAssertEqual(MessageTranslationLanguage.spanish.rawValue, "es")
    XCTAssertEqual(MessageTranslationLanguage.britishEnglish.rawValue, "en-GB")
    XCTAssertEqual(MessageTranslationLanguage.french.rawValue, "fr")
    XCTAssertEqual(MessageTranslationLanguage.korean.rawValue, "ko")
    XCTAssertEqual(MessageTranslationLanguage(rawValue: "de")?.rawValue, "de")
    XCTAssertNil(MessageTranslationLanguage(rawValue: "unsupported"))
  }

  func testAppLanguageDefaultsFollowSupportedMacLanguages() {
    XCTAssertEqual(
      AppLanguageChannel.defaultLanguage(preferredLanguages: ["en-US"]),
      "en"
    )
    XCTAssertEqual(
      AppLanguageChannel.defaultLanguage(preferredLanguages: ["ja-JP"]),
      "ja"
    )
    XCTAssertEqual(
      AppLanguageChannel.defaultLanguage(preferredLanguages: ["zh-Hans-CN"]),
      "zh-Hans"
    )
    XCTAssertEqual(
      AppLanguageChannel.defaultLanguage(preferredLanguages: ["zh-Hant-TW"]),
      "en"
    )
  }

  private func makeWindow() -> NSWindow {
    NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1150, height: 750),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
  }
}
