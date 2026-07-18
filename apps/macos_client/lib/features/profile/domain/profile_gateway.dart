import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/profile/domain/profile_update.dart';

abstract interface class ProfileGateway {
  Future<AuthUser> update({
    required String accessToken,
    required ProfileUpdate update,
  });

  Future<AuthUser> uploadAvatar({
    required String accessToken,
    required String imagePath,
  });
}
