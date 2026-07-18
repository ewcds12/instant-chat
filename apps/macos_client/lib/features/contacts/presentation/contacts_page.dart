import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({required this.onOpenConversation, super.key});

  final Future<void> Function(String userId) onOpenConversation;

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider);
    final accessToken = ref
        .read(authControllerProvider)
        .requireValue
        .session!
        .accessToken;
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _LoadFailure(
        onRetry: () => ref.invalidate(contactsControllerProvider),
      ),
      data: (contacts) => LiquidGradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
          child: GlassPanel(
            tint: RetroColors.glassStrong,
            padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contacts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: RetroMetrics.spaceSmall),
                const Text('Search by exact username.'),
                const SizedBox(height: RetroMetrics.spaceMedium),
                _SearchBar(
                  controller: _usernameController,
                  disabled: contacts.isSubmitting,
                  onSearch: () => _search(contacts.isSubmitting),
                ),
                if (contacts.errorMessage case final message?) ...[
                  const SizedBox(height: RetroMetrics.spaceSmall),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (contacts.searchResult case final user?) ...[
                  const SizedBox(height: RetroMetrics.spaceMedium),
                  _SearchResult(
                    displayName: user.displayName,
                    username: user.username,
                    disabled: contacts.isSubmitting,
                    onSend: () => ref
                        .read(contactsControllerProvider.notifier)
                        .sendSearchResult(),
                  ),
                ],
                const SizedBox(height: RetroMetrics.spaceLarge),
                _ContactsToolbar(
                  count: contacts.contacts.length,
                  disabled: contacts.isSubmitting,
                  onRefresh: () =>
                      ref.read(contactsControllerProvider.notifier).refresh(),
                ),
                const SizedBox(height: RetroMetrics.spaceSmall),
                Expanded(
                  child: contacts.contacts.isEmpty
                      ? const Center(child: Text('No contacts yet'))
                      : ListView.separated(
                          itemCount: contacts.contacts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: RetroMetrics.spaceSmall),
                          itemBuilder: (context, index) => _ContactRow(
                            contact: contacts.contacts[index],
                            accessToken: accessToken,
                            disabled: contacts.isSubmitting,
                            onMessage: () => widget.onOpenConversation(
                              contacts.contacts[index].user.id,
                            ),
                            onRemove: () => ref
                                .read(contactsControllerProvider.notifier)
                                .remove(contacts.contacts[index].user.id),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _search(bool isSubmitting) {
    if (isSubmitting || _usernameController.text.trim().isEmpty) {
      return;
    }
    ref
        .read(contactsControllerProvider.notifier)
        .search(_usernameController.text);
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.disabled,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool disabled;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Search by username',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: RetroMetrics.spaceSmall),
        FilledButton(
          onPressed: disabled ? null : onSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class _ContactsToolbar extends StatelessWidget {
  const _ContactsToolbar({
    required this.count,
    required this.disabled,
    required this.onRefresh,
  });

  final int count;
  final bool disabled;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$count contacts', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh contacts',
          onPressed: disabled ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({
    required this.displayName,
    required this.username,
    required this.disabled,
    required this.onSend,
  });

  final String displayName;
  final String username;
  final bool disabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _BorderedRow(
      child: Row(
        children: [
          Expanded(child: Text('$displayName · @$username')),
          FilledButton(
            onPressed: disabled ? null : onSend,
            child: const Text('Add contact'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
  });

  final Contact contact;
  final String accessToken;
  final bool disabled;
  final VoidCallback onMessage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _BorderedRow(
      child: Row(
        children: [
          ProfileAvatar(
            name: contact.user.displayName,
            accessToken: accessToken,
            avatarUrl: contact.user.avatarUrl,
            radius: 18,
          ),
          const SizedBox(width: RetroMetrics.spaceMedium),
          Expanded(
            child: Text(
              '${contact.user.displayName}\n@${contact.user.username}',
            ),
          ),
          TextButton(
            onPressed: disabled ? null : onRemove,
            child: const Text('Remove'),
          ),
          const SizedBox(width: RetroMetrics.spaceSmall),
          FilledButton(
            onPressed: disabled ? null : onMessage,
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }
}

class _BorderedRow extends StatelessWidget {
  const _BorderedRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: RetroColors.glass,
      padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
      radius: 14,
      shadows: const [],
      child: child,
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}
