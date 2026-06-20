class MobileAllDayEvent {
  const MobileAllDayEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.rangeLabel,
    this.description,
    this.location,
    this.htmlLink,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String rangeLabel;
  final String? description;
  final String? location;
  final String? htmlLink;

  factory MobileAllDayEvent.fromJson(Map<String, dynamic> json) {
    return MobileAllDayEvent(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Untitled event',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 1,
      rangeLabel: json['rangeLabel'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      htmlLink: json['htmlLink'] as String?,
    );
  }
}
