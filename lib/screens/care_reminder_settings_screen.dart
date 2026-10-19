import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class CareReminderSettingsScreen extends StatefulWidget {
  const CareReminderSettingsScreen({super.key, required this.elderId});

  final String elderId;

  @override
  State<CareReminderSettingsScreen> createState() =>
      _CareReminderSettingsScreenState();
}

class _CareReminderSettingsScreenState
    extends State<CareReminderSettingsScreen> {
  final FirestoreService _db = FirestoreService();
  List<TimeOfDay> _mealTimes = [];
  List<TimeOfDay> _waterTimes = [];
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _exerciseTime = const TimeOfDay(hour: 8, minute: 0);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await _db.getCareReminderSettings(widget.elderId);
      if (!mounted) return;
      setState(() {
        _mealTimes = _parseTimes(data?['mealTimes']);
        _waterTimes = _parseTimes(data?['waterTimes']);
        _wakeUpTime =
            _parseTime((data?['wakeUpTime'] ?? '7:00 AM').toString()) ??
            const TimeOfDay(hour: 7, minute: 0);
        _exerciseTime =
            _parseTime((data?['exerciseTime'] ?? '8:00 AM').toString()) ??
            const TimeOfDay(hour: 8, minute: 0);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load meal and water reminder times.';
        _loading = false;
      });
    }
  }

  List<TimeOfDay> _parseTimes(dynamic value) {
    if (value == null) return [];
    if (value is! List) {
      throw const FormatException('Reminder times must be a list.');
    }
    final parsed = <TimeOfDay>[];
    for (final item in value) {
      final time = _parseTime(item.toString());
      if (time == null) {
        throw FormatException('Invalid reminder time: $item');
      }
      parsed.add(time);
    }
    parsed.sort(_compareTimes);
    return parsed;
  }

  TimeOfDay? _parseTime(String raw) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final suffix = (match.group(3) ?? '').toUpperCase();
    if (minute > 59 || hour > 12 || hour == 0) return null;
    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _compareTimes(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);

  Future<void> _addTime(List<TimeOfDay> times) async {
    if (times.length >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A maximum of 50 daily alarms can be set per type.'),
        ),
      );
      return;
    }
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected == null || !mounted) return;
    if (times.any(
      (time) => time.hour == selected.hour && time.minute == selected.minute,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That reminder time is already set.')),
      );
      return;
    }
    setState(() {
      times.add(selected);
      times.sort(_compareTimes);
    });
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) =>
      showTimePicker(context: context, initialTime: initialTime);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _db.saveCareReminderSettings(
        elderId: widget.elderId,
        mealTimes: _mealTimes.map((time) => time.format(context)).toList(),
        waterTimes: _waterTimes.map((time) => time.format(context)).toList(),
        wakeUpTime: _wakeUpTime.format(context),
        exerciseTime: _exerciseTime.format(context),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily reminders saved.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save reminder times. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Meal and Water Alarms'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF203864),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _mealTimes.isEmpty && _waterTimes.isEmpty
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Set daily meal, water, wake-up, and exercise reminders. '
                  'The Elder and linked Family members can update these schedules.',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                ),
                const SizedBox(height: 20),
                _timeSection(
                  title: 'Meal reminders',
                  icon: Icons.restaurant_rounded,
                  times: _mealTimes,
                ),
                const SizedBox(height: 18),
                _timeSection(
                  title: 'Water reminders',
                  icon: Icons.water_drop_rounded,
                  times: _waterTimes,
                ),
                const SizedBox(height: 18),
                _dailyAlarmTile(
                  title: 'Morning wake-up',
                  subtitle: 'സുപ്രഭാതം. എഴുന്നേൽക്കാനുള്ള സമയമായി.',
                  icon: Icons.wb_sunny_rounded,
                  time: _wakeUpTime,
                  onTap: () async {
                    final selected = await _pickTime(_wakeUpTime);
                    if (selected != null && mounted) {
                      setState(() => _wakeUpTime = selected);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _dailyAlarmTile(
                  title: 'Exercise reminder',
                  subtitle: 'വ്യായാമം ചെയ്യാനുള്ള സമയമായി.',
                  icon: Icons.fitness_center_rounded,
                  time: _exerciseTime,
                  onTap: () async {
                    final selected = await _pickTime(_exerciseTime);
                    if (selected != null && mounted) {
                      setState(() => _exerciseTime = selected);
                    }
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save reminders'),
                ),
              ],
            ),
    );
  }

  Widget _dailyAlarmTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4F8EF7)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(time.format(context)),
        onTap: _saving ? null : onTap,
      ),
    );
  }

  Widget _timeSection({
    required String title,
    required IconData icon,
    required List<TimeOfDay> times,
  }) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4F8EF7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add time',
                  onPressed: _saving ? null : () => _addTime(times),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            if (times.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No times set yet.'),
              )
            else
              ...times.map(
                (time) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_rounded),
                  title: Text(time.format(context)),
                  trailing: IconButton(
                    tooltip: 'Remove time',
                    onPressed: _saving
                        ? null
                        : () => setState(() => times.remove(time)),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
