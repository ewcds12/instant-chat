part of 'messages_page.dart';

extension _MessagesPageContactInfo on _MessagesPageState {
  Widget _buildContactInfo(String accessToken) {
    final contacts = ref.watch(contactsControllerProvider);
    return ContactDetailPanel(
      user: widget.conversation.peer,
      accessToken: accessToken,
      disabled: contacts.asData?.value.isSubmitting ?? false,
      conversationId: widget.conversation.id,
      onBack: _closeContactInfo,
      onMessage: _closeContactInfo,
      onRemove: _confirmRemoveContact,
    );
  }

  void _openContactInfo() {
    _setContactInfoVisible(true);
  }

  void _closeContactInfo() {
    _setContactInfoVisible(false);
  }

  Future<void> _confirmRemoveContact() async {
    final peer = widget.conversation.peer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Delete ${peer.displayName} from your contacts and remove this chat from Chats? Message history will return if you add each other again.',
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
    await ref.read(contactsControllerProvider.future);
    if (!mounted) {
      return;
    }
    final deleted = await ref
        .read(contactsControllerProvider.notifier)
        .remove(peer.id);
    if (!deleted || !mounted) {
      return;
    }
    ref.read(selectedConversationIdProvider.notifier).select(null);
    ref.invalidate(conversationsControllerProvider);
    _closeContactInfo();
  }
}
