import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// CHERRY CREEK HIGH SCHOOL BELL SCHEDULE
// ---------------------------------------------------------------------------

/// One slot in the school day. Times are minutes after midnight.
class BellPeriod {
  const BellPeriod(this.name, this.startMin, this.endMin);

  final String name;
  final int startMin;
  final int endMin;
}

int _m(int hour24, int minute) => hour24 * 60 + minute;

/// Monday, Tuesday, Thursday, Friday
final List<BellPeriod> _regularDay = [
  BellPeriod('Period 1', _m(8, 20), _m(9, 12)),
  BellPeriod('Period 2', _m(9, 19), _m(10, 6)),
  BellPeriod('Period 3', _m(10, 13), _m(11, 0)),
  BellPeriod('Period 4', _m(11, 7), _m(11, 54)),
  BellPeriod('Period 5', _m(12, 1), _m(12, 48)),
  BellPeriod('Period 6', _m(12, 55), _m(13, 42)),
  BellPeriod('Period 7', _m(13, 49), _m(14, 36)),
  BellPeriod('Period 8', _m(14, 43), _m(15, 30)),
];

/// Wednesday (advisory schedule)
final List<BellPeriod> _wednesday = [
  BellPeriod('Period 1', _m(8, 20), _m(9, 0)),
  BellPeriod('Period 2', _m(9, 7), _m(9, 47)),
  BellPeriod('Advisory', _m(9, 54), _m(10, 48)),
  BellPeriod('Period 3', _m(10, 55), _m(11, 35)),
  BellPeriod('Period 4', _m(11, 42), _m(12, 22)),
  BellPeriod('Period 5', _m(12, 29), _m(13, 9)),
  BellPeriod('Period 6', _m(13, 16), _m(13, 56)),
  BellPeriod('Period 7', _m(14, 3), _m(14, 43)),
  BellPeriod('Period 8', _m(14, 50), _m(15, 30)),
];

List<BellPeriod> periodsFor(int weekday) {
  if (weekday == DateTime.saturday || weekday == DateTime.sunday) return [];
  return weekday == DateTime.wednesday ? _wednesday : _regularDay;
}

const List<String> _dayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

String _clock(int minutes) {
  final h24 = minutes ~/ 60;
  final m = minutes % 60;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h:${m.toString().padLeft(2, '0')} ${h24 >= 12 ? 'PM' : 'AM'}';
}

String _timeLeft(int seconds) {
  if (seconds < 60) return 'Less than 1 min';
  final mins = (seconds / 60).ceil();
  return mins == 1 ? '1 min' : '$mins min';
}

// ---------------------------------------------------------------------------
// DATA
// ---------------------------------------------------------------------------

/// What the student types in for a period.
class ClassInfo {
  const ClassInfo({this.name = '', this.room = ''});

  final String name;
  final String room;

  Map<String, dynamic> toJson() => {'name': name, 'room': room};

  factory ClassInfo.fromJson(Map<String, dynamic> json) => ClassInfo(
        name: (json['name'] ?? '') as String,
        room: (json['room'] ?? '') as String,
      );
}

enum Phase { noSchool, beforeSchool, inClass, passing, schoolOver }

class _Status {
  const _Status(this.phase, {this.current, this.next, this.secondsLeft = 0, this.progress = 0});

  final Phase phase;
  final BellPeriod? current;
  final BellPeriod? next;
  final int secondsLeft;
  final double progress;
}

