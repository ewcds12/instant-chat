import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sends dropped images and files in order with scoped access', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'instant-chat-drop-test-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final image = File('${directory.path}/photo.PNG');
    final document = File('${directory.path}/notes.txt');
    image.writeAsBytesSync([1, 2, 3]);
    document.writeAsStringSync('Notes');
    final gateway = StubMessageGateway(_session.user);
    final container = await _container(gateway);
    addTearDown(container.dispose);
    final scopedCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('desktop_drop'), (
          call,
        ) async {
          scopedCalls.add(call.method);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('desktop_drop'), null),
    );
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-composer')));

    await _invokePlatformMethod(const MethodCall('entered', [50.0, 100.0]));
    await tester.pump();
    expect(find.text('Release to send'), findsOneWidget);
    await tester.runAsync(
      () => _dropAndWait(
        MethodCall('performOperation_macos', [
          _dropItem(image.path),
          _dropItem(document.path),
        ]),
        () => gateway.sentAttachmentPaths.length == 2,
      ),
    );
    await tester.pump();

    expect(gateway.sentAttachmentPaths, [image.path, document.path]);
    expect(scopedCalls, [
      'startAccessingSecurityScopedResource',
      'stopAccessingSecurityScopedResource',
      'startAccessingSecurityScopedResource',
      'stopAccessingSecurityScopedResource',
    ]);
  });

  testWidgets('rejects dropped folders without sending', (tester) async {
    final gateway = StubMessageGateway(_session.user);
    final container = await _container(gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-composer')));

    await _invokePlatformMethod(const MethodCall('entered', [50.0, 100.0]));
    await tester.runAsync(
      () => _dropAndWait(
        const MethodCall('performOperation_macos', [
          {'path': '/tmp/folder', 'isDirectory': true, 'fromPromise': false},
        ]),
        () => true,
      ),
    );
    await tester.pump();

    expect(find.text("Folders can't be sent."), findsOneWidget);
    expect(gateway.sentAttachmentPaths, isEmpty);
  });
}

Map<String, Object> _dropItem(String path) => {
  'path': path,
  'apple-bookmark': Uint8List.fromList([1, 2, 3]),
  'isDirectory': false,
  'fromPromise': false,
};

Future<ProviderContainer> _container(StubMessageGateway gateway) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _StubAuthController(AuthState(session: _session)),
      ),
      messageGatewayProvider.overrideWithValue(gateway),
      conversationGatewayProvider.overrideWithValue(StubConversationGateway()),
      conversationRecoveryIntervalProvider.overrideWithValue(null),
      messageRecoveryIntervalProvider.overrideWithValue(null),
      realtimeConnectionProvider.overrideWithValue(
        const StubRealtimeConnection(),
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

Future<void> _invokePlatformMethod(MethodCall call) async {
  final completer = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'desktop_drop',
        const StandardMethodCodec().encodeMethodCall(call),
        completer.complete,
      );
  await completer.future;
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

Future<void> _dropAndWait(MethodCall call, bool Function() predicate) async {
  await _invokePlatformMethod(call);
  for (var attempt = 0; attempt < 30; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (predicate()) {
      return;
    }
  }
  fail('Timed out waiting for dropped files to send.');
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
