import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_panel.dart';
import 'package:instant_chat/features/contacts/presentation/contact_directory.dart';
import 'package:instant_chat/features/contacts/presentation/contact_remark_dialog.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_selection.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({required this.onOpenConversation, super.key});

  final Future<void> Function(String userId) onOpenConversation;

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final _searchController = TextEditingController();
  String _directoryQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider);
    final session = ref.watch(authControllerProvider).asData?.value.session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final accessToken = session.accessToken;
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadFailure(
        message: _contactLoadFailureMessage(error),
        onRetry: () => ref.invalidate(contactsControllerProvider),
      ),
      data: (contacts) {
        final selectedContact = _selectedContact(
          contacts.contacts,
          ref.watch(selectedContactUserIdProvider),
        );
        return Row(
          children: [
            SizedBox(
              key: const Key('contact-directory-column'),
              width: RetroMetrics.contactDirectoryWidth,
              child: ContactDirectory(
                contacts: contacts.contacts,
                incomingRequests: contacts.incoming,
                accessToken: accessToken,
                query: _directoryQuery,
                selectedUserId: selectedContact?.user.id,
                searchController: _searchController,
                isSubmitting: contacts.isSubmitting,
                searchResult: contacts.searchResult,
                errorMessage: contacts.errorMessage,
                onQueryChanged: _setDirectoryQuery,
                onSearchExactId: _searchExactId,
                onSendRequest: () => ref
                    .read(contactsControllerProvider.notifier)
                    .sendSearchResult(),
                onAcceptRequest: _acceptRequest,
                onDeclineRequest: (request) => ref
                    .read(contactsControllerProvider.notifier)
                    .reject(request.id),
                onSelect: (contact) => ref
                    .read(selectedContactUserIdProvider.notifier)
                    .select(contact.user.id),
              ),
            ),
            VerticalDivider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: ContactDetailPanel(
                user: selectedContact?.user,
                remark: selectedContact?.remark ?? '',
                accessToken: accessToken,
                disabled: contacts.isSubmitting,
                onMessage: selectedContact == null
                    ? null
                    : () => widget.onOpenConversation(selectedContact.user.id),
                onRemove: selectedContact == null
                    ? null
                    : () => _confirmRemove(selectedContact),
                onSetRemark: selectedContact == null
                    ? null
                    : () => _setRemark(selectedContact),
              ),
            ),
          ],
        );
      },
    );
  }

  Contact? _selectedContact(List<Contact> contacts, String? selectedUserId) {
    if (contacts.isEmpty) {
      return null;
    }
    for (final contact in contacts) {
      if (contact.user.id == selectedUserId) {
        return contact;
      }
    }
    return contacts.first;
  }

  void _setDirectoryQuery(String value) {
    setState(() => _directoryQuery = value);
  }

  void _searchExactId() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }
    ref.read(contactsControllerProvider.notifier).search(query);
  }

  Future<void> _acceptRequest(ContactRequest request) async {
    final accepted = await ref
        .read(contactsControllerProvider.notifier)
        .accept(request.id);
    if (!accepted || !mounted) {
      return;
    }
    ref.invalidate(conversationsControllerProvider);
    ref.read(selectedContactUserIdProvider.notifier).select(request.user.id);
  }

  Future<void> _confirmRemove(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Delete ${contact.user.displayName} from your contacts and remove this chat from Chats? Message history will return if you add each other again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await ref
        .read(contactsControllerProvider.notifier)
        .remove(contact.user.id);
    if (!deleted || !mounted) {
      return;
    }
    ref.read(selectedConversationIdProvider.notifier).select(null);
    ref.invalidate(conversationsControllerProvider);
    if (!mounted ||
        ref.read(selectedContactUserIdProvider) != contact.user.id) {
      return;
    }
    ref.read(selectedContactUserIdProvider.notifier).select(null);
  }

  Future<void> _setRemark(Contact contact) async {
    final remark = await showContactRemarkDialog(
      context: context,
      originalName: contact.user.displayName,
      currentRemark: contact.remark,
    );
    if (remark == null || remark == contact.remark || !mounted) {
      return;
    }
    await ref
        .read(contactsControllerProvider.notifier)
        .setRemark(contact.user.id, remark);
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

String _contactLoadFailureMessage(Object error) {
  return switch (error) {
    ApiFailure failure => failure.message,
    FormatException _ => 'The server returned an invalid contact response.',
    _ => 'Contacts could not be loaded.',
  };
}
