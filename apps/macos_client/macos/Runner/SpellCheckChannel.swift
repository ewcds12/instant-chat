import Cocoa
import FlutterMacOS

final class SpellCheckChannel {
  private static let channelName = "instant_chat/spell_check"
  private static let preferenceKey = "checkSpellingWhileTyping"
  private static let changeNotification = Notification.Name(
    "InstantChatSpellCheckChanged"
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
      guard let enabled = notification.object as? Bool else { return }
      self?.channel.invokeMethod("enabledChanged", arguments: enabled)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }

  private static var isEnabled: Bool {
    guard UserDefaults.standard.object(forKey: preferenceKey) != nil else {
      return true
    }
    return UserDefaults.standard.bool(forKey: preferenceKey)
  }

  private static func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "getEnabled":
      result(isEnabled)
    case "setEnabled":
      guard let values = call.arguments as? [String: Any],
        let enabled = values["enabled"] as? Bool
      else {
        result(invalidArgumentsError)
        return
      }
      UserDefaults.standard.set(enabled, forKey: preferenceKey)
      NotificationCenter.default.post(name: changeNotification, object: enabled)
      result(nil)
    case "check":
      check(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func check(arguments: Any?, result: FlutterResult) {
    guard let values = arguments as? [String: Any],
      let language = values["language"] as? String,
      let text = values["text"] as? String
    else {
      result(invalidArgumentsError)
      return
    }
    let checker = NSSpellChecker.shared
    let source = text as NSString
    let tag = NSSpellChecker.uniqueSpellDocumentTag()
    defer { checker.closeSpellDocument(withTag: tag) }
    var offset = 0
    var matches = [[String: Any]]()
    while offset < source.length {
      let range = checker.checkSpelling(
        of: text,
        startingAt: offset,
        language: language,
        wrap: false,
        inSpellDocumentWithTag: tag,
        wordCount: nil
      )
      guard range.location != NSNotFound, range.length > 0 else { break }
      let suggestions = checker.guesses(
        forWordRange: range,
        in: text,
        language: language,
        inSpellDocumentWithTag: tag
      ) ?? []
      matches.append([
        "startIndex": range.location,
        "endIndex": NSMaxRange(range),
        "suggestions": Array(suggestions.prefix(5)),
      ])
      offset = NSMaxRange(range)
    }
    result(matches)
  }

  private static var invalidArgumentsError: FlutterError {
    FlutterError(
      code: "invalid_spell_check_arguments",
      message: "The spell check request is invalid.",
      details: nil
    )
  }
}
