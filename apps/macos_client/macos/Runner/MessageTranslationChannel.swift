import Cocoa
import FlutterMacOS
import SwiftUI
import Translation

enum MessageTranslationLanguage: String, CaseIterable {
  case english = "en"
  case simplifiedChinese = "zh-Hans"
  case japanese = "ja"

  @available(macOS 15.0, *)
  var localeLanguage: Locale.Language {
    Locale.Language(identifier: rawValue)
  }
}

@MainActor
final class MessageTranslationChannel {
  private static let channelName = "instant_chat/message_translation"
  private static let preferenceKey = "message_translation_target_language"
  private static let translationStorePrefix = "message_translations"

  private let channel: FlutterMethodChannel
  private weak var controller: FlutterViewController?
  private var translationHosts: [UUID: NSView] = [:]

  init(controller: FlutterViewController) {
    self.controller = controller
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
    case "getTargetLanguage":
      result(UserDefaults.standard.string(forKey: Self.preferenceKey))
    case "setTargetLanguage":
      guard let code = call.arguments as? String,
        MessageTranslationLanguage(rawValue: code) != nil
      else {
        result(invalidArgumentsError)
        return
      }
      UserDefaults.standard.set(code, forKey: Self.preferenceKey)
      result(nil)
    case "getStoredTranslations":
      guard let arguments = call.arguments as? [String: Any],
        let accountID = arguments["account_id"] as? String,
        !accountID.isEmpty,
        let conversationID = arguments["conversation_id"] as? String,
        !conversationID.isEmpty,
        let targetCode = arguments["target_language"] as? String,
        let target = MessageTranslationLanguage(rawValue: targetCode)
      else {
        result(invalidArgumentsError)
        return
      }
      let key = translationStoreKey(
        accountID: accountID,
        conversationID: conversationID,
        target: target
      )
      let translations = UserDefaults.standard.dictionary(forKey: key)?
        .compactMapValues { $0 as? String } ?? [:]
      result(translations)
    case "storeTranslation":
      guard let arguments = call.arguments as? [String: Any],
        let accountID = arguments["account_id"] as? String,
        !accountID.isEmpty,
        let conversationID = arguments["conversation_id"] as? String,
        !conversationID.isEmpty,
        let messageID = arguments["message_id"] as? String,
        !messageID.isEmpty,
        let targetCode = arguments["target_language"] as? String,
        let target = MessageTranslationLanguage(rawValue: targetCode),
        let translatedText = arguments["translated_text"] as? String,
        !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(invalidArgumentsError)
        return
      }
      let key = translationStoreKey(
        accountID: accountID,
        conversationID: conversationID,
        target: target
      )
      var translations = UserDefaults.standard.dictionary(forKey: key)?
        .compactMapValues { $0 as? String } ?? [:]
      translations[messageID] = translatedText
      UserDefaults.standard.set(translations, forKey: key)
      result(nil)
    case "translate":
      guard let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let targetCode = arguments["target_language"] as? String,
        let target = MessageTranslationLanguage(rawValue: targetCode)
      else {
        result(invalidArgumentsError)
        return
      }
      guard #available(macOS 15.0, *) else {
        result(
          FlutterError(
            code: "translation_unavailable",
            message: "Translation requires macOS 15 or later.",
            details: nil
          )
        )
        return
      }
      startTranslation(text: text, target: target, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var invalidArgumentsError: FlutterError {
    FlutterError(
      code: "invalid_translation_request",
      message: "The translation request is invalid.",
      details: nil
    )
  }

  private func translationStoreKey(
    accountID: String,
    conversationID: String,
    target: MessageTranslationLanguage
  ) -> String {
    let account = Data(accountID.utf8).base64EncodedString()
    let conversation = Data(conversationID.utf8).base64EncodedString()
    return "\(Self.translationStorePrefix).\(account).\(conversation).\(target.rawValue)"
  }

  @available(macOS 15.0, *)
  private func startTranslation(
    text: String,
    target: MessageTranslationLanguage,
    result: @escaping FlutterResult
  ) {
    guard let controller else {
      result(
        FlutterError(
          code: "translation_unavailable",
          message: "Translation is unavailable.",
          details: nil
        )
      )
      return
    }
    let identifier = UUID()
    let request = MessageTranslationRequest(
      text: text,
      target: target.localeLanguage
    ) { [weak self] outcome in
      self?.completeTranslation(identifier, outcome: outcome, result: result)
    }
    let host = NSHostingView(rootView: MessageTranslationHost(request: request))
    host.frame = NSRect(x: -2, y: -2, width: 1, height: 1)
    host.alphaValue = 0.01
    controller.view.addSubview(host)
    translationHosts[identifier] = host
  }

  @available(macOS 15.0, *)
  private func completeTranslation(
    _ identifier: UUID,
    outcome: Result<String, Error>,
    result: @escaping FlutterResult
  ) {
    translationHosts.removeValue(forKey: identifier)?.removeFromSuperview()
    switch outcome {
    case .success(let translatedText):
      result(translatedText)
    case .failure:
      result(
        FlutterError(
          code: "translation_failed",
          message: "Translation could not be completed.",
          details: nil
        )
      )
    }
  }
}

@available(macOS 15.0, *)
@MainActor
private final class MessageTranslationRequest {
  let text: String
  let target: Locale.Language
  private let completion: (Result<String, Error>) -> Void
  private var isComplete = false

  init(
    text: String,
    target: Locale.Language,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    self.text = text
    self.target = target
    self.completion = completion
  }

  func perform(using session: TranslationSession) async {
    guard !isComplete else {
      return
    }
    do {
      let response = try await session.translate(text)
      finish(with: .success(response.targetText))
    } catch {
      finish(with: .failure(error))
    }
  }

  private func finish(with outcome: Result<String, Error>) {
    guard !isComplete else {
      return
    }
    isComplete = true
    completion(outcome)
  }
}

@available(macOS 15.0, *)
private struct MessageTranslationHost: View {
  let request: MessageTranslationRequest
  @State private var configuration: TranslationSession.Configuration

  init(request: MessageTranslationRequest) {
    self.request = request
    _configuration = State(
      initialValue: TranslationSession.Configuration(
        source: nil,
        target: request.target
      )
    )
  }

  var body: some View {
    Color.clear
      .frame(width: 1, height: 1)
      .translationTask(configuration) { session in
        await request.perform(using: session)
      }
  }
}
