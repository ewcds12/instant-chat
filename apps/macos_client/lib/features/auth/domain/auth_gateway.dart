import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';

abstract interface class AuthGateway {
  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
  });

  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<AuthSession> refresh(String refreshToken);

  Future<AuthUser> currentUser(String accessToken);

  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  });
}
