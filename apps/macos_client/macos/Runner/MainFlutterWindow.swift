import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  static let initialFrameSize = NSSize(width: 1300, height: 780)
  private static let trafficLightOffset = NSPoint(x: 12, y: -8)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setFrame(
      NSRect(origin: self.frame.origin, size: Self.initialFrameSize),
      display: true
    )
    self.center()
    self.title = "Instant Chat"
    Self.configureWindowChrome(self)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      Self.repositionWindowControls(in: self)
    }
  }

  static func configureWindowChrome(_ window: NSWindow) {
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.insert(.fullSizeContentView)
    window.isMovableByWindowBackground = true
  }

  static func repositionWindowControls(in window: NSWindow) {
    let buttons = [
      window.standardWindowButton(.closeButton),
      window.standardWindowButton(.miniaturizeButton),
      window.standardWindowButton(.zoomButton),
    ]
    for button in buttons.compactMap({ $0 }) {
      button.setFrameOrigin(
        NSPoint(
          x: button.frame.minX + trafficLightOffset.x,
          y: button.frame.minY + trafficLightOffset.y
        )
      )
    }
  }
}
