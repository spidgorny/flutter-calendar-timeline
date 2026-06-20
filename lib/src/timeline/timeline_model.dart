import '../models/mobile_all_day_event.dart';

class TimelineMonthGroup {
  const TimelineMonthGroup({
    required this.label,
    required this.startIndex,
    required this.endIndex,
  });

  final String label;
  final int startIndex;
  final int endIndex;
}

class TimelineEventRow {
  const TimelineEventRow({
    required this.event,
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.startedBeforeWindow,
  });

  final MobileAllDayEvent event;
  final int startIndex;
  final int endIndex;
  final int color;
  final bool startedBeforeWindow;
}

class TimelineModel {
  const TimelineModel({
    required this.days,
    required this.months,
    required this.rows,
  });

  final List<DateTime> days;
  final List<TimelineMonthGroup> months;
  final List<TimelineEventRow> rows;
}
