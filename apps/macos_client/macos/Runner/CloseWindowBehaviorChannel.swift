import FlutterMacOS

enum CloseWindowBehavior: String {
  case keepRunning = "keep_running"
  case quitApplication = "quit_application"
}

enum CloseWindowBehaviorPreference {
  private static let preferenceKey = "closeWindowBehavior"

  static var current: CloseWindowBehavior {
    guard let storedValue = UserDefaults.standard.string(forKey: preferenceKey),
      let behavior = CloseWindowBehavior(rawValue: storedValue)
    else {
      return .keepRunning
    }
    return behavior
  }

  static func set(_ behavior: CloseWindowBehavior) {
    UserDefaults.standard.set(behavior.rawValue, forKey: preferenceKey)
  }
}

final class CloseWindowBehaviorChannel {
  private static let channelName = "instant_chat/close_window_behavior"

  private let channel: FlutterMethodChannel

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getBehavior":
        result(CloseWindowBehaviorPreference.current.rawValue)
      case "setBehavior":
        Self.setBehavior(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private static func setBehavior(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
      let rawBehavior = arguments["behavior"] as? String,
      let behavior = CloseWindowBehavior(rawValue: rawBehavior)
    else {
      result(
        FlutterError(
          code: "invalid_close_window_behavior",
          message: "The close-window behavior is invalid.",
          details: nil
        )
      )
      return
    }
    CloseWindowBehaviorPreference.set(behavior)
    result(nil)
  }
}
