import Cocoa
import FlutterMacOS

enum AppWindowMode: String {
  case authentication
  case main
}

class MainFlutterWindow: NSWindow {
  static let authenticationFrameSize = NSSize(width: 280, height: 360)
  static let mainFrameSize = NSSize(width: 1150, height: 750)
  static let mainMinimumFrameSize = NSSize(width: 960, height: 620)
  static let initialFrameSize = authenticationFrameSize
  private static let trafficLightOffset = NSPoint(x: 12, y: -8)
  private static let standardTrafficLightOrigin = NSPoint(x: 7, y: 6)
  private static let trafficLightSpacing = CGFloat(20)
  private var clipboardImageChannel: ClipboardImageChannel?
  private var messageTranslationChannel: MessageTranslationChannel?
  private var windowModeChannel: AppWindowModeChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "Instant Chat"
    Self.configureWindowChrome(self)
    Self.configureWindow(self, for: .authentication, animated: false)

    RegisterGeneratedPlugins(registry: flutterViewController)
    clipboardImageChannel = ClipboardImageChannel(
      controller: flutterViewController
    )
    messageTranslationChannel = MessageTranslationChannel(
      controller: flutterViewController
    )
    windowModeChannel = AppWindowModeChannel(
      controller: flutterViewController,
      window: self
    )
    configurePasteMenuItem()

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

  override func sendEvent(_ event: NSEvent) {
    if clipboardImageChannel?.handlePasteShortcut(event) == true {
      return
    }
    super.sendEvent(event)
  }

  @objc private func pasteFromMenu(_ sender: Any?) {
    if clipboardImageChannel?.handlePasteCommand() == true {
      return
    }
    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: sender)
  }

  private func configurePasteMenuItem() {
    DispatchQueue.main.async { [weak self] in
      guard let self,
        let editMenu = NSApp.mainMenu?.item(withTitle: "Edit")?.submenu,
        let pasteItem = editMenu.item(withTitle: "Paste")
      else {
        return
      }
      pasteItem.target = self
      pasteItem.action = #selector(self.pasteFromMenu(_:))
    }
  }

  static func configureWindowChrome(_ window: NSWindow) {
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.insert(.fullSizeContentView)
    window.isMovableByWindowBackground = true
  }

  static func configureWindow(
    _ window: NSWindow,
    for mode: AppWindowMode,
    animated: Bool
  ) {
    window.minSize = NSSize(width: 1, height: 1)
    window.maxSize = NSSize(width: 10_000, height: 10_000)

    let targetSize: NSSize
    switch mode {
    case .authentication:
      targetSize = authenticationFrameSize
      window.styleMask.remove(.resizable)
      window.standardWindowButton(.zoomButton)?.isEnabled = false
    case .main:
      targetSize = mainFrameSize
      window.styleMask.insert(.resizable)
      window.standardWindowButton(.zoomButton)?.isEnabled = true
    }

    window.setFrame(
      centeredFrame(for: targetSize, window: window),
      display: true,
      animate: animated
    )

    switch mode {
    case .authentication:
      window.minSize = authenticationFrameSize
      window.maxSize = authenticationFrameSize
    case .main:
      window.minSize = mainMinimumFrameSize
      window.maxSize = NSSize(width: 10_000, height: 10_000)
    }
    repositionWindowControls(in: window)
  }

  private static func centeredFrame(
    for size: NSSize,
    window: NSWindow
  ) -> NSRect {
    guard let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
      return NSRect(origin: window.frame.origin, size: size)
    }
    return NSRect(
      x: visibleFrame.midX - (size.width / 2),
      y: visibleFrame.midY - (size.height / 2),
      width: size.width,
      height: size.height
    )
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

private final class AppWindowModeChannel {
  private static let channelName = "instant_chat/window"
  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?

  init(controller: FlutterViewController, window: NSWindow) {
    self.window = window
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setMode" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let rawMode = call.arguments as? String,
        let mode = AppWindowMode(rawValue: rawMode),
        let window = self?.window
      else {
        result(
          FlutterError(
            code: "invalid_window_mode",
            message: "The requested window mode is invalid.",
            details: nil
          )
        )
        return
      }
      MainFlutterWindow.configureWindow(window, for: mode, animated: true)
      result(nil)
    }
  }
}

private final class ClipboardImageChannel {
  private static let channelName = "instant_chat/clipboard"
  private let channel: FlutterMethodChannel
  private var isPasteEnabled = false

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setPasteEnabled" {
        self?.isPasteEnabled = call.arguments as? Bool ?? false
        result(nil)
        return
      }
      guard call.method == "readImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        result(try self?.readImage())
      } catch {
        result(
          FlutterError(
            code: "clipboard_image_read_failed",
            message: "The clipboard image could not be read.",
            details: nil
          )
        )
      }
    }
  }

  func handlePasteShortcut(_ event: NSEvent) -> Bool {
    guard event.type == .keyDown,
      !event.isARepeat,
      event.modifierFlags.contains(.command),
      event.charactersIgnoringModifiers?.lowercased() == "v"
    else {
      return false
    }
    return handlePasteCommand()
  }

  func handlePasteCommand() -> Bool {
    guard isPasteEnabled, let image = try? readImage() else {
      return false
    }
    channel.invokeMethod("imagePasted", arguments: image)
    return true
  }

  private func readImage() throws -> [String: Any]? {
    let pasteboard = NSPasteboard.general
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
    ]
    if let urls = pasteboard.readObjects(
      forClasses: [NSURL.self],
      options: options
    ) as? [URL],
      let url = urls.first,
      NSImage(contentsOf: url) != nil
    {
      return ["path": url.path, "is_temporary": false]
    }

    let imageData: Data?
    if let png = pasteboard.data(forType: .png) {
      imageData = png
    } else if let tiff = pasteboard.data(forType: .tiff),
      let bitmap = NSBitmapImageRep(data: tiff)
    {
      imageData = bitmap.representation(using: .png, properties: [:])
    } else {
      imageData = nil
    }
    guard let imageData else {
      return nil
    }

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("instant-chat-clipboard-\(UUID().uuidString).png")
    try imageData.write(to: url, options: .atomic)
    return ["path": url.path, "is_temporary": true]
  }
}
