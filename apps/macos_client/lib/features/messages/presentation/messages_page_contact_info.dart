part of 'messages_page.dart';

extension _MessagesPageContactInfo on _MessagesPageState {
  Widget _buildContactInfo(String accessToken) {
    final contacts = ref.watch(contactsControllerProvider);
    final remark =
        contacts.asData?.value.contacts
            .where((contact) => contact.user.id == widget.conversation.peer.id)
            .map((contact) => contact.remark)
            .firstOrNull ??
        '';
    return ContactDetailPanel(
      user: widget.conversation.peer,
      remark: remark,
      accessToken: accessToken,
      disabled: contacts.asData?.value.isSubmitting ?? false,
      conversationId: widget.conversation.id,
      onBack: _closeContactInfo,
      onMessage: _closeContactInfo,
      onRemove: _confirmRemoveContact,
      onSetRemark: () => _setContactRemark(remark),
    );
  }

  Future<void> _setContactRemark(String currentRemark) async {
    final peer = widget.conversation.peer;
    final remark = await showContactRemarkDialog(
      context: context,
      originalName: peer.displayName,
      currentRemark: currentRemark,
    );
    if (remark == null || remark == currentRemark || !mounted) {
      return;
    }
    await ref.read(contactsControllerProvider.future);
    if (!mounted) {
      return;
    }
    await ref
        .read(contactsControllerProvider.notifier)
        .setRemark(peer.id, remark);
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
        title: Text(context.l10n.ui('Delete Contact?')),
        content: Text(context.l10n.deleteContactDescription(peer.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.ui('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.ui('Delete')),
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
