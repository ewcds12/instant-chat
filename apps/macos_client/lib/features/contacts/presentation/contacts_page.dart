import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';

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
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _LoadFailure(
        onRetry: () => ref.invalidate(contactsControllerProvider),
      ),
      data: (contacts) => Padding(
        padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contacts', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: RetroMetrics.spaceSmall),
            const Text(
              'Search by exact username. Email addresses stay private.',
            ),
            const SizedBox(height: RetroMetrics.spaceMedium),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Search by username',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) => _search(contacts.isSubmitting),
                  ),
                ),
                const SizedBox(width: RetroMetrics.spaceSmall),
                FilledButton(
                  onPressed: contacts.isSubmitting
                      ? null
                      : () => _search(false),
                  child: const Text('Search'),
                ),
              ],
            ),
            if (contacts.errorMessage case final message?) ...[
              const SizedBox(height: RetroMetrics.spaceSmall),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            Row(
              children: [
                Text(
                  '${contacts.contacts.length} contacts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh contacts',
                  onPressed: contacts.isSubmitting
                      ? null
                      : () => ref
                            .read(contactsControllerProvider.notifier)
                            .refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
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
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
  });

  final Contact contact;
  final bool disabled;
  final VoidCallback onMessage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _BorderedRow(
      child: Row(
        children: [
          const Icon(Icons.person_outline),
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
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: RetroMetrics.border,
        ),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
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
