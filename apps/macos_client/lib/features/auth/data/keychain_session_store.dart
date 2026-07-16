import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/session_store.dart';

class KeychainSessionStore implements SessionStore {
  KeychainSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'instant_chat.auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null) {
      return null;
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Stored session must be a JSON object');
    }
    return AuthSession.fromJson(stringKeyedMap(decoded));
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
