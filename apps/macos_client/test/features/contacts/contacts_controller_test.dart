import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_gateway.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('search normalizes username and send refreshes the snapshot', () async {
    final gateway = _FakeContactGateway();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        contactGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final subscription = container.listen(
      contactsControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(contactsControllerProvider.future);

    await container
        .read(contactsControllerProvider.notifier)
        .search(' OTHER_USER ');
    await container
        .read(contactsControllerProvider.notifier)
        .sendSearchResult();

    expect(gateway.searchedUsername, 'other_user');
    expect(gateway.sentUsername, 'other_user');
    expect(gateway.listContactsCalls, 2);
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'retro_user',
    email: 'retro@example.com',
    displayName: 'Retro User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 16, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 16),
);

final _otherUser = PublicUser(
  id: '8',
  username: 'other_user',
  displayName: 'Other User',
  createdAt: DateTime.utc(2026, 7, 16),
);

class _FakeContactGateway implements ContactGateway {
  String? searchedUsername;
  String? sentUsername;
  int listContactsCalls = 0;

  @override
  Future<PublicUser> searchUser({
    required String accessToken,
    required String username,
  }) async {
    searchedUsername = username;
    return _otherUser;
  }

  @override
  Future<ContactRequest> sendRequest({
    required String accessToken,
    required String username,
  }) async {
    sentUsername = username;
    return ContactRequest(
      id: '9',
      user: _otherUser,
      createdAt: DateTime.utc(2026, 7, 16),
      updatedAt: DateTime.utc(2026, 7, 16),
    );
  }

  @override
  Future<List<Contact>> listContacts(String accessToken) async {
    listContactsCalls++;
    return [];
  }

  @override
  Future<ContactRequestLists> listRequests(String accessToken) async {
    return const ContactRequestLists(incoming: [], outgoing: []);
  }

  @override
  Future<Contact> acceptRequest({
    required String accessToken,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectRequest({
    required String accessToken,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeContact({
    required String accessToken,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
