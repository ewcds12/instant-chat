import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contact_directory_list.dart';
import 'package:instant_chat/features/contacts/presentation/contact_request_drawer.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class ContactDirectory extends StatelessWidget {
  const ContactDirectory({
    required this.contacts,
    required this.incomingRequests,
    required this.accessToken,
    required this.query,
    required this.selectedUserId,
    required this.searchController,
    required this.isSubmitting,
    required this.searchResult,
    required this.errorMessage,
    required this.onQueryChanged,
    required this.onSearchExactId,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onDeclineRequest,
    required this.onSelect,
    super.key,
  });

  final List<Contact> contacts;
  final List<ContactRequest> incomingRequests;
  final String accessToken;
  final String query;
  final String? selectedUserId;
  final TextEditingController searchController;
  final bool isSubmitting;
  final PublicUser? searchResult;
  final String? errorMessage;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearchExactId;
  final VoidCallback onSendRequest;
  final ValueChanged<ContactRequest> onAcceptRequest;
  final ValueChanged<ContactRequest> onDeclineRequest;
  final ValueChanged<Contact> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glass,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            child: SizedBox(
              key: const Key('contact-directory-search-box'),
              height: RetroMetrics.contactSearchHeight,
              child: _DirectorySearchField(
                controller: searchController,
                disabled: isSubmitting,
                onChanged: onQueryChanged,
                onSubmit: onSearchExactId,
              ),
            ),
          ),
          if (isSubmitting) const LinearProgressIndicator(minHeight: 1),
          if (incomingRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: ContactRequestDrawer(
                requests: incomingRequests,
                disabled: isSubmitting,
                onAccept: onAcceptRequest,
                onDecline: onDeclineRequest,
              ),
            ),
          if (errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _DirectoryFeedback(message: errorMessage!),
            ),
          ],
          if (searchResult != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: _SearchResult(
                user: searchResult!,
                accessToken: accessToken,
                disabled: isSubmitting,
                onSendRequest: onSendRequest,
              ),
            ),
          ],
          Expanded(
            child: ContactDirectoryList(
              contacts: contacts,
              accessToken: accessToken,
              query: query,
              selectedUserId: selectedUserId,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectorySearchField extends StatelessWidget {
  const _DirectorySearchField({
    required this.controller,
    required this.disabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool disabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      key: const Key('contact-directory-search'),
      controller: controller,
      enabled: !disabled,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        fillColor: RetroColors.glassStrong,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary),
        ),
        suffixIcon: IconButton(
          tooltip: 'Search exact ID',
          onPressed: disabled ? null : onSubmit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmit(),
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({
    required this.user,
    required this.accessToken,
    required this.disabled,
    required this.onSendRequest,
  });

  final PublicUser user;
  final String accessToken;
  final bool disabled;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(RetroMetrics.corner),
      child: Ink(
        padding: const EdgeInsets.all(RetroMetrics.spaceSmall),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(RetroMetrics.corner),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              name: user.displayName,
              accessToken: accessToken,
              avatarUrl: user.avatarUrl,
              radius: 16,
            ),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Expanded(child: ContactIdentity(user: user)),
            TextButton(
              onPressed: disabled ? null : onSendRequest,
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryFeedback extends StatelessWidget {
  const _DirectoryFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceSmall),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
      ),
    );
  }
}
