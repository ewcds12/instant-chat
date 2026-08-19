import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class PostComposerBar extends StatelessWidget {
  const PostComposerBar({
    required this.user,
    required this.accessToken,
    required this.onCreate,
    super.key,
  });

  final AuthUser user;
  final String accessToken;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: const Key('explore-composer-flow'),
      width: double.infinity,
      height: RetroMetrics.exploreComposerHeight,
      child: Material(
        color: RetroColors.glassStrong,
        child: InkWell(
          key: const Key('explore-composer'),
          onTap: onCreate,
          child: Ink(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ProfileAvatar(
                  name: user.displayName,
                  accessToken: accessToken,
                  avatarUrl: user.avatarUrl,
                  radius: RetroMetrics.exploreAvatarRadius,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.ui('What’s happening?'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(66, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                  onPressed: onCreate,
                  child: Text(context.l10n.ui('Post')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
