import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/presentation/message_timestamp.dart';

part 'contact_message_search_widgets.dart';

Future<Message?> showContactMessageSearch({
  required BuildContext context,
  required Contact contact,
  required String currentUserId,
  required String conversationId,
  required String accessToken,
  required MessageGateway gateway,
}) {
  return showMessageHistorySearch(
    context: context,
    participantName: contact.user.displayName,
    currentUserId: currentUserId,
    conversationId: conversationId,
    accessToken: accessToken,
    gateway: gateway,
  );
}

Future<Message?> showMessageHistorySearch({
  required BuildContext context,
  required String participantName,
  required String currentUserId,
  required String conversationId,
  required String accessToken,
  required MessageGateway gateway,
}) {
  return showDialog<Message>(
    context: context,
    builder: (context) => _ContactMessageSearchDialog(
      participantName: participantName,
      currentUserId: currentUserId,
      conversationId: conversationId,
      accessToken: accessToken,
      gateway: gateway,
    ),
  );
}

class _ContactMessageSearchDialog extends StatefulWidget {
  const _ContactMessageSearchDialog({
    required this.participantName,
    required this.currentUserId,
    required this.conversationId,
    required this.accessToken,
    required this.gateway,
  });

  final String participantName;
  final String currentUserId;
  final String conversationId;
  final String accessToken;
  final MessageGateway gateway;

  @override
  State<_ContactMessageSearchDialog> createState() =>
      _ContactMessageSearchDialogState();
}

class _ContactMessageSearchDialogState
    extends State<_ContactMessageSearchDialog> {
  final _queryController = TextEditingController();
  final _messages = <String, Message>{};
  String? _nextCursor;
  String? _errorMessage;
  var _isLoading = false;
  var _isComplete = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = searchContactMessages(
      _messages.values,
      _queryController.text,
    );
    return Dialog(
      key: const Key('contact-message-search-dialog'),
      insetPadding: const EdgeInsets.all(RetroMetrics.spaceLarge),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: RetroMetrics.contactMessageSearchMaxWidth,
          maxHeight: RetroMetrics.contactMessageSearchMaxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchHeader(
                contactName: widget.participantName,
                onCancel: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: RetroMetrics.spaceMedium),
              TextField(
                key: const Key('contact-message-search-field'),
                controller: _queryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _clearQuery,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _openFirst(matches),
              ),
              const SizedBox(height: 12),
              _SearchStatus(
                resultCount: matches.length,
                hasQuery: _queryController.text.trim().isNotEmpty,
                isLoading: _isLoading,
                isComplete: _isComplete,
                errorMessage: _errorMessage,
                onRetry: _loadHistory,
              ),
              const SizedBox(height: RetroMetrics.spaceSmall),
              Expanded(
                child: _SearchResults(
                  matches: matches,
                  query: _queryController.text,
                  currentUserId: widget.currentUserId,
                  isComplete: _isComplete,
                  onOpen: (message) => Navigator.of(context).pop(message),
                ),
              ),
              if (matches.isNotEmpty) ...[
                const SizedBox(height: RetroMetrics.spaceMedium),
                Text(
                  'Press Return to open the first result',
                  key: const Key('contact-message-search-return-hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    if (_isLoading || _isComplete) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    var before = _messages.isEmpty ? null : _nextCursor;
    try {
      while (mounted) {
        final page = await widget.gateway.list(
          accessToken: widget.accessToken,
          conversationId: widget.conversationId,
          before: before,
          limit: 100,
        );
        if (!mounted) {
          return;
        }
        for (final message in page.messages) {
          _messages[message.id] = message;
        }
        final nextCursor = page.nextCursor;
        if (nextCursor != null && nextCursor == before) {
          throw const FormatException(
            'Message history cursor did not advance.',
          );
        }
        setState(() {
          _nextCursor = nextCursor;
          _isComplete = nextCursor == null;
        });
        if (nextCursor == null) {
          break;
        }
        before = nextCursor;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nextCursor = before;
          _errorMessage = 'Message history could not be loaded.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearQuery() {
    _queryController.clear();
    setState(() {});
  }

  void _openFirst(List<Message> matches) {
    if (matches.isNotEmpty) {
      Navigator.of(context).pop(matches.first);
    }
  }
}

List<Message> searchContactMessages(Iterable<Message> messages, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }
  final matches = messages
      .where(
        (message) =>
            message.recalledAt == null &&
            message.body.toLowerCase().contains(normalized),
      )
      .toList(growable: false);
  return matches
    ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
}
