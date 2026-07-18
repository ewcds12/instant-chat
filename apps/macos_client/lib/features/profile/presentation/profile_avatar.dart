import 'package:flutter/material.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.accessToken,
    required this.radius,
    this.avatarUrl,
    this.textStyle,
    super.key,
  });

  final String name;
  final String accessToken;
  final double radius;
  final String? avatarUrl;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: RetroColors.primaryLight,
      foregroundColor: colors.primary,
      child: avatarUrl == null
          ? Text(_initials(name), style: textStyle)
          : ClipOval(
              child: Image.network(
                _absoluteAvatarUrl(avatarUrl!),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                headers: bearerAuthorization(accessToken),
                errorBuilder: (_, _, _) =>
                    Text(_initials(name), style: textStyle),
              ),
            ),
    );
  }
}

String _absoluteAvatarUrl(String path) {
  final base = Uri.parse(AppConfig.apiBaseUrl);
  return base.resolve(path).toString();
}

String profileInitials(String name) => _initials(name);

String _initials(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0])
      .join()
      .toUpperCase();
}
