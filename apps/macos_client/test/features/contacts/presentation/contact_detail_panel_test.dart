import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_panel.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_section.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_navigation_target.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../../support/widget_network_stubs.dart';

void main() {
  testWidgets('opens the contact avatar and real shared content actions', (
    tester,
  ) async {
    var messageOpenCount = 0;
    final fileActions = _FakeFileActions();
    final urlLauncher = _FakeUrlLauncher();
    final gateway = StubMessageGateway(_authUser);
    await tester.binding.setSurfaceSize(const Size(920, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactSharedContentProvider.overrideWith(
            (ref, request) async => _sharedContent,
          ),
          messageGatewayProvider.overrideWithValue(gateway),
          localFileActionsProvider.overrideWithValue(fileActions),
          localUrlLauncherProvider.overrideWithValue(urlLauncher),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: ContactDetailPanel(
              contact: _contact,
              accessToken: 'access-token',
              disabled: false,
              onMessage: () => messageOpenCount += 1,
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contact-shared-media-strip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('contact-shared-image-image-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('contact-shared-file-file-1')),
      findsOneWidget,
    );
    expect(find.text('Notes.pdf'), findsOneWidget);
    expect(find.text('Links (1)'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('contact-detail-identity'))).height,
      RetroMetrics.contactDetailHeroHeight,
    );
    expect(find.text('Account ID'), findsNothing);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('contact-shared-image-image-1')),
      ),
      const Size.square(RetroMetrics.contactSharedThumbnailExtent),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('contact-shared-file-file-1')))
          .height,
      RetroMetrics.contactSharedRowHeight,
    );

    await tester.tap(find.byKey(const Key('contact-detail-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('message-image-preview')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('message-image-preview-contact-avatar-user-antoine'),
      ),
      findsOneWidget,
    );
    final preview = find.byKey(const Key('message-image-preview'));
    final download = find.byKey(const Key('message-image-preview-download'));
    final close = find.byKey(const Key('message-image-preview-close'));
    expect(download, findsOneWidget);
    expect(
      tester.getCenter(download).dx,
      lessThan(tester.getCenter(preview).dx),
    );
    expect(tester.getCenter(download).dx, lessThan(tester.getCenter(close).dx));
    await tester.tap(download);
    await tester.pumpAndSettle();
    expect(gateway.downloadedImageID, 'contact-avatar-user-antoine');
    expect(
      fileActions.writtenPath,
      '/tmp/image-contact-avatar-user-antoine.png',
    );
    expect(fileActions.writtenBytes, [4, 5, 6]);
    await tester.tap(find.byKey(const Key('message-image-preview-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contact-shared-see-all')));
    expect(messageOpenCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('contact-shared-image-image-1')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('message-image-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('message-image-preview-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contact-shared-file-file-1')));
    await tester.pumpAndSettle();
    expect(gateway.downloadedFileID, 'file-1');
    expect(gateway.downloadedFilePath, '/tmp/Notes.pdf');

    await tester.tap(find.byKey(const Key('contact-shared-links')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('contact-shared-links-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('contact-shared-link-0')));
    await tester.pump();
    expect(urlLauncher.opened, Uri.parse('https://example.com/shared'));
  });

  testWidgets('keeps shared content visible while it reloads', (tester) async {
    final first = Completer<ContactSharedContent>()..complete(_sharedContent);
    final second = Completer<ContactSharedContent>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _sharedReloadFuturesProvider.overrideWithValue([
            first.future,
            second.future,
          ]),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: Consumer(
              key: const Key('shared-reload-harness'),
              builder: (context, ref, _) => ContactSharedSection(
                value: ref.watch(_sharedReloadProvider),
                onRetry: () {},
                onSeeAll: () {},
                onOpenImage: (_) {},
                onOpenFile: (_) {},
                onOpenLinks: (_) {},
                accessToken: 'access-token',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(
      find.byKey(const Key('shared-reload-harness')),
    );
    ProviderScope.containerOf(
      context,
    ).read(_sharedReloadIndexProvider.notifier).state = 1;
    await tester.pump();

    expect(find.byKey(const Key('contact-shared-media-strip')), findsOneWidget);
    expect(find.text('Notes.pdf'), findsOneWidget);
    expect(find.text('Links (1)'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('keeps an initials-only avatar noninteractive', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactSharedContentProvider.overrideWith(
            (ref, request) async => const ContactSharedContent.empty(),
          ),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: ContactDetailPanel(
              contact: Contact(
                relationshipId: _contact.relationshipId,
                user: _contact.user.copyWith(clearAvatarUrl: true),
                connectedAt: _contact.connectedAt,
              ),
              accessToken: 'access-token',
              disabled: false,
              onMessage: () {},
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contact-detail-avatar')), findsNothing);
    expect(find.byTooltip('View profile photo'), findsNothing);
  });

  testWidgets('searches contact history and opens the selected message', (
    tester,
  ) async {
    var messageOpenCount = 0;
    final gateway = StubMessageGateway(
      _authUser,
      initialMessages: [_searchMessage],
    );
    await tester.binding.setSurfaceSize(const Size(1000, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          conversationGatewayProvider.overrideWithValue(
            _ContactConversationGateway(),
          ),
          conversationRecoveryIntervalProvider.overrideWithValue(null),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
          contactSharedContentProvider.overrideWith(
            (ref, request) async => const ContactSharedContent.empty(),
          ),
          messageGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: ContactDetailPanel(
              contact: _contact,
              accessToken: _session.accessToken,
              disabled: false,
              onMessage: () => messageOpenCount += 1,
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contact-message-search-open')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('contact-message-search-dialog')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('contact-message-search-field')),
      'project',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('contact-message-search-result-search-message'),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ContactDetailPanel)),
    );
    final target = container.read(messageNavigationTargetProvider);
    expect(messageOpenCount, 1);
    expect(target?.conversationId, _conversation.id);
    expect(target?.messageId, _searchMessage.id);
  });
}

final _sharedContent = ContactSharedContent(
  images: const [
    MessageImage(
      id: 'image-1',
      url: '/api/v1/message-images/image-1',
      contentType: 'image/png',
      byteSize: 3,
    ),
  ],
  files: const [
    MessageFile(
      id: 'file-1',
      url: '/api/v1/message-files/file-1',
      filename: 'Notes.pdf',
      contentType: 'application/pdf',
      byteSize: 2048,
    ),
  ],
  links: [Uri.parse('https://example.com/shared')],
);

final _authUser = AuthUser(
  id: 'operator',
  username: 'operator',
  displayName: 'Operator',
  createdAt: DateTime.utc(2026, 7, 15),
);

final _session = AuthSession(
  user: _authUser,
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 15, 14),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 15),
);

final _contact = Contact(
  relationshipId: 'relationship-antoine',
  user: PublicUser(
    id: 'user-antoine',
    username: 'antoine',
    displayName: 'Antoine Griezmann',
    avatarUrl: '/api/v1/users/user-antoine/avatar?v=1',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  connectedAt: DateTime.utc(2026, 7, 15),
);

final _conversation = Conversation(
  id: 'conversation-antoine',
  kind: 'direct',
  peer: _contact.user,
  createdAt: DateTime.utc(2026, 7, 15),
  updatedAt: DateTime.utc(2026, 7, 31),
  unreadCount: 0,
);

final _searchMessage = Message(
  id: 'search-message',
  conversationId: _conversation.id,
  sender: _contact.user,
  clientMessageId: 'client-search-message',
  sequence: '7',
  kind: MessageKind.text,
  body: 'The project files are ready.',
  image: null,
  createdAt: DateTime.utc(2026, 7, 31, 10, 42),
);

class _FakeFileActions implements LocalFileActions {
  String? writtenPath;
  List<int>? writtenBytes;

  @override
  Future<MessageFileAction?> chooseAction(String filename) async {
    return MessageFileAction.download;
  }

  @override
  Future<String?> chooseDownloadPath(String filename) async => '/tmp/$filename';

  @override
  Future<void> writeDownloadFile(String path, List<int> bytes) async {
    writtenPath = path;
    writtenBytes = bytes;
  }
}

class _FakeUrlLauncher implements LocalUrlLauncher {
  Uri? opened;

  @override
  Future<void> open(Uri url) async => opened = url;
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.value);

  final AuthState value;

  @override
  Future<AuthState> build() async => value;
}

class _ContactConversationGateway implements ConversationGateway {
  @override
  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  }) async => _conversation;

  @override
  Future<List<Conversation>> list(String accessToken) async => [_conversation];

  @override
  Future<void> markRead({
    required String accessToken,
    required String conversationId,
    required String sequence,
  }) async {}
}

final _sharedReloadIndexProvider = StateProvider<int>((ref) => 0);
final _sharedReloadFuturesProvider =
    Provider<List<Future<ContactSharedContent>>>((ref) => throw StateError(''));
final _sharedReloadProvider = FutureProvider<ContactSharedContent>((ref) async {
  final futures = ref.watch(_sharedReloadFuturesProvider);
  return futures[ref.watch(_sharedReloadIndexProvider)].then((value) => value);
});
