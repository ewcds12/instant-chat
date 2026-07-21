import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_directory_list.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_page.dart';
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

  testWidgets(
    'selects a contact, opens a direct message, and confirms remove',
    (tester) async {
      String? openedUserId;
      await tester.binding.setSurfaceSize(const Size(1200, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(AuthState(session: _session)),
            ),
            contactsControllerProvider.overrideWith(
              () => _StubContactsController(
                ContactsState(
                  contacts: [
                    _contact('amy', 'Amy Adams'),
                    _contact('zoe', 'Zoe Day'),
                  ],
                  incoming: const [],
                  outgoing: const [],
                ),
              ),
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
      expect(
        tester.getSize(find.byKey(const Key('contact-detail-header'))).height,
        RetroMetrics.contactDetailHeaderHeight,
      );
      expect(
        tester.getSize(find.byKey(const Key('contact-detail-message'))).height,
        RetroMetrics.composerControlHeight,
      );
      expect(find.text('Contact details'), findsNothing);
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

      await tester.tap(find.byKey(const Key('contact-detail-message')));
      await tester.pump();
      expect(openedUserId, 'user-zoe');

      await tester.tap(find.byTooltip('Contact options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Contact…'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Contact?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Contact?'), findsNothing);
    },
  );
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

Contact _contact(String username, String displayName) {
  return Contact(
    relationshipId: 'relationship-$username',
    user: PublicUser(
      id: 'user-$username',
      username: username,
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 21),
    ),
    connectedAt: DateTime.utc(2026, 7, 21),
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

  @override
  Future<ContactsState> build() async => contactsState;
}
