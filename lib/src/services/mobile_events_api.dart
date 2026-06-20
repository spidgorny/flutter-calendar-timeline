import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mobile_all_day_event.dart';

class MobileEventsApi {
  const MobileEventsApi({required this.baseUrl, required this.calendarId});

  final String baseUrl;
  final String calendarId;

  Future<List<MobileAllDayEvent>> fetchAllDayEvents({
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/mobile/all-day-events?calendarId=${Uri.encodeQueryComponent(calendarId)}',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          (decoded['error'] as String?) ?? 'Failed to load events.';
      throw Exception(errorMessage);
    }

    final rawEvents = (decoded['events'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return rawEvents.map(MobileAllDayEvent.fromJson).toList();
  }
}
