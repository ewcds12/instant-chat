import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_failure.dart';
import 'package:instant_chat/features/auth/domain/auth_gateway.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/domain/session_store.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';

void main() {
  test('login stores the returned session', () async {
    final gateway = _FakeAuthGateway(session: _futureSession());
    final store = _MemorySessionStore();
    final container = _container(gateway, store);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(username: ' Operator ', password: 'pw');

    expect(gateway.loginUsername, 'operator');
    expect(store.session?.accessToken, 'new-access');
    expect(
      container
          .read(authControllerProvider)
          .requireValue
          .session
          ?.user
          .username,
      'operator',
    );
  });

  test('restore rotates an expired access token', () async {
    final old = _futureSession(
      accessToken: 'old-access',
      accessExpiresAt: DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      ),
    );
    final fresh = _futureSession();
    final gateway = _FakeAuthGateway(session: fresh);
    final store = _MemorySessionStore(old);
    final container = _container(gateway, store);
    addTearDown(container.dispose);

    final restored = await container.read(authControllerProvider.future);

    expect(gateway.refreshToken, old.refreshToken);
    expect(restored.session?.accessToken, fresh.accessToken);
    expect(store.session?.accessToken, fresh.accessToken);
  });

  test('restore clears a rejected refresh token', () async {
    final old = _futureSession(
      accessExpiresAt: DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      ),
    );
    final gateway = _FakeAuthGateway(
      session: _futureSession(),
      refreshFailure: const AuthFailure(
        code: 'invalid_token',
        message: 'The refresh token is invalid or expired.',
      ),
    );
    final store = _MemorySessionStore(old);
    final container = _container(gateway, store);
    addTearDown(container.dispose);

    final restored = await container.read(authControllerProvider.future);

    expect(store.session, isNull);
    expect(restored.session, isNull);
  });

  test('refreshes a near-expiring session in the background', () async {
    final old = _futureSession(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
    );
    final fresh = _futureSession(accessToken: 'fresh-access');
    final gateway = _FakeAuthGateway(session: fresh);
    final store = _MemorySessionStore(old);
    final container = _container(gateway, store);
    addTearDown(container.dispose);

    final restored = await container.read(authControllerProvider.future);
    expect(restored.session?.accessToken, 'old-access');

    await _waitFor(() => gateway.refreshCalls == 1);

    expect(gateway.refreshToken, 'old-refresh');
    expect(store.session?.accessToken, 'fresh-access');
    expect(
      container.read(authControllerProvider).requireValue.session?.accessToken,
      'fresh-access',
    );
  });

  test('background refresh clears a rejected refresh token', () async {
    final old = _futureSession(
      refreshToken: 'rejected-refresh',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
    );
    final gateway = _FakeAuthGateway(
      session: _futureSession(),
      refreshFailure: const AuthFailure(
        code: 'invalid_token',
        message: 'The refresh token is invalid or expired.',
      ),
    );
    final store = _MemorySessionStore(old);
    final container = _container(gateway, store);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);

    await _waitFor(() => store.session == null);

    expect(gateway.refreshToken, 'rejected-refresh');
    expect(container.read(authControllerProvider).requireValue.session, isNull);
  });

  test('coalesces concurrent manual refreshes', () async {
    final gateway = _FakeAuthGateway(
      session: _futureSession(accessToken: 'fresh-access'),
      refreshBlock: Completer<void>(),
    );
    final store = _MemorySessionStore(_futureSession());
    final container = _container(gateway, store);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final notifier = container.read(authControllerProvider.notifier);
    final first = notifier.refreshSession();
    final second = notifier.refreshSession();
    gateway.refreshBlock!.complete();
    await Future.wait([first, second]);

    expect(gateway.refreshCalls, 1);
    expect(store.session?.accessToken, 'fresh-access');
  });
}

ProviderContainer _container(AuthGateway gateway, SessionStore store) {
  return ProviderContainer(
    overrides: [
      authGatewayProvider.overrideWithValue(gateway),
      sessionStoreProvider.overrideWithValue(store),
    ],
  );
}

AuthSession _futureSession({
  String accessToken = 'new-access',
  String refreshToken = 'refresh-token',
  DateTime? accessExpiresAt,
}) {
  final now = DateTime.now().toUtc();
  return AuthSession(
    user: AuthUser(
      id: '42',
      username: 'operator',
      displayName: 'Operator',
      createdAt: now,
    ),
    accessToken: accessToken,
    accessExpiresAt: accessExpiresAt ?? now.add(const Duration(minutes: 10)),
    refreshToken: refreshToken,
    refreshExpiresAt: now.add(const Duration(days: 10)),
  );
}

class _MemorySessionStore implements SessionStore {
  _MemorySessionStore([this.session]);

  AuthSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async => this.session = session;
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    required this.session,
    this.refreshFailure,
    this.refreshBlock,
  });

  final AuthSession session;
  final AuthFailure? refreshFailure;
  final Completer<void>? refreshBlock;
  String? loginUsername;
  String? refreshToken;
  var refreshCalls = 0;

  @override
  Future<AuthUser> currentUser(String accessToken) async => session.user;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    loginUsername = username;
    return session;
  }

  @override
  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    this.refreshToken = refreshToken;
    refreshCalls++;
    await refreshBlock?.future;
    if (refreshFailure case final failure?) {
      throw failure;
    }
    return session;
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
  }) async => session;
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
