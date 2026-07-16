import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  static let initialFrameSize = NSSize(width: 1180, height: 660)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setFrame(
      NSRect(origin: self.frame.origin, size: Self.initialFrameSize),
      display: true
    )
    self.center()
    self.title = "Instant Chat"
    self.titleVisibility = .visible

    if #available(macOS 11.0, *) {
      let titleToolbar = NSToolbar(identifier: "InstantChatTitleToolbar")
      titleToolbar.displayMode = .iconOnly
      self.toolbar = titleToolbar
      self.toolbarStyle = .unifiedCompact
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
