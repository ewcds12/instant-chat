import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/platform/macos_image_picker.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/profile/domain/profile_update.dart';
import 'package:instant_chat/features/profile/presentation/profile_details.dart';
import 'package:instant_chat/features/profile/presentation/profile_editor.dart';
import 'package:instant_chat/features/profile/presentation/profile_feedback.dart';
import 'package:instant_chat/features/profile/presentation/profile_identity.dart';
import 'package:instant_chat/features/profile/presentation/profile_photo_cropper.dart';
import 'package:instant_chat/features/profile/presentation/profile_provider.dart';

Future<void> showProfileSheet({
  required BuildContext context,
  required AuthSession session,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: RetroMetrics.profileBackdropBlur,
        sigmaY: RetroMetrics.profileBackdropBlur,
      ),
      child: ProfileSheet(session: session),
    ),
  );
}

class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  var _isSaving = false;
  Timer? _feedbackTimer;
  String? _feedbackMessage;
  var _feedbackIsError = false;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session =
        ref.watch(authControllerProvider).requireValue.session ??
        widget.session;
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const Key('profile-sheet'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(RetroMetrics.spaceLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: RetroMetrics.maxProfilePanelWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.98),
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F172A),
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              RetroMetrics.spaceLarge,
              RetroMetrics.spaceSmall,
              RetroMetrics.spaceLarge,
              RetroMetrics.spaceLarge,
            ),
            child: Column(
              children: [
                ProfileHeader(onClose: () => Navigator.of(context).pop()),
                ProfileIdentity(
                  session: session,
                  isSaving: _isSaving,
                  onEditPhoto: () => _editPhoto(session),
                ),
                const SizedBox(height: RetroMetrics.spaceMedium),
                ProfileDetails(
                  user: session.user,
                  onEditName: () => _editText(session, ProfileField.name),
                  onEditGender: () => _editGender(session),
                  onEditRegion: () => _editText(session, ProfileField.region),
                  onEditID: () => _editText(session, ProfileField.id),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _feedbackMessage == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: RetroMetrics.spaceMedium,
                          ),
                          child: ProfileFeedback(
                            message: _feedbackMessage!,
                            isError: _feedbackIsError,
                          ),
                        ),
                ),
                const SizedBox(height: RetroMetrics.spaceLarge * 2),
                Text(
                  'Instant Chat for macOS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editPhoto(AuthSession session) async {
    final path = await ref
        .read(localImagePickerProvider)
        .pickImagePath(prompt: 'Choose a profile photo');
    if (!mounted || path == null) {
      return;
    }
    final croppedPath = await showProfilePhotoCropper(
      context: context,
      imagePath: path,
    );
    if (!mounted || croppedPath == null) {
      return;
    }
    try {
      await _save(
        () => ref
            .read(profileGatewayProvider)
            .uploadAvatar(
              accessToken: session.accessToken,
              imagePath: croppedPath,
            ),
      );
    } finally {
      await File(croppedPath).delete();
    }
  }

  Future<void> _editText(AuthSession session, ProfileField field) async {
    final user = session.user;
    final value = await showProfileTextEditor(
      context: context,
      title: field.title,
      label: field.label,
      initialValue: field.value(user),
      hintText: field.hintText,
      lowercase: field == ProfileField.id,
    );
    if (!mounted || value == null || value == field.value(user)) {
      return;
    }
    await _saveProfile(session, field.update(user, value));
  }

  Future<void> _editGender(AuthSession session) async {
    final value = await showProfileChoiceEditor(
      context: context,
      currentValue: session.user.gender ?? '',
    );
    if (!mounted || value == null || value == (session.user.gender ?? '')) {
      return;
    }
    await _saveProfile(session, profileUpdate(session.user, gender: value));
  }

  Future<void> _saveProfile(AuthSession session, ProfileUpdate update) {
    return _save(
      () => ref
          .read(profileGatewayProvider)
          .update(accessToken: session.accessToken, update: update),
    );
  }

  Future<void> _save(Future<AuthUser> Function() request) async {
    setState(() => _isSaving = true);
    try {
      final user = await request();
      await ref.read(authControllerProvider.notifier).replaceCurrentUser(user);
      _showFeedback('Profile updated.');
    } on ApiFailure catch (failure) {
      _showError(failure.message);
    } on FormatException {
      _showError('The server returned an invalid response.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    _showFeedback(message, isError: true);
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }
}
