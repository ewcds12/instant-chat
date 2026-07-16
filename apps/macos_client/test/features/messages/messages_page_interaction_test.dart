import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';

void main() {
  testWidgets('returns focus to the composer after sending', (tester) async {
    final gateway = StubMessageGateway(_session.user);
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-composer')));

    await tester.enterText(find.byKey(const Key('message-composer')), 'Hello.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final composer = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(gateway.sentBody, 'Hello.');
    expect(find.text('Hello.'), findsOneWidget);
    expect(composer.focusNode?.hasFocus, isTrue);
  });

  testWidgets('scrolls to the newest realtime message', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final realtime = StreamRealtimeConnection();
    addTearDown(realtime.close);
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: List.generate(
        28,
        (index) => _message('$index', 'Message $index', sequence: '$index'),
      ),
    );
    final container = await _container(gateway: gateway, realtime: realtime);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-history-list')));
    await container.read(messagesControllerProvider(_conversation.id).future);
    await tester.runAsync(_flushEvents);
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('message-history-list')),
      const Offset(0, 420),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    realtime.emit(_message('99', 'Newest update', sequence: '99'));
    await tester.runAsync(_flushEvents);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(_flushEvents);
    await tester.pump();

    expect(
      container
          .read(messagesControllerProvider(_conversation.id))
          .requireValue
          .messages
          .last
          .body,
      'Newest update',
    );
    final listView = tester.widget<ListView>(
      find.byKey(const Key('message-history-list')),
    );
    final position = listView.controller!.position;
    expect(
      position.pixels,
      moreOrLessEquals(position.maxScrollExtent, epsilon: 1),
    );
  });
}

Future<ProviderContainer> _container({
  required StubMessageGateway gateway,
  StreamRealtimeConnection? realtime,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _StubAuthController(AuthState(session: _session)),
      ),
      messageGatewayProvider.overrideWithValue(gateway),
      realtimeConnectionProvider.overrideWithValue(
        realtime ?? const StubRealtimeConnection(),
      ),
    ],
  );
  await container.read(authControllerProvider.future);
  return container;
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

Message _message(String id, String body, {required String sequence}) {
  return Message(
    id: id,
    conversationId: _conversation.id,
    sender: _conversation.peer,
    clientMessageId: 'client-$id',
    sequence: sequence,
    body: body,
    createdAt: DateTime.utc(2026, 7, 15, 13),
  );
}

final _session = AuthSession(
  user: AuthUser(
    id: '42',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 15, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 15),
);

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'other_user',
    displayName: 'Other User',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  createdAt: DateTime.utc(2026, 7, 15, 12),
  updatedAt: DateTime.utc(2026, 7, 15, 12),
);

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
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

Future<void> _flushEvents() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}
