import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';

void main() {
  test('extracts only web links and trims sentence punctuation', () {
    final links = extractWebLinks(
      'Open https://example.com/news, then http://instant.chat/path?q=1. '
      'Ignore ftp://example.com.',
    );

    expect(links.map((link) => link.toString()), [
      'https://example.com/news',
      'http://instant.chat/path?q=1',
    ]);
  });

  test('collects recent unique shared content and ignores recalls', () {
    final content = ContactSharedContent.fromMessages([
      _message(
        id: 'older',
        createdAt: DateTime.utc(2026, 7, 20),
        body: 'https://example.com',
        image: _image('image-older'),
      ),
      _message(
        id: 'newer',
        createdAt: DateTime.utc(2026, 7, 21),
        body: 'https://instant.chat',
        image: _image('image-newer'),
        file: _file('file-newer'),
      ),
      _message(
        id: 'duplicate',
        createdAt: DateTime.utc(2026, 7, 22),
        body: 'https://instant.chat',
        image: _image('image-newer'),
        recalledAt: DateTime.utc(2026, 7, 23),
      ),
    ]);

    expect(content.images.map((image) => image.id), [
      'image-newer',
      'image-older',
    ]);
    expect(content.files.single.id, 'file-newer');
    expect(content.links.map((link) => link.toString()), [
      'https://instant.chat',
      'https://example.com',
    ]);
  });

  test('does not reload when unrelated conversation state refreshes', () async {
    final gateway = _CountingMessageGateway();
    final container = ProviderContainer(
      overrides: [
        conversationsControllerProvider.overrideWith(
          _StubConversationsController.new,
        ),
        messageGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    const request = (
      contactUserId: 'user-antoine',
      accessToken: 'access-token',
    );
    final provider = contactSharedContentProvider(request);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.future);
    expect(gateway.listCallCount, 1);

    final controller =
        container.read(conversationsControllerProvider.notifier)
            as _StubConversationsController;
    controller.refreshUnrelatedState();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.listCallCount, 1);

    controller.recordNewMessage();
    await Future<void>.delayed(Duration.zero);
    await container.read(provider.future);
    expect(gateway.listCallCount, 2);
  });
}

Message _message({
  required String id,
  required DateTime createdAt,
  required String body,
  MessageImage? image,
  MessageFile? file,
  DateTime? recalledAt,
}) {
  return Message(
    id: id,
    conversationId: 'conversation-1',
    sender: _sender,
    clientMessageId: 'client-$id',
    sequence: id,
    kind: image != null
        ? MessageKind.image
        : file != null
        ? MessageKind.file
        : MessageKind.text,
    body: body,
    image: image,
    file: file,
    recalledAt: recalledAt,
    createdAt: createdAt,
  );
}

MessageImage _image(String id) => MessageImage(
  id: id,
  url: '/api/v1/message-images/$id',
  contentType: 'image/png',
  byteSize: 3,
);

MessageFile _file(String id) => MessageFile(
  id: id,
  url: '/api/v1/message-files/$id',
  filename: 'Notes.pdf',
  contentType: 'application/pdf',
  byteSize: 2048,
);

final _sender = PublicUser(
  id: 'user-antoine',
  username: 'antoine',
  displayName: 'Antoine Griezmann',
  createdAt: DateTime.utc(2026, 7, 15),
);

class _StubConversationsController extends ConversationsController {
  @override
  Future<ConversationsState> build() async {
    return ConversationsState(conversations: [_conversation()]);
  }

  void refreshUnrelatedState() {
    state = AsyncData(
      ConversationsState(
        conversations: [
          _conversation(unreadCount: 4, updatedAt: DateTime.utc(2026, 7, 22)),
        ],
      ),
    );
  }

  void recordNewMessage() {
    state = AsyncData(
      ConversationsState(conversations: [_conversation(lastSequence: '2')]),
    );
  }
}

class _CountingMessageGateway extends StubMessageGateway {
  _CountingMessageGateway() : super(_authUser);

  var listCallCount = 0;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  }) {
    listCallCount += 1;
    return super.list(
      accessToken: accessToken,
      conversationId: conversationId,
      before: before,
      after: after,
      limit: limit,
    );
  }
}

Conversation _conversation({
  int unreadCount = 0,
  String lastSequence = '1',
  DateTime? updatedAt,
}) {
  return Conversation(
    id: 'conversation-1',
    kind: 'direct',
    peer: _sender,
    createdAt: DateTime.utc(2026, 7, 15),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 21),
    unreadCount: unreadCount,
    lastMessage: ConversationLastMessage(
      sequence: lastSequence,
      kind: 'image',
      body: '',
      fileName: '',
    ),
  );
}

final _authUser = AuthUser(
  id: 'operator',
  username: 'operator',
  displayName: 'Operator',
  createdAt: DateTime.utc(2026, 7, 15),
);
