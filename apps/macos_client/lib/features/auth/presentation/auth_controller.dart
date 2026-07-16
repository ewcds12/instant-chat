import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/data/dio_auth_gateway.dart';
import 'package:instant_chat/features/auth/data/keychain_session_store.dart';
import 'package:instant_chat/features/auth/domain/auth_failure.dart';
import 'package:instant_chat/features/auth/domain/auth_gateway.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/session_store.dart';

final authGatewayProvider = Provider<AuthGateway>((ref) {
  return DioAuthGateway(ref.watch(dioProvider));
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return KeychainSessionStore();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({this.session, this.isSubmitting = false, this.errorMessage});

  final AuthSession? session;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthSession? session,
    bool clearSession = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends AsyncNotifier<AuthState> {
  AuthGateway get _gateway => ref.read(authGatewayProvider);
  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  Future<AuthState> build() async {
    try {
      final stored = await _store.read();
      if (stored == null) {
        return const AuthState();
      }
      return AuthState(session: await _restore(stored));
    } on FormatException {
      await _store.clear();
      return const AuthState();
    } on AuthFailure {
      await _store.clear();
      return const AuthState();
    }
  }

  Future<void> login({required String email, required String password}) {
    return _submit(
      () => _gateway.login(email: email.trim(), password: password),
    );
  }

  Future<void> register({
    required String email,
    required String username,
    required String displayName,
    required String password,
  }) {
    return _submit(
      () => _gateway.register(
        email: email.trim(),
        username: username.trim().toLowerCase(),
        displayName: displayName.trim(),
        password: password,
      ),
    );
  }

  void clearError() {
    final current = state.requireValue;
    if (current.errorMessage == null) {
      return;
    }
    state = AsyncData(current.copyWith(clearError: true));
  }

  Future<void> signOut() async {
    final current = state.requireValue;
    final session = current.session;
    if (session == null) {
      return;
    }
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _gateway.logout(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } on AuthFailure {
      // Local sign-out must remain available when the server is unreachable.
    } finally {
      await _store.clear();
      state = const AsyncData(AuthState());
    }
  }

  Future<AuthSession?> _restore(AuthSession stored) async {
    final now = DateTime.now().toUtc();
    if (!stored.refreshExpiresAt.isAfter(now)) {
      await _store.clear();
      return null;
    }
    if (stored.accessExpiresAt.isAfter(now)) {
      try {
        final user = await _gateway.currentUser(stored.accessToken);
        final restored = stored.copyWith(user: user);
        await _store.write(restored);
        return restored;
      } on AuthFailure catch (failure) {
        if (failure.isNetworkFailure) {
          return stored;
        }
        if (failure.code != 'invalid_token') {
          rethrow;
        }
      }
    }
    try {
      final refreshed = await _gateway.refresh(stored.refreshToken);
      await _store.write(refreshed);
      return refreshed;
    } on AuthFailure catch (failure) {
      if (failure.isNetworkFailure) {
        return stored;
      }
      await _store.clear();
      rethrow;
    }
  }

  Future<void> _submit(Future<AuthSession> Function() request) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final session = await request();
      await _store.write(session);
      state = AsyncData(AuthState(session: session));
    } on AuthFailure catch (failure) {
      state = AsyncData(
        current.copyWith(isSubmitting: false, errorMessage: failure.message),
      );
    } on FormatException {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'The server returned an invalid response.',
        ),
      );
    }
  }
}
