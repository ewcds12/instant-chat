import Cocoa
import FlutterMacOS
import XCTest
@testable import Instant_Chat

class RunnerTests: XCTestCase {
  func testInitialWindowSizeMatchesDesignReference() {
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.width, 1180)
    XCTAssertEqual(MainFlutterWindow.initialFrameSize.height, 660)
  }
}
