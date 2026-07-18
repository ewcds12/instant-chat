import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
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
  testWidgets('renders file messages with a dedicated file card', (
    tester,
  ) async {
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [_fileMessage('file-1', sequence: '1')],
    );
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-file-file-1')));
    await tester.pump();

    expect(find.byKey(const Key('message-file-file-1')), findsOneWidget);
    expect(find.byKey(const Key('message-bubble-file-1')), findsNothing);
    expect(find.text('Notes.pdf'), findsOneWidget);
  });

  testWidgets('cancels the native file action without downloading', (
    tester,
  ) async {
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [_fileMessage('file-1', sequence: '1')],
    );
    final actions = _FakeFileActions(action: null);
    final container = await _container(gateway: gateway, fileActions: actions);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-file-open-file-1')));

    await tester.tap(find.byKey(const Key('message-file-open-file-1')));
    await tester.runAsync(_flushEvents);
    await tester.pump();

    expect(actions.askedFilename, 'Notes.pdf');
    expect(gateway.downloadedFileID, isNull);
    expect(actions.downloadPath, isNull);
    expect(actions.downloadBytes, isNull);
  });

  testWidgets('downloads a file message through the native action flow', (
    tester,
  ) async {
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [_fileMessage('file-1', sequence: '1')],
    );
    final actions = _FakeFileActions(action: MessageFileAction.download);
    final container = await _container(gateway: gateway, fileActions: actions);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-file-open-file-1')));

    await tester.tap(find.byKey(const Key('message-file-open-file-1')));
    await tester.runAsync(_flushEvents);
    await tester.pump();

    expect(actions.askedFilename, 'Notes.pdf');
    expect(gateway.downloadedFileID, '8');
    expect(actions.downloadPath, '/tmp/Notes.pdf');
    expect(actions.downloadBytes, [1, 2, 3]);
  });
}

Future<ProviderContainer> _container({
  required StubMessageGateway gateway,
  LocalFileActions? fileActions,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _StubAuthController(AuthState(session: _session)),
      ),
      messageGatewayProvider.overrideWithValue(gateway),
      realtimeConnectionProvider.overrideWithValue(
        const StubRealtimeConnection(),
      ),
      if (fileActions != null)
        localFileActionsProvider.overrideWithValue(fileActions),
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

Message _fileMessage(String id, {required String sequence}) {
  return Message(
    id: id,
    conversationId: _conversation.id,
    sender: _conversation.peer,
    clientMessageId: 'client-$id',
    sequence: sequence,
    kind: MessageKind.file,
    body: '',
    image: null,
    file: const MessageFile(
      id: '8',
      url: '/api/v1/message-files/8',
      filename: 'Notes.pdf',
      contentType: 'application/pdf',
      byteSize: 2048,
    ),
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

class _FakeFileActions implements LocalFileActions {
  _FakeFileActions({required this.action});

  final MessageFileAction? action;
  String? askedFilename;
  String? downloadPath;
  List<int>? downloadBytes;

  @override
  Future<MessageFileAction?> chooseAction(String filename) async {
    askedFilename = filename;
    return action;
  }

  @override
  Future<String?> chooseDownloadPath(String filename) async {
    downloadPath = '/tmp/$filename';
    return downloadPath;
  }

  @override
  Future<void> writeDownloadFile(String path, List<int> bytes) async {
    downloadPath = path;
    downloadBytes = bytes;
  }
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
