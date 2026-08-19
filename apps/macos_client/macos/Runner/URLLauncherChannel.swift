import Cocoa
import FlutterMacOS
import WebKit

final class URLLauncherChannel {
  private static let channelName = "instant_chat/url_launcher"
  private static let preferenceKey = "openLinksInDefaultBrowser"

  private let channel: FlutterMethodChannel
  private var browserWindowController: InAppBrowserWindowController?

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getOpenLinksInDefaultBrowser":
      result(openLinksInDefaultBrowser)
    case "setOpenLinksInDefaultBrowser":
      guard let arguments = call.arguments as? [String: Any],
        let enabled = arguments["enabled"] as? Bool
      else {
        result(invalidArgumentsError)
        return
      }
      UserDefaults.standard.set(enabled, forKey: Self.preferenceKey)
      result(nil)
    case "open":
      guard let arguments = call.arguments as? [String: Any],
        let value = arguments["url"] as? String,
        let url = URL(string: value),
        ["http", "https"].contains(url.scheme?.lowercased() ?? "")
      else {
        result(invalidArgumentsError)
        return
      }
      open(url, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var openLinksInDefaultBrowser: Bool {
    guard UserDefaults.standard.object(forKey: Self.preferenceKey) != nil else {
      return true
    }
    return UserDefaults.standard.bool(forKey: Self.preferenceKey)
  }

  private var invalidArgumentsError: FlutterError {
    FlutterError(
      code: "invalid_link_arguments",
      message: "The link settings request is invalid.",
      details: nil
    )
  }

  private func open(_ url: URL, result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result(nil)
        return
      }
      if self.openLinksInDefaultBrowser {
        guard NSWorkspace.shared.open(url) else {
          result(
            FlutterError(
              code: "link_open_failed",
              message: "The link could not be opened.",
              details: nil
            )
          )
          return
        }
      } else {
        let controller = self.browserWindowController ?? InAppBrowserWindowController()
        self.browserWindowController = controller
        controller.open(url)
      }
      result(nil)
    }
  }
}

private final class InAppBrowserWindowController: NSWindowController, WKNavigationDelegate {
  private static let windowSize = NSSize(width: 980, height: 700)
  private static let minimumWindowSize = NSSize(width: 720, height: 480)

  private let webView: WKWebView

  init() {
    webView = WKWebView(frame: .zero)
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: Self.windowSize),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.minSize = Self.minimumWindowSize
    window.isReleasedWhenClosed = false
    window.contentView = webView
    window.center()
    super.init(window: window)
    webView.navigationDelegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func open(_ url: URL) {
    window?.title = url.host ?? "Web"
    webView.load(URLRequest(url: url))
    NSApp.activate(ignoringOtherApps: true)
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    guard let url = navigationAction.request.url,
      let scheme = url.scheme?.lowercased(),
      !["http", "https"].contains(scheme)
    else {
      decisionHandler(.allow)
      return
    }
    NSWorkspace.shared.open(url)
    decisionHandler(.cancel)
  }
}
