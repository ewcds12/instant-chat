import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contact_directory_list.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_page.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('groups matching contacts alphabetically and puts symbols last', () {
    final groups = groupContacts([
      _contact('zoe', 'Zoe'),
      _contact('amy', 'Amy'),
      _contact('3', '3rd'),
    ], '');

    expect(groups.map((group) => group.label), ['#', 'A', 'Z']);
    expect(groupContacts([_contact('amy', 'Amy')], 'my').single.label, 'A');
    expect(groupContacts([_contact('amy', 'Amy')], 'missing'), isEmpty);
  });

  test('matches remarks, original names, and usernames', () {
    final contact = _contact('amy', 'Amy Adams', remark: 'Coach');

    expect(groupContacts([contact], 'coach').single.label, 'C');
    expect(groupContacts([contact], 'amy'), isNotEmpty);
    expect(groupContacts([contact], 'amy_adams'), isEmpty);
  });

  testWidgets(
    'selects a contact, opens a direct message, and confirms deletion',
    (tester) async {
      String? openedUserId;
      final contactsController = _StubContactsController(
        ContactsState(
          contacts: [_contact('amy', 'Amy Adams'), _contact('zoe', 'Zoe Day')],
          incoming: const [],
          outgoing: const [],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1200, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(AuthState(session: _session)),
            ),
            contactsControllerProvider.overrideWith(() => contactsController),
            contactSharedContentProvider.overrideWith(
              (ref, request) async => const ContactSharedContent.empty(),
            ),
          ],
          child: MaterialApp(
            theme: RetroTheme.data,
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 760,
                child: ContactsPage(
                  onOpenConversation: (userId) async => openedUserId = userId,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const Key('contact-directory-column'))).width,
        RetroMetrics.conversationColumnWidth,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('contact-directory-search-box')))
            .height,
        RetroMetrics.contactSearchHeight,
      );
      expect(find.byTooltip('Refresh contacts'), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('contact-detail-header'))).height,
        RetroMetrics.contactDetailHeaderHeight,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('contact-detail-header')),
          matching: find.byType(ProfileAvatar),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byKey(const Key('contact-detail-message'))).height,
        RetroMetrics.contactDetailMessageHeight,
      );
      expect(find.text('Contact Info'), findsOneWidget);
      expect(find.text('Account ID'), findsNothing);
      expect(find.text('Shared'), findsOneWidget);
      expect(
        find.text('No shared photos, files, or links yet.'),
        findsOneWidget,
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
      expect(find.text('Amy Adams'), findsAtLeastNWidgets(1));
      final selected = tester.widget<Container>(
        find.byKey(const ValueKey('contact-directory-selection-user-amy')),
      );
      final selectedDecoration = selected.decoration! as BoxDecoration;
      expect(
        selectedDecoration.color,
        RetroTheme.data.colorScheme.surfaceContainerHigh,
      );

      await tester.tap(
        find.byKey(const ValueKey('contact-directory-row-user-zoe')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zoe Day'), findsAtLeastNWidgets(2));
      expect(find.text('@zoe'), findsAtLeastNWidgets(1));

      await tester.tap(find.byTooltip('Contact options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set Remark…'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('contact-remark-field')),
        'Captain',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(contactsController.remarkedUserId, 'user-zoe');
      expect(contactsController.remark, 'Captain');
      expect(find.text('Captain'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Zoe Day · @zoe'), findsAtLeastNWidgets(1));

      await tester.tap(find.byKey(const Key('contact-detail-message')));
      await tester.pump();
      expect(openedUserId, 'user-zoe');

      await tester.tap(find.byTooltip('Contact options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Contact…'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Contact?'), findsOneWidget);
      expect(
        find.textContaining('Message history will return'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Contact?'), findsNothing);

      await tester.tap(find.byTooltip('Contact options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Contact…'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(contactsController.removedUserId, 'user-zoe');
    },
  );

  testWidgets('expands and resolves incoming requests below search', (
    tester,
  ) async {
    final controller = _StubContactsController(
      ContactsState(
        contacts: [_contact('amy', 'Amy Adams')],
        incoming: [
          _request('ousmane', 'Ousmane Dembélé'),
          _request('antoine', 'Antoine Griezmann'),
        ],
        outgoing: const [],
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1200, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(() => controller),
          contactSharedContentProvider.overrideWith(
            (ref, request) async => const ContactSharedContent.empty(),
          ),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 760,
              child: ContactsPage(onOpenConversation: (_) async {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 Friend Requests'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('contact-request-drawer-toggle')),
        matching: find.byType(ProfileAvatar),
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const Key('contact-request-count-badge'))),
      const Size.square(RetroMetrics.contactRequestCountDiameter),
    );
    final badge = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('contact-request-count-badge')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((badge.decoration as BoxDecoration).shape, BoxShape.circle);
    expect(
      find.byKey(const ValueKey('contact-request-row-request-ousmane')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('contact-request-drawer-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Ousmane Dembélé'), findsOneWidget);
    expect(find.text('@antoine'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('contact-request-drawer')),
        matching: find.byType(ProfileAvatar),
      ),
      findsNothing,
    );
    final decline = find.byKey(
      const ValueKey('contact-request-decline-request-ousmane'),
    );
    final accept = find.byKey(
      const ValueKey('contact-request-accept-request-ousmane'),
    );
    expect(tester.getSize(decline).width, 62);
    expect(tester.getSize(accept).width, 58);
    expect(tester.getTopLeft(accept).dx - tester.getTopRight(decline).dx, 8);

    await tester.tap(
      find.byKey(const ValueKey('contact-request-decline-request-ousmane')),
    );
    await tester.pumpAndSettle();
    expect(controller.rejectedRequestId, 'request-ousmane');
    expect(find.text('1 Friend Request'), findsOneWidget);
    expect(find.text('Ousmane Dembélé'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('contact-request-accept-request-antoine')),
    );
    await tester.pumpAndSettle();
    expect(controller.acceptedRequestId, 'request-antoine');
    expect(find.byKey(const Key('contact-request-drawer')), findsNothing);
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '1',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 21),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 21, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 21),
);

Contact _contact(String username, String displayName, {String remark = ''}) {
  return Contact(
    relationshipId: 'relationship-$username',
    user: PublicUser(
      id: 'user-$username',
      username: username,
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 21),
    ),
    remark: remark,
    connectedAt: DateTime.utc(2026, 7, 21),
  );
}

ContactRequest _request(String username, String displayName) {
  return ContactRequest(
    id: 'request-$username',
    user: PublicUser(
      id: 'user-$username',
      username: username,
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 21),
    ),
    createdAt: DateTime.utc(2026, 7, 21),
    updatedAt: DateTime.utc(2026, 7, 21),
  );
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

class _StubContactsController extends ContactsController {
  _StubContactsController(this.contactsState);

  final ContactsState contactsState;
  String? acceptedRequestId;
  String? rejectedRequestId;
  String? removedUserId;
  String? remarkedUserId;
  String? remark;

  @override
  Future<ContactsState> build() async => contactsState;

  @override
  Future<bool> accept(String requestId) async {
    acceptedRequestId = requestId;
    final current = state.requireValue;
    final request = current.incoming.singleWhere(
      (request) => request.id == requestId,
    );
    state = AsyncData(
      current.copyWith(
        contacts: [
          ...current.contacts,
          Contact(
            relationshipId: 'relationship-${request.user.username}',
            user: request.user,
            remark: '',
            connectedAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        incoming: current.incoming
            .where((request) => request.id != requestId)
            .toList(growable: false),
      ),
    );
    return true;
  }

  @override
  Future<void> reject(String requestId) async {
    rejectedRequestId = requestId;
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        incoming: current.incoming
            .where((request) => request.id != requestId)
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<bool> remove(String userId) async {
    removedUserId = userId;
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        contacts: current.contacts
            .where((contact) => contact.user.id != userId)
            .toList(growable: false),
      ),
    );
    return true;
  }

  @override
  Future<bool> setRemark(String userId, String remark) async {
    remarkedUserId = userId;
    this.remark = remark;
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        contacts: current.contacts
            .map(
              (contact) => contact.user.id == userId
                  ? Contact(
                      relationshipId: contact.relationshipId,
                      user: contact.user,
                      remark: remark,
                      connectedAt: contact.connectedAt,
                    )
                  : contact,
            )
            .toList(growable: false),
      ),
    );
    return true;
  }
}
