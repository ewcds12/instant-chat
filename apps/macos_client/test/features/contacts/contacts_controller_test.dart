import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_gateway.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';

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

  test(
    'accept reports success and cancel removes an outgoing request',
    () async {
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

      final accepted = await container
          .read(contactsControllerProvider.notifier)
          .accept('incoming-1');
      await container
          .read(contactsControllerProvider.notifier)
          .cancel('outgoing-1');

      expect(accepted, isTrue);
      expect(gateway.acceptedRequestId, 'incoming-1');
      expect(gateway.canceledRequestId, 'outgoing-1');
    },
  );

  test('delete reports success and refreshes the contact snapshot', () async {
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

    final deleted = await container
        .read(contactsControllerProvider.notifier)
        .remove(_otherUser.id);

    expect(deleted, isTrue);
    expect(gateway.removedUserId, _otherUser.id);
    expect(gateway.listContactsCalls, 2);
  });

  test(
    'setRemark reports success and refreshes the contact snapshot',
    () async {
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

      final updated = await container
          .read(contactsControllerProvider.notifier)
          .setRemark(_otherUser.id, 'Coach');

      expect(updated, isTrue);
      expect(gateway.remarkedUserId, _otherUser.id);
      expect(gateway.remark, 'Coach');
      expect(gateway.listContactsCalls, 2);
    },
  );

  test('fallback refresh discovers an incoming request', () async {
    final gateway = _FakeContactGateway();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        contactGatewayProvider.overrideWithValue(gateway),
        contactRecoveryIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
        realtimeConnectionProvider.overrideWithValue(
          const StubRealtimeConnection(),
        ),
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

    gateway.incoming = [_incomingRequest];
    await _waitForIncomingRequest(container);

    expect(gateway.listContactsCalls, greaterThanOrEqualTo(2));
    expect(
      container
          .read(contactsControllerProvider)
          .requireValue
          .incoming
          .single
          .id,
      _incomingRequest.id,
    );
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'retro_user',
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

final _incomingRequest = ContactRequest(
  id: 'incoming-1',
  user: _otherUser,
  createdAt: DateTime.utc(2026, 7, 16),
  updatedAt: DateTime.utc(2026, 7, 16),
);

class _FakeContactGateway implements ContactGateway {
  String? searchedUsername;
  String? sentUsername;
  String? acceptedRequestId;
  String? canceledRequestId;
  String? removedUserId;
  String? remarkedUserId;
  String? remark;
  int listContactsCalls = 0;
  List<ContactRequest> incoming = [];

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
    return ContactRequestLists(incoming: incoming, outgoing: const []);
  }

  @override
  Future<Contact> acceptRequest({
    required String accessToken,
    required String requestId,
  }) async {
    acceptedRequestId = requestId;
    return Contact(
      relationshipId: 'relationship-1',
      user: _otherUser,
      connectedAt: DateTime.utc(2026, 7, 16),
    );
  }

  @override
  Future<void> rejectRequest({
    required String accessToken,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelRequest({
    required String accessToken,
    required String requestId,
  }) async {
    canceledRequestId = requestId;
  }

  @override
  Future<void> removeContact({
    required String accessToken,
    required String userId,
  }) async {
    removedUserId = userId;
  }

  @override
  Future<void> setRemark({
    required String accessToken,
    required String userId,
    required String remark,
  }) async {
    remarkedUserId = userId;
    this.remark = remark;
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

Future<void> _waitForIncomingRequest(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container
            .read(contactsControllerProvider)
            .asData
            ?.value
            .incoming
            .isNotEmpty ??
        false) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('The incoming contact request was not recovered.');
}
