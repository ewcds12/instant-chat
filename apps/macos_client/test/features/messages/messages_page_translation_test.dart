import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_message_translation.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/message_controller_stubs.dart';
import '../../support/widget_network_stubs.dart';

void main() {
  testWidgets('requires a target language and shows translation below text', (
    tester,
  ) async {
    final translation = _StubMessageTranslation();
    final container = await _container(translation);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const ValueKey('message-bubble-1')));
    final bubbleFinder = find.byKey(const ValueKey('message-bubble-1'));
    final originalBubbleWidth = tester.getSize(bubbleFinder).width;

    await _rightClick(tester, bubbleFinder);
    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('message-translation-language-dialog')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsNothing);
    expect(translation.translateCount, 0);

    await tester.tap(
      find.byKey(const ValueKey('message-translation-language-zh-Hans')),
    );
    await tester.pump();

    expect(
      translation.savedLanguage,
      MessageTranslationLanguage.simplifiedChinese,
    );
    expect(find.text('Translating…'), findsOneWidget);
    expect(find.text('Hello.'), findsOneWidget);

    translation.complete('这是一段明显长于原文并且必须按照原气泡宽度自动换行的译文。');
    await tester.pump();

    expect(find.text('Hello.'), findsOneWidget);
    expect(find.text('这是一段明显长于原文并且必须按照原气泡宽度自动换行的译文。'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('message-translation-text-1')),
      findsOneWidget,
    );
    expect(
      tester.getSize(bubbleFinder).width,
      moreOrLessEquals(originalBubbleWidth),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('message-translation-text-1')))
          .height,
      greaterThan(20),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('message-translation-text-1')),
    );

    expect(find.text('这是一段明显长于原文并且必须按照原气泡宽度自动换行的译文。'), findsOneWidget);
    expect(translation.translateCount, 1);
  });

  testWidgets('opens language settings without translating the message', (
    tester,
  ) async {
    final translation = _StubMessageTranslation(
      currentLanguage: MessageTranslationLanguage.english,
    );
    final container = await _container(translation);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const ValueKey('message-bubble-1')));

    await _rightClick(tester, find.byKey(const ValueKey('message-bubble-1')));
    await tester.tap(find.byKey(const Key('message-translation-settings')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('message-translation-language-dialog')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('message-translation-language-ja')),
    );
    await tester.pumpAndSettle();

    expect(translation.savedLanguage, MessageTranslationLanguage.japanese);
    expect(translation.translateCount, 0);
    expect(find.text('Translating…'), findsNothing);
  });
}

Future<ProviderContainer> _container(
  _StubMessageTranslation translation,
) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => StubAuthController(AuthState(session: testAuthSession)),
      ),
      localMessageTranslationProvider.overrideWithValue(translation),
      messageGatewayProvider.overrideWithValue(
        StubMessageGateway(testAuthSession.user, initialMessages: [_message]),
      ),
      conversationRecoveryIntervalProvider.overrideWithValue(null),
      messageRecoveryIntervalProvider.overrideWithValue(null),
      conversationGatewayProvider.overrideWithValue(StubConversationGateway()),
      realtimeConnectionProvider.overrideWithValue(
        const StubRealtimeConnection(),
      ),
    ],
  );
  await container.read(authControllerProvider.future);
  return container;
}

Widget _messagesPage(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: RetroTheme.data,
    home: Scaffold(body: MessagesPage(conversation: _conversation)),
  ),
);

Future<void> _rightClick(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder.');
}

class _StubMessageTranslation implements LocalMessageTranslation {
  _StubMessageTranslation({this.currentLanguage});

  MessageTranslationLanguage? currentLanguage;
  MessageTranslationLanguage? savedLanguage;
  var translateCount = 0;
  Completer<String>? _translation;
  final _storedTranslations = <String, String>{};

  @override
  Future<MessageTranslationLanguage?> getTargetLanguage() async =>
      currentLanguage;

  @override
  Future<void> setTargetLanguage(MessageTranslationLanguage language) async {
    currentLanguage = language;
    savedLanguage = language;
  }

  @override
  Future<Map<String, String>> getStoredTranslations({
    required String accountId,
    required String conversationId,
    required MessageTranslationLanguage targetLanguage,
  }) async => Map.unmodifiable(_storedTranslations);

  @override
  Future<void> storeTranslation({
    required String accountId,
    required String conversationId,
    required String messageId,
    required MessageTranslationLanguage targetLanguage,
    required String translatedText,
  }) async {
    _storedTranslations[messageId] = translatedText;
  }

  @override
  Future<String> translate({
    required String text,
    required MessageTranslationLanguage targetLanguage,
  }) {
    translateCount += 1;
    _translation = Completer<String>();
    return _translation!.future;
  }

  void complete(String text) => _translation!.complete(text);
}

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: _peer,
  createdAt: DateTime.utc(2026, 8, 5),
  updatedAt: DateTime.utc(2026, 8, 5),
  unreadCount: 0,
);

final _peer = PublicUser(
  id: '8',
  username: 'other_user',
  displayName: 'Other User',
  createdAt: DateTime.utc(2026, 8, 5),
);

final _message = Message(
  id: '1',
  conversationId: '11',
  sender: _peer,
  clientMessageId: '00000000000000000000000000000001',
  sequence: '1',
  kind: MessageKind.text,
  body: 'Hello.',
  image: null,
  createdAt: DateTime.utc(2026, 8, 5, 12),
);
