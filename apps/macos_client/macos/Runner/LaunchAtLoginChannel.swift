import FlutterMacOS
import ServiceManagement

final class LaunchAtLoginChannel {
  private static let channelName = "instant_chat/launch_at_login"

  private let channel: FlutterMethodChannel

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getStatus":
        Self.getStatus(result: result)
      case "setEnabled":
        Self.setEnabled(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private static func getStatus(result: FlutterResult) {
    guard #available(macOS 13.0, *) else {
      result("unsupported")
      return
    }
    returnStatus(of: SMAppService.mainApp, result: result)
  }

  private static func setEnabled(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let enabled = arguments["enabled"] as? Bool
    else {
      result(
        FlutterError(
          code: "invalid_launch_at_login_request",
          message: "The enabled value must be a Boolean.",
          details: nil
        )
      )
      return
    }
    guard #available(macOS 13.0, *) else {
      result("unsupported")
      return
    }

    let service = SMAppService.mainApp
    do {
      if enabled {
        if service.status == .requiresApproval {
          SMAppService.openSystemSettingsLoginItems()
        } else if service.status != .enabled {
          try service.register()
        }
      } else if service.status != .notRegistered {
        try service.unregister()
      }
      if service.status == .requiresApproval {
        SMAppService.openSystemSettingsLoginItems()
      }
      returnStatus(of: service, result: result)
    } catch {
      result(
        FlutterError(
          code: "launch_at_login_update_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  @available(macOS 13.0, *)
  private static func returnStatus(
    of service: SMAppService,
    result: FlutterResult
  ) {
    switch service.status {
    case .notRegistered:
      result("disabled")
    case .enabled:
      result("enabled")
    case .requiresApproval:
      result("requires_approval")
    case .notFound:
      result(
        FlutterError(
          code: "launch_at_login_unavailable",
          message: "The login item could not be found.",
          details: nil
        )
      )
    @unknown default:
      result(
        FlutterError(
          code: "unknown_launch_at_login_status",
          message: "The login item returned an unknown status.",
          details: nil
        )
      )
    }
  }
}
