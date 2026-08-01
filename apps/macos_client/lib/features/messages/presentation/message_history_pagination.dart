part of 'message_history.dart';

const _olderMessageLoadThreshold = 120.0;

bool _shouldLoadOlderMessages(
  ScrollNotification notification, {
  required MessagesState value,
  required int targetIndex,
}) {
  if (targetIndex >= 0 ||
      value.nextCursor == null ||
      value.isLoadingOlder ||
      value.isSending ||
      notification.depth != 0 ||
      notification.metrics.pixels > _olderMessageLoadThreshold) {
    return false;
  }
  return switch (notification) {
    ScrollUpdateNotification(:final scrollDelta) =>
      scrollDelta != null && scrollDelta < 0,
    OverscrollNotification(:final overscroll) => overscroll < 0,
    _ => false,
  };
}

class _MessageHistoryLoadingIndicator extends StatelessWidget {
  const _MessageHistoryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: RetroMetrics.spaceSmall,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox.square(
          key: const Key('message-history-loading-older'),
          dimension: RetroMetrics.spaceMedium,
          child: const CircularProgressIndicator(
            strokeWidth: RetroMetrics.border * 2,
          ),
        ),
      ),
    );
  }
}
