import FlutterMacOS

final class AppLanguageChannel {
  static let supportedCodes = ["en", "ja", "zh-Hans"]
  private static let channelName = "instant_chat/app_language"
  private static let preferenceKey = "appLanguage"
  private static let changeNotification = Notification.Name(
    "InstantChatAppLanguageChanged"
  )

  private let channel: FlutterMethodChannel
  private var observer: NSObjectProtocol?

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      Self.handle(call, result: result)
    }
    observer = NotificationCenter.default.addObserver(
      forName: Self.changeNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let code = notification.object as? String else {
        return
      }
      self?.channel.invokeMethod("languageChanged", arguments: code)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  static func defaultLanguage(preferredLanguages: [String]) -> String {
    guard let preferred = preferredLanguages.first?.lowercased() else {
      return "en"
    }
    if preferred.hasPrefix("ja") {
      return "ja"
    }
    let usesSimplifiedChinese = preferred.hasPrefix("zh-hans")
      || preferred.hasPrefix("zh-cn")
      || preferred.hasPrefix("zh-sg")
    return usesSimplifiedChinese ? "zh-Hans" : "en"
  }

  private static var currentLanguage: String {
    let stored = UserDefaults.standard.string(forKey: preferenceKey)
    if let stored, supportedCodes.contains(stored) {
      return stored
    }
    return defaultLanguage(preferredLanguages: Locale.preferredLanguages)
  }

  private static func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "getLanguage":
      result(currentLanguage)
    case "setLanguage":
      setLanguage(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func setLanguage(arguments: Any?, result: FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let code = values["code"] as? String,
      supportedCodes.contains(code)
    else {
      result(
        FlutterError(
          code: "invalid_app_language",
          message: "The selected app language is not supported.",
          details: nil
        )
      )
      return
    }
    UserDefaults.standard.set(code, forKey: preferenceKey)
    NotificationCenter.default.post(name: changeNotification, object: code)
    result(nil)
  }
}
