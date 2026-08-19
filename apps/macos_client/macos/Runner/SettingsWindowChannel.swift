import Cocoa
import FlutterMacOS

final class SettingsWindowChannel: NSObject, NSWindowDelegate {
  private static let channelName = "instant_chat/settings_window"
  private static let windowSize = NSSize(width: 920, height: 620)
  private static let minimumWindowSize = NSSize(width: 760, height: 500)

  private let channel: FlutterMethodChannel
  private var launchAtLoginChannel: LaunchAtLoginChannel?
  private var urlLauncherChannel: URLLauncherChannel?
  private var settingsWindow: NSWindow?
  private var settingsEngine: FlutterEngine?

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.openSettingsWindow(result: result)
    }
  }

  private func openSettingsWindow(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result(nil)
        return
      }
      if let settingsWindow = self.settingsWindow {
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)
        result(nil)
        return
      }

      let engine = FlutterEngine(name: "instant-chat-settings", project: nil)
      guard engine.run(withEntrypoint: "settingsMain") else {
        result(
          FlutterError(
            code: "settings_window_launch_failed",
            message: "The settings window could not be started.",
            details: nil
          )
        )
        return
      }

      let viewController = FlutterViewController(
        engine: engine,
        nibName: nil,
        bundle: nil
      )
      let launchAtLoginChannel = LaunchAtLoginChannel(
        controller: viewController
      )
      let urlLauncherChannel = URLLauncherChannel(controller: viewController)
      viewController.backgroundColor = NSColor(
        calibratedRed: 0.98,
        green: 0.99,
        blue: 1.0,
        alpha: 1.0
      )
      let window = NSWindow(
        contentRect: NSRect(origin: .zero, size: Self.windowSize),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
      )
      window.title = "Settings"
      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
      window.isMovableByWindowBackground = true
      window.isReleasedWhenClosed = false
      window.minSize = Self.minimumWindowSize
      window.contentViewController = viewController
      window.delegate = self
      window.center()

      self.settingsEngine = engine
      self.launchAtLoginChannel = launchAtLoginChannel
      self.urlLauncherChannel = urlLauncherChannel
      self.settingsWindow = window
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
      result(nil)
    }
  }

  func windowWillClose(_ notification: Notification) {
    settingsWindow = nil
    launchAtLoginChannel = nil
    urlLauncherChannel = nil
    settingsEngine?.shutDownEngine()
    settingsEngine = nil
  }
}
