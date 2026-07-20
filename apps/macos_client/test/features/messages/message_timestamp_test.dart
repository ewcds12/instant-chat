import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/presentation/message_timestamp.dart';

void main() {
  final now = DateTime(2026, 7, 20, 15);

  test(
    'shows timestamps for the first message, date changes, and five-minute gaps',
    () {
      expect(
        shouldShowMessageTimestamp(
          previousTimestamp: null,
          timestamp: DateTime(2026, 7, 20, 12),
        ),
        isTrue,
      );
      expect(
        shouldShowMessageTimestamp(
          previousTimestamp: DateTime(2026, 7, 20, 12),
          timestamp: DateTime(2026, 7, 20, 12, 4, 59),
        ),
        isFalse,
      );
      expect(
        shouldShowMessageTimestamp(
          previousTimestamp: DateTime(2026, 7, 20, 12),
          timestamp: DateTime(2026, 7, 20, 12, 5),
        ),
        isTrue,
      );
      expect(
        shouldShowMessageTimestamp(
          previousTimestamp: DateTime(2026, 7, 19, 23, 59),
          timestamp: DateTime(2026, 7, 20),
        ),
        isTrue,
      );
    },
  );

  test('formats today, recent days, and older dates', () {
    expect(
      messageTimestampLabel(DateTime(2026, 7, 20, 14, 30), now: now),
      '14:30',
    );
    expect(
      messageTimestampLabel(DateTime(2026, 7, 19, 14, 30), now: now),
      'Yesterday 14:30',
    );
    expect(
      messageTimestampLabel(DateTime(2026, 7, 18, 14, 30), now: now),
      'Saturday 14:30',
    );
    expect(
      messageTimestampLabel(DateTime(2026, 7, 10, 14, 30), now: now),
      'Jul 10, 2026 14:30',
    );
  });
}
