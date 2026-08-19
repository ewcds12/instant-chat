part of 'contact_message_search.dart';

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.contactName, required this.onCancel});

  final String contactName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.searchMessagesWith(contactName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: RetroMetrics.spaceMedium),
        TextButton(onPressed: onCancel, child: Text(context.l10n.ui('Cancel'))),
      ],
    );
  }
}

class _SearchStatus extends StatelessWidget {
  const _SearchStatus({
    required this.resultCount,
    required this.hasQuery,
    required this.isLoading,
    required this.isComplete,
    required this.errorMessage,
    required this.onRetry,
  });

  final int resultCount;
  final bool hasQuery;
  final bool isLoading;
  final bool isComplete;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = !hasQuery
        ? context.l10n.ui('Search your complete conversation history.')
        : context.l10n.resultCount(resultCount, partial: isLoading);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Text(
              errorMessage == null ? label : context.l10n.ui(errorMessage!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: errorMessage == null
                    ? colors.onSurfaceVariant
                    : colors.error,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (errorMessage != null && !isComplete)
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.ui('Try Again')),
            ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.matches,
    required this.query,
    required this.currentUserId,
    required this.isComplete,
    required this.onOpen,
  });

  final List<Message> matches;
  final String query;
  final String currentUserId;
  final bool isComplete;
  final ValueChanged<Message> onOpen;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return Center(
        child: Text(context.l10n.ui('Type a word or phrase to search.')),
      );
    }
    if (matches.isEmpty) {
      return Center(
        child: Text(
          context.l10n.ui(
            isComplete ? 'No matching messages.' : 'Searching history…',
          ),
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
      ),
      child: ListView.separated(
        key: const Key('contact-message-search-results'),
        itemCount: matches.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: RetroMetrics.spaceMedium,
          endIndent: RetroMetrics.spaceMedium,
        ),
        itemBuilder: (context, index) {
          final message = matches[index];
          return _SearchResultRow(
            message: message,
            senderLabel: message.sender.id == currentUserId
                ? context.l10n.ui('You')
                : message.sender.displayName,
            onOpen: () => onOpen(message),
          );
        },
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.message,
    required this.senderLabel,
    required this.onOpen,
  });

  final Message message;
  final String senderLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('contact-message-search-result-${message.id}'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RetroMetrics.spaceMedium,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        senderLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizedMessageTimestampLabel(
                          context,
                          message.createdAt,
                          now: DateTime.now(),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: RetroMetrics.spaceMedium),
            Text(
              context.l10n.ui('Open'),
              style: TextStyle(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
