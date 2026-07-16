import 'package:instant_chat/features/auth/domain/auth_session.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}
