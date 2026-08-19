import Cocoa
import FlutterMacOS

final class DockVisibilityChannel {
  private static let channelName = "instant_chat/dock_visibility"
  private static let preferenceKey = "keepAppInDock"

  private let channel: FlutterMethodChannel

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getKeepAppInDock":
        result(Self.keepAppInDock)
      case "setKeepAppInDock":
        Self.setKeepAppInDock(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  static func applyStoredPreference() {
    _ = NSApp.setActivationPolicy(keepAppInDock ? .regular : .accessory)
  }

  private static var keepAppInDock: Bool {
    guard UserDefaults.standard.object(forKey: preferenceKey) != nil else {
      return true
    }
    return UserDefaults.standard.bool(forKey: preferenceKey)
  }

  private static func setKeepAppInDock(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
      let enabled = arguments["enabled"] as? Bool
    else {
      result(
        FlutterError(
          code: "invalid_dock_visibility_request",
          message: "The enabled value must be a Boolean.",
          details: nil
        )
      )
      return
    }
    DispatchQueue.main.async {
      guard NSApp.setActivationPolicy(enabled ? .regular : .accessory) else {
        result(
          FlutterError(
            code: "dock_visibility_update_failed",
            message: "The Dock visibility could not be changed.",
            details: nil
          )
        )
        return
      }
      UserDefaults.standard.set(enabled, forKey: preferenceKey)
      if enabled {
        NSApp.activate(ignoringOtherApps: true)
      }
      result(nil)
    }
  }
}
