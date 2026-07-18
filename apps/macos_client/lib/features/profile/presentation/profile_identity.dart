import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: RetroMetrics.profileHeaderHeight,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text('Profile', style: Theme.of(context).textTheme.titleLarge),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const Key('profile-sheet-close'),
            tooltip: 'Close profile',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    ),
  );
}

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    required this.session,
    required this.isSaving,
    required this.onEditPhoto,
    super.key,
  });

  final AuthSession session;
  final bool isSaving;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ProfileAvatar(
          name: session.user.displayName,
          accessToken: session.accessToken,
          avatarUrl: session.user.avatarUrl,
          radius: RetroMetrics.profileAvatarRadius,
          textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontSize: RetroMetrics.profileAvatarTextSize,
          ),
        ),
        const SizedBox(height: RetroMetrics.spaceSmall),
        OutlinedButton(
          key: const Key('profile-edit-photo'),
          onPressed: isSaving ? null : onEditPhoto,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            minimumSize: const Size(0, RetroMetrics.profilePhotoButtonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: RetroMetrics.spaceMedium,
            ),
            side: BorderSide(color: colors.outline),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(RetroMetrics.cornerPill),
              ),
            ),
          ),
          child: const Text('Edit photo'),
        ),
        const SizedBox(height: RetroMetrics.spaceMedium),
        Text(
          session.user.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          '@${session.user.username}',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
