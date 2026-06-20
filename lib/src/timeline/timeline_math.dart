import 'package:intl/intl.dart';

import '../models/mobile_all_day_event.dart';
import 'timeline_model.dart';

class TimelineMath {
  static final DateFormat _monthHeaderFormat = DateFormat('MMMM yyyy');

  static const List<int> _eventColors = <int>[
    0xFF4F46E5,
    0xFF0F766E,
    0xFFEA580C,
    0xFFBE185D,
    0xFF15803D,
    0xFF7C3AED,
    0xFF0284C7,
    0xFFA16207,
    0xFFDB2777,
    0xFF2563EB,
  ];

  static TimelineModel buildModel(List<MobileAllDayEvent> sourceEvents) {
    final windowStart = _startOfDay(DateTime.now());
    final windowEnd = DateTime(
      windowStart.year,
      windowStart.month + 6,
      windowStart.day,
    );
    final days = _buildDays(windowStart, windowEnd);
    final months = _buildMonths(days);

    final rows =
        sourceEvents
            .where((event) => !event.endDate.isBefore(windowStart))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final modeledRows = <TimelineEventRow>[];
    for (var i = 0; i < rows.length; i += 1) {
      final event = rows[i];
      final start = _startOfDay(event.startDate);
      final end = _startOfDay(event.endDate);

      final startIndex = _clampDayDiff(
        start.difference(windowStart).inDays,
        days.length - 1,
      );
      final endIndex = _clampDayDiff(
        end.difference(windowStart).inDays,
        days.length - 1,
      );
      final normalizedEndIndex = endIndex < startIndex ? startIndex : endIndex;

      modeledRows.add(
        TimelineEventRow(
          event: event,
          startIndex: startIndex,
          endIndex: normalizedEndIndex,
          color: _eventColors[i % _eventColors.length],
          startedBeforeWindow: start.isBefore(windowStart),
        ),
      );
    }

    return TimelineModel(days: days, months: months, rows: modeledRows);
  }

  static List<DateTime> _buildDays(DateTime start, DateTime end) {
    final days = <DateTime>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(day);
    }
    return days;
  }

  static List<TimelineMonthGroup> _buildMonths(List<DateTime> days) {
    final groups = <TimelineMonthGroup>[];
    var startIndex = 0;

    while (startIndex < days.length) {
      final anchor = days[startIndex];
      var endIndex = startIndex;

      while (endIndex + 1 < days.length &&
          days[endIndex + 1].month == anchor.month &&
          days[endIndex + 1].year == anchor.year) {
        endIndex += 1;
      }

      groups.add(
        TimelineMonthGroup(
          label: _monthHeaderFormat.format(anchor),
          startIndex: startIndex,
          endIndex: endIndex,
        ),
      );
      startIndex = endIndex + 1;
    }

    return groups;
  }

  static DateTime _startOfDay(DateTime input) {
    return DateTime(input.year, input.month, input.day);
  }

  static int _clampDayDiff(int value, int maxIndex) {
    if (value < 0) return 0;
    if (value > maxIndex) return maxIndex;
    return value;
  }
}
