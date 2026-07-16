import 'package:flutter/material.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

Future<void> showMessageSearch(BuildContext context, List<Message> messages) {
  return showSearch<void>(
    context: context,
    delegate: _MessageSearchDelegate(messages),
  );
}

class _MessageSearchDelegate extends SearchDelegate<void> {
  _MessageSearchDelegate(this.messages);

  final List<Message> messages;

  @override
  String get searchFieldLabel => 'Search messages';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear search',
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Close search',
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
      return const Center(child: Text('Type to search loaded messages.'));
    }
    if (matches.isEmpty) {
      return const Center(child: Text('No matching messages.'));
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
