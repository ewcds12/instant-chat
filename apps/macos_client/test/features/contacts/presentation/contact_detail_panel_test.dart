import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_panel.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_section.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../../support/widget_network_stubs.dart';

void main() {
  testWidgets('shows and opens real shared content actions', (tester) async {
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
    expect(
      tester
          .getSize(find.byKey(const Key('contact-detail-account-row')))
          .height,
      RetroMetrics.contactDetailAccountRowHeight,
    );
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

final _contact = Contact(
  relationshipId: 'relationship-antoine',
  user: PublicUser(
    id: 'user-antoine',
    username: 'antoine',
    displayName: 'Antoine Griezmann',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  connectedAt: DateTime.utc(2026, 7, 15),
);

class _FakeFileActions implements LocalFileActions {
  @override
  Future<MessageFileAction?> chooseAction(String filename) async {
    return MessageFileAction.download;
  }

  @override
  Future<String?> chooseDownloadPath(String filename) async => '/tmp/$filename';

  @override
  Future<void> writeDownloadFile(String path, List<int> bytes) async {}
}

class _FakeUrlLauncher implements LocalUrlLauncher {
  Uri? opened;

  @override
  Future<void> open(Uri url) async => opened = url;
}

final _sharedReloadIndexProvider = StateProvider<int>((ref) => 0);
final _sharedReloadFuturesProvider =
    Provider<List<Future<ContactSharedContent>>>((ref) => throw StateError(''));
final _sharedReloadProvider = FutureProvider<ContactSharedContent>((ref) async {
  final futures = ref.watch(_sharedReloadFuturesProvider);
  return futures[ref.watch(_sharedReloadIndexProvider)].then((value) => value);
});
