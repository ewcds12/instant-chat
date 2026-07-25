import 'package:flutter/material.dart';

class MessageLoadFailure extends StatelessWidget {
  const MessageLoadFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

class MessageErrorBar extends StatelessWidget {
  const MessageErrorBar({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}

class MessageRetryBar extends StatelessWidget {
  const MessageRetryBar({
    required this.disabled,
    required this.onRetry,
    super.key,
  });

  final bool disabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Expanded(child: Text('Message not sent')),
          TextButton(
            onPressed: disabled ? null : onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