// ---------------------------------------------------------------------------
// PAGE
// ---------------------------------------------------------------------------

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const String _classesKey = 'schedule_classes';
  static const String _alertsKey = 'schedule_alerts_on';

  Timer? _timer;
  DateTime _now = DateTime.now();
  Map<String, ClassInfo> _classes = {};
  bool _alertsOn = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh the countdown every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_classesKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _classes = map.map((k, v) => MapEntry(k, ClassInfo.fromJson(v as Map<String, dynamic>)));
      }
      _alertsOn = prefs.getBool(_alertsKey) ?? true;
    } catch (_) {
      _classes = {};
    }
    if (!mounted) return;
    setState(() => _loaded = true);
    _scheduleAlerts();
  }

  Future<void> _saveClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_classesKey, jsonEncode(_classes.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
  }

  Future<void> _saveAlertsSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_alertsKey, _alertsOn);
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // PASSING PERIOD NOTIFICATIONS
  // -------------------------------------------------------------------------

  int _alertId(int weekday, int index) => 2000 + weekday * 20 + index;

  /// Next time the given weekday and clock time happens.
  tz.TZDateTime _nextWeekly(int weekday, int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < 8; i++) {
      final candidate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + i, minutes ~/ 60, minutes % 60,
      );
      if (candidate.weekday == weekday && candidate.isAfter(now)) return candidate;
    }
    return now.add(const Duration(days: 7));
  }

  String _alertBody(BellPeriod p, ClassInfo? info) {
    final what = (info != null && info.name.isNotEmpty) ? '${info.name} (${p.name})' : p.name;
    final room = info?.room ?? '';
    if (room.isNotEmpty) {
      return '$what is in $room and starts at ${_clock(p.startMin)}.';
    }
    return '$what starts at ${_clock(p.startMin)}.';
  }

  /// Cancels old alerts and sets up weekly alerts for every passing period.
  Future<void> _scheduleAlerts() async {
    try {
      await NotificationService.instance.init();
      final plugin = FlutterLocalNotificationsPlugin();

      for (var weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
        for (var i = 0; i < 12; i++) {
          await plugin.cancel(_alertId(weekday, i));
        }
      }
      if (!_alertsOn) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'passing_periods',
          'Passing periods',
          channelDescription: 'Tells you which class is next, where it is, and when it starts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (var weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
        final periods = periodsFor(weekday);
        // A passing period starts when the class before it ends.
        for (var i = 1; i < periods.length; i++) {
          final next = periods[i];
          await plugin.zonedSchedule(
            _alertId(weekday, i),
            'Passing period',
            _alertBody(next, _classes[next.name]),
            _nextWeekly(weekday, periods[i - 1].endMin),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    } catch (_) {
      // If notifications are blocked, the schedule still works on screen.
    }
  }

  // -------------------------------------------------------------------------
  // WHAT IS HAPPENING RIGHT NOW
  // -------------------------------------------------------------------------

  _Status _status() {
    final periods = periodsFor(_now.weekday);
    if (periods.isEmpty) return const _Status(Phase.noSchool);

    final secs = _now.hour * 3600 + _now.minute * 60 + _now.second;

    if (secs < periods.first.startMin * 60) {
      return _Status(
        Phase.beforeSchool,
        next: periods.first,
        secondsLeft: periods.first.startMin * 60 - secs,
      );
    }

    for (var i = 0; i < periods.length; i++) {
      final p = periods[i];
      final start = p.startMin * 60;
      final end = p.endMin * 60;
      final nextPeriod = i + 1 < periods.length ? periods[i + 1] : null;

      if (secs >= start && secs < end) {
        return _Status(
          Phase.inClass,
          current: p,
          next: nextPeriod,
          secondsLeft: end - secs,
          progress: (secs - start) / (end - start),
        );
      }
      if (nextPeriod != null && secs >= end && secs < nextPeriod.startMin * 60) {
        return _Status(
          Phase.passing,
          next: nextPeriod,
          secondsLeft: nextPeriod.startMin * 60 - secs,
        );
      }
    }
    return const _Status(Phase.schoolOver);
  }

  String _titleFor(BellPeriod p) {
    final info = _classes[p.name];
    return (info != null && info.name.isNotEmpty) ? info.name : p.name;
  }

  String _roomFor(BellPeriod p) {
    final room = _classes[p.name]?.room ?? '';
    return room.isNotEmpty ? room : 'Room not added yet';
  }

  Future<void> _editClass(BellPeriod p) async {
    final result = await showDialog<ClassInfo>(
      context: context,
      builder: (_) => _ClassEditDialog(periodName: p.name, initial: _classes[p.name]),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (result.name.isEmpty && result.room.isEmpty) {
        _classes.remove(p.name);
      } else {
        _classes[p.name] = result;
      }
    });
    await _saveClasses();
    // Rebuild the alerts so they use the new class and room.
    await _scheduleAlerts();
  }

  Future<void> _toggleAlerts(bool value) async {
    setState(() => _alertsOn = value);
    await _saveAlertsSetting();
    await _scheduleAlerts();
  }

  // -------------------------------------------------------------------------
  // SCREEN
  // -------------------------------------------------------------------------

  _StatusCard _buildStatusCard(_Status s) {
    switch (s.phase) {
      case Phase.inClass:
        final p = s.current!;
        final next = s.next;
        return _StatusCard(
          label: 'RIGHT NOW',
          title: _titleFor(p),
          detail: _roomFor(p),
          big: '${_timeLeft(s.secondsLeft)} left',
          progress: s.progress,
          footer: next == null
              ? 'This is the last class of the day.'
              : 'Next: ${_titleFor(next)} at ${_clock(next.startMin)}',
        );
      case Phase.passing:
        final next = s.next!;
        return _StatusCard(
          label: 'PASSING PERIOD',
          title: 'Go to ${_titleFor(next)}',
          detail: _roomFor(next),
          big: 'Starts in ${_timeLeft(s.secondsLeft)}',
          footer: 'Class starts at ${_clock(next.startMin)}',
        );
      case Phase.beforeSchool:
        final next = s.next!;
        return _StatusCard(
          label: 'GOOD MORNING',
          title: 'First class: ${_titleFor(next)}',
          detail: _roomFor(next),
          big: 'Starts in ${_timeLeft(s.secondsLeft)}',
          footer: 'School starts at ${_clock(next.startMin)}',
        );
      case Phase.schoolOver:
        return _StatusCard(
          label: 'ALL DONE',
          title: 'School is over for today',
          big: _now.weekday == DateTime.friday ? 'Have a great weekend!' : 'See you tomorrow!',
        );
      case Phase.noSchool:
        return const _StatusCard(
          label: 'NO SCHOOL TODAY',
          title: 'Enjoy your day off',
          big: 'Next up: Monday',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule', style: TextStyle(fontSize: 26)), toolbarHeight: 72),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _status();
    final noSchool = status.phase == Phase.noSchool;
    final shownWeekday = noSchool ? DateTime.monday : _now.weekday;
    final periods = periodsFor(shownWeekday);
    final dayName = _dayNames[shownWeekday - 1];
    final heading = noSchool
        ? "$dayName's schedule"
        : (shownWeekday == DateTime.wednesday ? '$dayName · Advisory schedule' : dayName);

    final nowSecs = _now.hour * 3600 + _now.minute * 60 + _now.second;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontSize: 26)),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 24),
            Text(heading, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final p in periods) _buildPeriodTile(p, nowSecs, noSchool, colors),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                secondary: const Icon(Icons.notifications_active, size: 32),
                title: const Text('Passing period alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                  'Get a notification telling you your next class, where it is, and when it starts.',
                  style: TextStyle(fontSize: 16),
                ),
                value: _alertsOn,
                onChanged: _toggleAlerts,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Times are from the Cherry Creek High School bell schedule. Storm delay and special schedules are not included, and alerts repeat every week, including break weeks.',
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTile(BellPeriod p, int nowSecs, bool noSchool, ColorScheme colors) {
    final isCurrent = !noSchool && nowSecs >= p.startMin * 60 && nowSecs < p.endMin * 60;
    final isPast = !noSchool && nowSecs >= p.endMin * 60;
    final info = _classes[p.name];
    final hasName = info != null && info.name.isNotEmpty;
    final hasRoom = info != null && info.room.isNotEmpty;
    final timeText = '${_clock(p.startMin)} – ${_clock(p.endMin)}';
    final muted = colors.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent ? BorderSide(color: colors.primary, width: 3) : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => _editClass(p),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(
          isPast ? Icons.check_circle : (isCurrent ? Icons.play_circle_fill : Icons.circle_outlined),
          size: 34,
          color: isCurrent ? colors.primary : (isPast ? muted : colors.onSurface),
        ),
        title: Text(
          hasName ? info.name : p.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isPast ? muted : colors.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              hasName ? '${p.name} · $timeText' : timeText,
              hasRoom ? info.room : 'Tap to add your class and room',
            ].join('\n'),
            style: TextStyle(fontSize: 17, color: muted, height: 1.4),
          ),
        ),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('NOW', style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            : Icon(Icons.edit_outlined, color: muted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BIG STATUS CARD AT THE TOP
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.title,
    required this.big,
    this.detail,
    this.progress,
    this.footer,
  });

  final String label;
  final String title;
  final String big;
  final String? detail;
  final double? progress;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.onPrimaryContainer;

    // One clear sentence for screen readers (changes only when the minute changes).
    final spoken = [label, title, detail, big, footer].where((e) => e != null && e.isNotEmpty).join('. ');

    return Semantics(
      container: true,
      label: spoken,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textColor)),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, height: 1.15)),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 28, color: textColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(detail!, style: TextStyle(fontSize: 24, color: textColor))),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(big, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor)),
              if (progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    color: colors.primary,
                    backgroundColor: colors.surface,
                  ),
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 14),
                Text(footer!, style: TextStyle(fontSize: 18, color: textColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIALOG TO ADD A CLASS AND ROOM
// ---------------------------------------------------------------------------

class _ClassEditDialog extends StatefulWidget {
  const _ClassEditDialog({required this.periodName, this.initial});

  final String periodName;
  final ClassInfo? initial;

  @override
  State<_ClassEditDialog> createState() => _ClassEditDialogState();
}

class _ClassEditDialogState extends State<_ClassEditDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _room = TextEditingController(text: widget.initial?.room ?? '');

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, ClassInfo(name: _name.text.trim(), room: _room.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.periodName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Class name',
                hintText: 'Example: Algebra 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _room,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Where is it?',
                hintText: 'Example: Room 204 or Gym',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 18)),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}