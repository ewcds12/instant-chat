import 'package:flutter/material.dart';

const messageTimestampInterval = Duration(minutes: 5);

class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({
    required this.timestamp,
    required this.now,
    super.key,
  });

  final DateTime timestamp;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        messageTimestampLabel(timestamp, now: now),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

bool shouldShowMessageTimestamp({
  required DateTime? previousTimestamp,
  required DateTime timestamp,
}) {
  if (previousTimestamp == null) {
    return true;
  }
  final previous = previousTimestamp.toLocal();
  final current = timestamp.toLocal();
  return !_isSameDay(previous, current) ||
      current.difference(previous) >= messageTimestampInterval;
}

String messageTimestampLabel(DateTime timestamp, {required DateTime now}) {
  final localTimestamp = timestamp.toLocal();
  final localNow = now.toLocal();
  final dayDifference = _startOfDay(
    localNow,
  ).difference(_startOfDay(localTimestamp)).inDays;
  final time = _timeLabel(localTimestamp);
  if (dayDifference == 0) {
    return time;
  }
  if (dayDifference == 1) {
    return 'Yesterday $time';
  }
  if (dayDifference > 1 && dayDifference < 7) {
    return '${_weekdayLabel(localTimestamp.weekday)} $time';
  }
  return '${_monthLabel(localTimestamp.month)} ${localTimestamp.day}, '
      '${localTimestamp.year} $time';
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _isSameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Monday',
  DateTime.tuesday => 'Tuesday',
  DateTime.wednesday => 'Wednesday',
  DateTime.thursday => 'Thursday',
  DateTime.friday => 'Friday',
  DateTime.saturday => 'Saturday',
  _ => 'Sunday',
};

String _monthLabel(int month) => switch (month) {
  DateTime.january => 'Jan',
  DateTime.february => 'Feb',
  DateTime.march => 'Mar',
  DateTime.april => 'Apr',
  DateTime.may => 'May',
  DateTime.june => 'Jun',
  DateTime.july => 'Jul',
  DateTime.august => 'Aug',
  DateTime.september => 'Sep',
  DateTime.october => 'Oct',
  DateTime.november => 'Nov',
  _ => 'Dec',
};
