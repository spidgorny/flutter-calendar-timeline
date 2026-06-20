import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/mobile_all_day_event.dart';
import '../services/google_auth_service.dart';
import '../services/mobile_events_api.dart';
import '../timeline/timeline_math.dart';
import '../timeline/timeline_model.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final GoogleAuthService _authService = GoogleAuthService();
  late final MobileEventsApi _eventsApi = MobileEventsApi(
    baseUrl: AppConfig.apiBaseUrl,
    calendarId: AppConfig.calendarId,
  );

  GoogleSignInAccount? _account;
  String? _accessToken;
  List<MobileAllDayEvent> _events = const [];
  bool _authBusy = false;
  bool _eventsBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _authBusy = true;
      _error = null;
    });

    try {
      final account = await _authService.signInSilently();
      if (account == null) {
        setState(() {
          _authBusy = false;
        });
        return;
      }

      final token = await _authService.getAccessToken(account);
      if (token == null || token.isEmpty) {
        throw Exception('Google access token is missing.');
      }

      setState(() {
        _account = account;
        _accessToken = token;
        _authBusy = false;
      });
      await _loadEvents();
    } catch (error) {
      setState(() {
        _authBusy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _authBusy = true;
      _error = null;
    });

    try {
      final account = await _authService.signIn();
      if (account == null) {
        setState(() {
          _authBusy = false;
        });
        return;
      }

      final token = await _authService.getAccessToken(account);
      if (token == null || token.isEmpty) {
        throw Exception('Google access token is missing.');
      }

      setState(() {
        _account = account;
        _accessToken = token;
        _authBusy = false;
      });
      await _loadEvents();
    } catch (error) {
      setState(() {
        _authBusy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    setState(() {
      _account = null;
      _accessToken = null;
      _events = const [];
      _error = null;
    });
  }

  Future<void> _loadEvents() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Missing access token. Sign in again.';
      });
      return;
    }

    setState(() {
      _eventsBusy = true;
      _error = null;
    });

    try {
      final events = await _eventsApi.fetchAllDayEvents(accessToken: token);
      if (!mounted) return;
      setState(() {
        _events = events;
        _eventsBusy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _eventsBusy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _account != null && _accessToken != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Timeline'),
        actions: signedIn
            ? [
                IconButton(
                  onPressed: _eventsBusy ? null : _loadEvents,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _InfoHeader(
              signedInEmail: _account?.email,
              apiBaseUrl: AppConfig.apiBaseUrl,
              calendarId: AppConfig.calendarId,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Material(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _authBusy
                  ? const Center(child: CircularProgressIndicator())
                  : !signedIn
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: _signIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
                    )
                  : _eventsBusy
                  ? const Center(child: CircularProgressIndicator())
                  : _TimelineBoard(events: _events),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.signedInEmail,
    required this.apiBaseUrl,
    required this.calendarId,
  });

  final String? signedInEmail;
  final String apiBaseUrl;
  final String calendarId;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (signedInEmail != null)
            Text('Signed in as $signedInEmail', style: labelStyle),
          Text('API: $apiBaseUrl', style: labelStyle),
          Text('Calendar: $calendarId', style: labelStyle),
        ],
      ),
    );
  }
}

class _TimelineBoard extends StatelessWidget {
  const _TimelineBoard({required this.events});

  final List<MobileAllDayEvent> events;

  static const double _labelWidth = 270;
  static const double _dayWidth = 32;
  static const double _headerHeight = 46;
  static const double _rowHeight = 66;

  @override
  Widget build(BuildContext context) {
    final timeline = TimelineMath.buildModel(events);
    final totalTrackWidth = timeline.days.length * _dayWidth;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (timeline.rows.isEmpty) {
      return const Center(
        child: Text('No current or upcoming all-day events.'),
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _labelWidth + totalTrackWidth,
          child: Column(
            children: [
              _buildMonthRow(timeline.months),
              _buildDayRow(timeline.days, todayStart),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: timeline.rows.length,
                  itemBuilder: (context, index) {
                    final row = timeline.rows[index];
                    return _TimelineEventRowWidget(
                      row: row,
                      rowHeight: _rowHeight,
                      labelWidth: _labelWidth,
                      dayWidth: _dayWidth,
                      dayCount: timeline.days.length,
                      days: timeline.days,
                      today: todayStart,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthRow(List<TimelineMonthGroup> months) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          Container(
            width: _labelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Event',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ...months.asMap().entries.map((entry) {
            final month = entry.value;
            final width = (month.endIndex - month.startIndex + 1) * _dayWidth;
            final hue = (entry.key * 47) % 360;
            return Container(
              width: width,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1, hue.toDouble(), 0.14, 0.98).toColor(),
                    HSVColor.fromAHSV(1, hue.toDouble(), 0.18, 0.92).toColor(),
                  ],
                ),
                border: const Border(
                  right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Text(
                month.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayRow(List<DateTime> days, DateTime today) {
    final dayLabel = DateFormat('E');
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          Container(
            width: _labelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Text('Range'),
          ),
          ...days.map((day) {
            final isToday = day == today;
            return Container(
              width: _dayWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFDBEAFE) : null,
                border: const Border(
                  right: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    dayLabel.format(day),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineEventRowWidget extends StatelessWidget {
  const _TimelineEventRowWidget({
    required this.row,
    required this.rowHeight,
    required this.labelWidth,
    required this.dayWidth,
    required this.dayCount,
    required this.days,
    required this.today,
  });

  final TimelineEventRow row;
  final double rowHeight;
  final double labelWidth;
  final double dayWidth;
  final int dayCount;
  final List<DateTime> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final barLeft = row.startIndex * dayWidth;
    final barWidth = (row.endIndex - row.startIndex + 1) * dayWidth;
    final barColor = Color(row.color);
    final isWeekend = days
        .map((day) {
          final weekday = day.weekday;
          return weekday == DateTime.saturday || weekday == DateTime.sunday;
        })
        .toList(growable: false);

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: labelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.event.rangeLabel} • ${row.event.durationDays}d${row.startedBeforeWindow ? ' • Continues' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: dayCount * dayWidth,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Row(
                  children: List.generate(dayCount, (index) {
                    final isToday = days[index] == today;
                    return Container(
                      width: dayWidth,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFFEFF6FF)
                            : isWeekend[index]
                            ? const Color(0xFFFAFAFA)
                            : null,
                        border: const Border(
                          right: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned(
                  left: barLeft,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: barWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withValues(alpha: 0.8)],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      row.event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
