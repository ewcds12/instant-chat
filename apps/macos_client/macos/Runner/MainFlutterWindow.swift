import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  static let initialFrameSize = NSSize(width: 1300, height: 750)
  private static let trafficLightOffset = NSPoint(x: 12, y: -8)
  private static let standardTrafficLightOrigin = NSPoint(x: 7, y: 6)
  private static let trafficLightSpacing = CGFloat(20)

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
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(repositionWindowControlsAfterResize),
      name: NSWindow.didResizeNotification,
      object: self
    )
    scheduleInitialWindowControlReposition()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
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
    for (index, button) in buttons.compactMap({ $0 }).enumerated() {
      button.setFrameOrigin(
        NSPoint(
          x: standardTrafficLightOrigin.x + trafficLightOffset.x +
            (CGFloat(index) * trafficLightSpacing),
          y: standardTrafficLightOrigin.y + trafficLightOffset.y
        )
      )
    }
  }

  @objc private func repositionWindowControlsAfterResize() {
    Self.repositionWindowControls(in: self)
  }

  private func scheduleInitialWindowControlReposition() {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      Self.repositionWindowControls(in: self)
    }
  }
}
