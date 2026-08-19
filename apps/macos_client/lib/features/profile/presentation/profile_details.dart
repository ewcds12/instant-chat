import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/profile/domain/profile_update.dart';
import 'package:instant_chat/features/profile/presentation/profile_rows.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({
    required this.user,
    required this.onEditName,
    required this.onEditGender,
    required this.onEditID,
    super.key,
  });

  final AuthUser user;
  final VoidCallback onEditName;
  final VoidCallback onEditGender;
  final VoidCallback onEditID;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: RetroMetrics.spaceMedium,
            bottom: RetroMetrics.spaceSmall,
          ),
          child: Text(
            context.l10n.ui('Personal details'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        ProfileRows(
          children: [
            ProfileRow(
              label: context.l10n.ui('Name'),
              value: user.displayName,
              onTap: onEditName,
            ),
            ProfileRow(
              label: context.l10n.ui('Gender'),
              value: context.l10n.ui(genderLabel(user.gender)),
              onTap: onEditGender,
            ),
            ProfileRow(
              label: context.l10n.id,
              value: '@${user.username}',
              onTap: onEditID,
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileAccountActions extends StatelessWidget {
  const ProfileAccountActions({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: RetroMetrics.spaceMedium,
            bottom: RetroMetrics.spaceSmall,
          ),
          child: Text(
            context.l10n.ui('Account'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        ProfileRows(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('profile-sign-out'),
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RetroMetrics.spaceLarge,
                  ),
                  child: SizedBox(
                    height: RetroMetrics.profileRowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.l10n.ui('Sign out'),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: colors.error),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum ProfileField {
  name('Name', 'Name', 'Your display name'),
  id('ID', 'ID', 'your_id');

  const ProfileField(this.title, this.label, this.hintText);

  final String title;
  final String label;
  final String hintText;

  String value(AuthUser user) => switch (this) {
    ProfileField.name => user.displayName,
    ProfileField.id => user.username,
  };

  ProfileUpdate update(AuthUser user, String value) => switch (this) {
    ProfileField.name => profileUpdate(user, displayName: value),
    ProfileField.id => profileUpdate(user, username: value),
  };
}

ProfileUpdate profileUpdate(
  AuthUser user, {
  String? username,
  String? displayName,
  String? gender,
  String? region,
}) {
  return ProfileUpdate(
    username: username ?? user.username,
    displayName: displayName ?? user.displayName,
    gender: gender ?? user.gender,
    region: region ?? user.region,
  );
}

String genderLabel(String? value) => switch (value) {
  'female' => 'Female',
  'male' => 'Male',
  'non_binary' => 'Non-binary',
  'prefer_not_to_say' => 'Prefer not to say',
  _ => 'Not set',
};
