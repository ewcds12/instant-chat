import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

Future<void> showMessageSearch(BuildContext context, List<Message> messages) {
  return showSearch<void>(
    context: context,
    delegate: _MessageSearchDelegate(messages, context.l10n),
  );
}

class _MessageSearchDelegate extends SearchDelegate<void> {
  _MessageSearchDelegate(this.messages, this.localizations);

  final List<Message> messages;
  final AppLocalizations localizations;

  @override
  String get searchFieldLabel => localizations.ui('Search messages');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: context.l10n.ui('Clear search'),
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.ui('Close search'),
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final matches = normalized.isEmpty
        ? const <Message>[]
        : messages
              .where(
                (message) => message.body.toLowerCase().contains(normalized),
              )
              .toList();
    if (normalized.isEmpty) {
      return Center(
        child: Text(context.l10n.ui('Type to search loaded messages.')),
      );
    }
    if (matches.isEmpty) {
      return Center(child: Text(context.l10n.ui('No matching messages.')));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final message = matches[index];
        return ListTile(
          title: Text(
            message.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('@${message.sender.username}'),
        );
      },
    );
  }
}
