import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/contacts/presentation/requests_page.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('routes an accepted request to its selected contact', (
    tester,
  ) async {
    String? openedContactId;
    await tester.binding.setSurfaceSize(const Size(1200, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(
            () => _StubRequestsController(
              ContactsState(
                contacts: const [],
                incoming: [_request('1', 'Ada Lovelace')],
                outgoing: [_request('2', 'Grace Hopper')],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(
            body: RequestsPage(onOpenContact: (id) => openedContactId = id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('1 pending'), findsNWidgets(2));

    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(openedContactId, 'user-1');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Request?'), findsOneWidget);
    await tester.tap(find.text('Keep Request'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Request?'), findsNothing);
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: 'operator',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 21),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 21, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 21),
);

ContactRequest _request(String id, String displayName) {
  return ContactRequest(
    id: id,
    user: PublicUser(
      id: 'user-$id',
      username: displayName.toLowerCase().replaceAll(' ', '_'),
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

class _StubRequestsController extends ContactsController {
  _StubRequestsController(this.requestsState);

  final ContactsState requestsState;

  @override
  Future<ContactsState> build() async => requestsState;

  @override
  Future<bool> accept(String requestId) async => true;
}
