import Cocoa
import FlutterMacOS
import XCTest
@testable import Instant_Chat

class RunnerTests: XCTestCase {
  func testInitialWindowSizeMatchesDesignReference() {
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.width, 1180)
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.height, 660)
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
  }
}
