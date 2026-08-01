import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_image_view.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
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

  testWidgets('keeps the history at the bottom when the composer expands', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: List.generate(
        28,
        (index) => _message('$index', 'Message $index', sequence: '$index'),
      ),
    );
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-history-list')));

    await tester.drag(
      find.byKey(const Key('message-history-list')),
      const Offset(0, 420),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('message-composer')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.pump();

    final composer = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    final listView = tester.widget<ListView>(
      find.byKey(const Key('message-history-list')),
    );
    expect(composer.focusNode?.hasPrimaryFocus, isTrue);
    expect(
      listView.controller!.position.pixels,
      moreOrLessEquals(
        listView.controller!.position.maxScrollExtent,
        epsilon: 1,
      ),
    );
  });

  testWidgets('renders image messages without a chat bubble', (tester) async {
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [_imageMessage('image-1', sequence: '1')],
    );
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-image-image-1')));
    await tester.pump();

    expect(find.byKey(const Key('message-image-image-1')), findsOneWidget);
    expect(find.byKey(const Key('message-bubble-image-1')), findsNothing);
  });

  testWidgets('shows contextual message timestamps', (tester) async {
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [
        _message(
          'first',
          'First timestamp',
          sequence: '1',
          createdAt: DateTime(2026, 7, 20, 15),
        ),
        _message(
          'nearby',
          'Nearby timestamp',
          sequence: '2',
          createdAt: DateTime(2026, 7, 20, 15, 4),
        ),
        _message(
          'delayed',
          'Delayed timestamp',
          sequence: '3',
          createdAt: DateTime(2026, 7, 20, 15, 9),
        ),
      ],
    );
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-bubble-delayed')));

    expect(find.textContaining('15:00'), findsOneWidget);
    expect(find.textContaining('15:04'), findsNothing);
    expect(find.textContaining('15:09'), findsOneWidget);
  });

  testWidgets('shows an avatar next to every message', (tester) async {
    final avatarPeer = _conversation.peer.copyWith(
      avatarUrl: '/api/v1/users/8/avatar',
    );
    final gateway = StubMessageGateway(
      _session.user,
      initialMessages: [
        _message('peer-1', 'First', sequence: '1'),
        _message('peer-2', 'Second', sequence: '2'),
        _ownMessage('mine-1', 'Third', sequence: '3'),
        _ownMessage('mine-2', 'Fourth', sequence: '4'),
        _message('peer-3', 'Fifth', sequence: '5', sender: avatarPeer),
      ],
    );
    final container = await _container(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(_messagesPage(container));
    await _pumpUntil(tester, find.byKey(const Key('message-bubble-peer-3')));

    expect(
      find.byKey(const Key('message-sender-avatar-peer-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('message-sender-avatar-peer-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('message-sender-avatar-mine-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('message-sender-avatar-mine-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('message-sender-avatar-peer-3')),
      findsOneWidget,
    );
    final avatar = tester.widget<ProfileAvatar>(
      find.byKey(const Key('message-sender-avatar-peer-3')),
    );
    expect(avatar.avatarUrl, '/api/v1/users/8/avatar');
    expect(avatar.radius, 18);

    final firstIncomingBubble = tester.getRect(
      find.byKey(const Key('message-bubble-peer-1')),
    );
    final terminalIncomingBubble = tester.getRect(
      find.byKey(const Key('message-bubble-peer-2')),
    );
    final firstOutgoingBubble = tester.getRect(
      find.byKey(const Key('message-bubble-mine-1')),
    );
    final terminalOutgoingBubble = tester.getRect(
      find.byKey(const Key('message-bubble-mine-2')),
    );

    expect(
      firstIncomingBubble.left,
      moreOrLessEquals(terminalIncomingBubble.left),
    );
    expect(
      firstOutgoingBubble.right,
      moreOrLessEquals(terminalOutgoingBubble.right),
    );

    final incomingDecoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('message-bubble-peer-1')),
                )
                .decoration!
            as BoxDecoration;
    final outgoingDecoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('message-bubble-mine-1')),
                )
                .decoration!
            as BoxDecoration;
    expect(
      incomingDecoration.borderRadius,
      const BorderRadius.all(Radius.circular(10)),
    );
    expect(
      outgoingDecoration.borderRadius,
      const BorderRadius.all(Radius.circular(10)),
    );
  });

  testWidgets('opens image preview and switches images with arrow keys', (
    tester,
  ) async {
    final images = [_messageImage('5'), _messageImage('6')];

    await tester.pumpWidget(_imagePreviewHarness(images));

    await tester.tap(find.byKey(const Key('message-image-open-test')));
    await _pumpUntil(tester, find.byKey(const Key('message-image-preview')));

    expect(find.text('1 of 2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('2 of 2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('downloads the selected image from the preview', (tester) async {
    final images = [_messageImage('5'), _messageImage('6')];
    String? downloadedID;

    await tester.pumpWidget(
      _imagePreviewHarness(
        images,
        onDownload: (image) async => downloadedID = image.id,
      ),
    );
    await tester.tap(find.byKey(const Key('message-image-open-test')));
    await _pumpUntil(tester, find.byKey(const Key('message-image-preview')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 220));

    await tester.tap(find.byKey(const Key('message-image-preview-download')));
    await tester.pump();

    expect(downloadedID, '6');
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
      conversationRecoveryIntervalProvider.overrideWithValue(null),
      messageRecoveryIntervalProvider.overrideWithValue(null),
      conversationGatewayProvider.overrideWithValue(StubConversationGateway()),
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

Widget _imagePreviewHarness(
  List<MessageImage> images, {
  Future<void> Function(MessageImage image)? onDownload,
}) {
  return MaterialApp(
    theme: RetroTheme.data,
    home: Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => MessageImageView(
            openKey: const Key('message-image-open-test'),
            image: images.first,
            accessToken: _session.accessToken,
            onOpen: () => showMessageImagePreview(
              context: context,
              images: images,
              initialImage: images.first,
              accessToken: _session.accessToken,
              onDownload: onDownload ?? (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
}

Message _message(
  String id,
  String body, {
  required String sequence,
  PublicUser? sender,
  DateTime? createdAt,
}) {
  return Message(
    id: id,
    conversationId: _conversation.id,
    sender: sender ?? _conversation.peer,
    clientMessageId: 'client-$id',
    sequence: sequence,
    kind: MessageKind.text,
    body: body,
    image: null,
    createdAt: createdAt ?? DateTime.utc(2026, 7, 15, 13),
  );
}

Message _ownMessage(String id, String body, {required String sequence}) {
  return Message(
    id: id,
    conversationId: _conversation.id,
    sender: PublicUser.fromAuthUser(_session.user),
    clientMessageId: 'client-$id',
    sequence: sequence,
    kind: MessageKind.text,
    body: body,
    image: null,
    createdAt: DateTime.utc(2026, 7, 15, 13),
  );
}

Message _imageMessage(
  String id, {
  required String sequence,
  String imageId = '5',
}) {
  return Message(
    id: id,
    conversationId: _conversation.id,
    sender: _conversation.peer,
    clientMessageId: 'client-$id',
    sequence: sequence,
    kind: MessageKind.image,
    body: '',
    image: _messageImage(imageId),
    createdAt: DateTime.utc(2026, 7, 15, 13),
  );
}

MessageImage _messageImage(String id) {
  return MessageImage(
    id: id,
    url: '/api/v1/message-images/$id',
    contentType: 'image/png',
    byteSize: 3,
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
  unreadCount: 0,
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
