import 'package:flutter/material.dart';

import 'screens/timeline_page.dart';

class CalendarTimelineApp extends StatelessWidget {
  const CalendarTimelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Calendar Timeline',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const TimelinePage(),
    );
  }
}
