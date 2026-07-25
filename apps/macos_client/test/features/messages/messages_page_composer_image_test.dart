import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_clipboard_image.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';

void main() {
  testWidgets('pastes and sends an image together with text', (tester) async {
    final clipboard = _StubClipboardImage('/tmp/copied-image.png');
    final gateway = StubMessageGateway(_session.user);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        localClipboardImageProvider.overrideWithValue(clipboard),
        messageGatewayProvider.overrideWithValue(gateway),
        conversationRecoveryIntervalProvider.overrideWithValue(null),
        messageRecoveryIntervalProvider.overrideWithValue(null),
        conversationGatewayProvider.overrideWithValue(
          StubConversationGateway(),
        ),
        realtimeConnectionProvider.overrideWithValue(
          const StubRealtimeConnection(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-composer')));
    await tester.tap(find.byKey(const Key('message-composer')));

    await _pressPaste(tester);
    await _pumpUntil(
      tester,
      find.byKey(const Key('message-composer-image-preview')),
    );
    await tester.enterText(
      find.byKey(const Key('message-composer')),
      'Keep this text',
    );
    await tester.tap(find.byKey(const Key('message-composer-image-remove')));
    await tester.pump();
    expect(
      find.byKey(const Key('message-composer-image-preview')),
      findsNothing,
    );
    expect(clipboard.releasedPaths, ['/tmp/copied-image.png']);
    final fieldAfterRemoval = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(fieldAfterRemoval.controller?.text, 'Keep this text');

    await _pressPaste(tester);
    await _pumpUntil(
      tester,
      find.byKey(const Key('message-composer-image-preview')),
    );
    await tester.enterText(
      find.byKey(const Key('message-composer')),
      'Hello guys!',
    );
    await tester.tap(find.byKey(const Key('message-send-button')));
    await _pumpUntilValue(tester, () => gateway.sentBody);

    expect(gateway.sentImagePath, '/tmp/copied-image.png');
    expect(gateway.sentBody, 'Hello guys!');
    expect(clipboard.releasedPaths, [
      '/tmp/copied-image.png',
      '/tmp/copied-image.png',
    ]);
    expect(
      find.byKey(const Key('message-composer-image-preview')),
      findsNothing,
    );
    final field = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(field.controller?.text, isEmpty);
  });
}

Future<void> _pressPaste(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

Widget _messagesPage(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(body: MessagesPage(conversation: _conversation)),
    ),
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder.');
}

Future<void> _pumpUntilValue(
  WidgetTester tester,
  String? Function() value,
) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (value() != null) {
      return;
    }
  }
  fail('Timed out waiting for a sent value.');
}

class _StubClipboardImage implements LocalClipboardImage {
  _StubClipboardImage(this.path);

  final String path;
  final List<String> releasedPaths = [];

  @override
  Future<ClipboardImage?> read() async {
    return ClipboardImage(path: path, isTemporary: true);
  }

  @override
  Future<void> release(ClipboardImage image) async {
    releasedPaths.add(image.path);
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

final _session = AuthSession(
  user: AuthUser(
    id: '42',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 25),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 25, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 25),
);

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'sam',
    displayName: 'Sam',
    createdAt: DateTime.utc(2026, 7, 25),
  ),
  createdAt: DateTime.utc(2026, 7, 25, 12),
  updatedAt: DateTime.utc(2026, 7, 25, 12),
  unreadCount: 0,
);
