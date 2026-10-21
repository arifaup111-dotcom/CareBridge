// lib/screens/family_health_tab.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';
import 'care_reminder_settings_screen.dart';
import 'family_common.dart';

class FamilyHealthTab extends StatefulWidget {
  const FamilyHealthTab({super.key, required this.elderUid});

  final String elderUid;

  @override
  State<FamilyHealthTab> createState() => _FamilyHealthTabState();
}

class _FamilyHealthTabState extends State<FamilyHealthTab> {
  final FirestoreService _db = FirestoreService();
  final Stream<DateTime> _locationClock = Stream<DateTime>.periodic(
    const Duration(seconds: 10),
    (_) => DateTime.now(),
  ).asBroadcastStream();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _recordReadings() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _ReadingFormDialog(),
    );
    if (result == null) return;
    try {
      await _db.addHealthReading(
        elderId: widget.elderUid,
        heartRate: result['heartRate'],
        bloodPressure: result['bloodPressure'],
        temperature: result['temperature'],
        status: result['status'],
      );
      _snack('Health readings saved.');
    } catch (_) {
      _snack(
        'Could not save the readings. Check your connection and try again.',
      );
    }
  }

  Future<void> _recordConsultation() async {
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => const _ConsultationFormDialog(),
    );
    if (result == null) return;

    try {
      await _db.addHealthConsultation(
        elderId: widget.elderUid,
        doctorName: result['doctorName']! as String,
        consultationDate: result['consultationDate']! as DateTime,
        diagnosis: result['diagnosis']! as String,
        status: result['status']! as String,
        heartRate: result['heartRate'] as String?,
        bloodPressure: result['bloodPressure'] as String?,
        temperature: result['temperature'] as String?,
      );
      _snack('Doctor consultation saved.');
    } catch (error) {
      _snack('Could not save the consultation: $error');
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('Could not open Maps.');
    } catch (_) {
      _snack('Could not open Maps.');
    }
  }

  /// First non-empty value among [keys], else "Not available".
  String _pick(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    List<String> keys,
  ) {
    for (final source in [a, b]) {
      for (final key in keys) {
        final value = source[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFamilyBg,
      appBar: familyAppBar(context, 'Health Status'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordReadings,
        backgroundColor: kFamilyBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.monitor_heart),
        label: const Text('Record readings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _elderHeader(),
          const SizedBox(height: 14),
          _emergencyAlert(),
          _doctorConsultation(),
          const SizedBox(height: 14),
          _vitals(),
          const SizedBox(height: 6),
          _medicineSummary(),
          const SizedBox(height: 14),
          _careReminderSummary(),
        ],
      ),
    );
  }

  // ---------- Doctor consultation ----------
  Widget _doctorConsultation() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamLatestHealthConsultation(widget.elderUid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final consultation = docs.isEmpty ? null : docs.first.data();
        final consultationDate =
            (consultation?['consultationDate'] as Timestamp?)?.toDate();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Doctor's consultation",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kFamilyNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Record doctor consultation',
                    onPressed: _recordConsultation,
                    icon: const Icon(Icons.add_circle, color: kFamilyBlue),
                  ),
                ],
              ),
              if (snapshot.hasError)
                const Text(
                  'Could not load consultation history.',
                  style: TextStyle(color: Colors.redAccent),
                )
              else if (!snapshot.hasData)
                const LinearProgressIndicator()
              else if (consultation == null)
                const Text(
                  "No doctor consultation recorded yet. Add the doctor's advice after a visit.",
                  style: TextStyle(color: kFamilyMuted, height: 1.4),
                )
              else ...[
                Text(
                  '${consultation['doctorName'] ?? 'Doctor'}'
                  '${consultationDate == null ? '' : ' • ${DateFormat('d MMM yyyy').format(consultationDate)}'}',
                  style: const TextStyle(
                    color: kFamilyMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _consultationValue(
                  'Overall status',
                  (consultation['status'] ?? 'Not recorded').toString(),
                ),
                _consultationValue(
                  "Doctor's notes",
                  (consultation['diagnosis'] ?? 'Not recorded').toString(),
                ),
                if (consultation['heartRate'] != null)
                  _consultationValue(
                    'Heart rate',
                    consultation['heartRate'].toString(),
                  ),
                if (consultation['bloodPressure'] != null)
                  _consultationValue(
                    'Blood pressure',
                    consultation['bloodPressure'].toString(),
                  ),
                if (consultation['temperature'] != null)
                  _consultationValue(
                    'Temperature',
                    consultation['temperature'].toString(),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Recorded by Family based on the doctor consultation.',
                  style: TextStyle(color: kFamilyMuted, fontSize: 12),
                ),
              ],
              if (snapshot.hasData)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _recordConsultation,
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Record consultation'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _consultationValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: kFamilyMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kFamilyNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Elder header ----------
  Widget _elderHeader() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.streamElderProfile(widget.elderUid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final name = (data['name'] ?? 'Connected Elder').toString();
        final elderId = (data['elderId'] ?? '').toString();
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFEAF2FF),
                child: Icon(Icons.elderly, color: kFamilyBlue, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected Elder',
                      style: TextStyle(color: kFamilyMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: kFamilyNavy,
                      ),
                    ),
                    if (elderId.isNotEmpty)
                      Text(
                        elderId,
                        style: const TextStyle(color: kFamilyMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Latest emergency alert ----------
  Widget _emergencyAlert() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamEmergencies(widget.elderUid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final data = docs.first.data();
        final resolved = data['resolved'] == true;
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final trackingEnabled = data['locationTracking'] == true;
        final locationUpdatedAt = (data['locationUpdatedAt'] as Timestamp?)
            ?.toDate();
        final when = ts == null
            ? 'just now'
            : DateFormat('d MMM, h:mm a').format(ts);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: resolved ? Colors.white : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emergency_rounded,
                    color: resolved ? kFamilyMuted : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolved ? 'Last emergency alert' : 'Emergency alert',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: resolved ? kFamilyNavy : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Raised $when', style: const TextStyle(color: kFamilyMuted)),
              if (trackingEnabled) ...[
                const SizedBox(height: 6),
                StreamBuilder<DateTime>(
                  stream: _locationClock,
                  builder: (context, clockSnapshot) {
                    final now = clockSnapshot.data ?? DateTime.now();
                    final isFresh =
                        locationUpdatedAt != null &&
                        now.difference(locationUpdatedAt).abs().inSeconds < 30;
                    return Row(
                      children: [
                        Icon(
                          isFresh
                              ? Icons.my_location_rounded
                              : Icons.location_disabled_rounded,
                          size: 16,
                          color: isFresh ? Colors.red : kFamilyMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isFresh
                                ? 'Sharing live location'
                                : locationUpdatedAt == null
                                ? 'Waiting for the first location update'
                                : 'No recent location update; showing last known location',
                            style: TextStyle(
                              color: isFresh ? Colors.red : kFamilyMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (locationUpdatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trackingEnabled
                        ? 'Updated ${DateFormat('h:mm:ss a').format(locationUpdatedAt)}'
                        : 'Last location ${DateFormat('h:mm a').format(locationUpdatedAt)}',
                    style: const TextStyle(color: kFamilyMuted),
                  ),
                ),
              if (lat != null && lng != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openMap(lat, lng),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Open location in Maps'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------- Vitals ----------
  Widget _vitals() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.streamElderProfile(widget.elderUid),
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? <String, dynamic>{};
        final profileHealth = profile['health'] is Map
            ? Map<String, dynamic>.from(profile['health'] as Map)
            : profile;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.streamLatestHealthReading(widget.elderUid),
          builder: (context, readingSnap) {
            final docs = readingSnap.data?.docs ?? const [];
            final latest = docs.isEmpty
                ? <String, dynamic>{}
                : docs.first.data();
            final ts = (latest['timestamp'] as Timestamp?)?.toDate();

            final heart = _pick(latest, profileHealth, [
              'heartRate',
              'heart_rate',
            ]);
            final bp = _pick(latest, profileHealth, [
              'bloodPressure',
              'blood_pressure',
            ]);
            final temp = _pick(latest, profileHealth, ['temperature']);
            final status = _pick(latest, profileHealth, [
              'status',
              'healthStatus',
            ]);
            final empty = [
              heart,
              bp,
              temp,
              status,
            ].every((v) => v == 'Not available');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current health status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kFamilyNavy,
                  ),
                ),
                if (ts != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Last updated ${DateFormat('d MMM, h:mm a').format(ts)}',
                      style: const TextStyle(color: kFamilyMuted, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 12),
                _vitalCard(Icons.favorite, 'Heart rate', heart, Colors.red),
                _vitalCard(
                  Icons.monitor_heart,
                  'Blood pressure',
                  bp,
                  Colors.purple,
                ),
                _vitalCard(
                  Icons.thermostat,
                  'Temperature',
                  temp,
                  Colors.orange,
                ),
                _vitalCard(
                  Icons.health_and_safety,
                  'Overall status',
                  status,
                  Colors.green,
                ),
                if (empty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No health readings yet. Tap "Record readings" to add '
                      'the Elder\'s latest heart rate, blood pressure and '
                      'temperature.',
                      style: TextStyle(color: Color(0xFF7A5B00), height: 1.4),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _vitalCard(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kFamilyNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Medicine adherence ----------
  Widget _medicineSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamMedicines(widget.elderUid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final taken = docs
            .where((d) => FirestoreService.isMedicineTakenToday(d.data()))
            .length;
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.medication, color: kFamilyBlue, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Medicines marked as taken',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              Text(
                '$taken / ${docs.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kFamilyNavy,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _careReminderSummary() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.streamCareReminderSettings(widget.elderUid),
      builder: (context, snapshot) {
        final settings = snapshot.data?.data() ?? const <String, dynamic>{};
        final now = DateTime.now();
        final today =
            '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today’s care check-ins',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kFamilyNavy,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                const Text(
                  'Could not load meal and water check-ins.',
                  style: TextStyle(color: Colors.redAccent),
                )
              else if (!snapshot.hasData)
                const LinearProgressIndicator()
              else ...[
                _careCheckInRow(
                  settings: settings,
                  category: 'meal',
                  today: today,
                  label: 'Meal',
                  icon: Icons.restaurant_rounded,
                ),
                const SizedBox(height: 10),
                _careCheckInRow(
                  settings: settings,
                  category: 'breakfast',
                  today: today,
                  label: 'Breakfast',
                  icon: Icons.free_breakfast_rounded,
                ),
                const SizedBox(height: 10),
                _careCheckInRow(
                  settings: settings,
                  category: 'lunch',
                  today: today,
                  label: 'Lunch',
                  icon: Icons.lunch_dining_rounded,
                ),
                const SizedBox(height: 10),
                _careCheckInRow(
                  settings: settings,
                  category: 'dinner',
                  today: today,
                  label: 'Dinner',
                  icon: Icons.dinner_dining_rounded,
                ),
                const SizedBox(height: 10),
                _careCheckInRow(
                  settings: settings,
                  category: 'water',
                  today: today,
                  label: 'Water',
                  icon: Icons.water_drop_rounded,
                ),
                const SizedBox(height: 10),
                _careCheckInRow(
                  settings: settings,
                  category: 'exercise',
                  today: today,
                  label: 'Exercise',
                  icon: Icons.fitness_center_rounded,
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CareReminderSettingsScreen(elderId: widget.elderUid),
                    ),
                  ),
                  icon: const Icon(Icons.alarm_add_rounded),
                  label: const Text('Manage reminder times'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _careCheckInRow({
    required Map<String, dynamic> settings,
    required String category,
    required String today,
    required String label,
    required IconData icon,
  }) {
    final confirmed = settings['${category}ConfirmedOn'] == today;
    final timestamp = settings['${category}ConfirmedAt'];
    final time = confirmed && timestamp is Timestamp
        ? DateFormat('h:mm a').format(timestamp.toDate().toLocal())
        : null;
    return Row(
      children: [
        Icon(icon, color: confirmed ? const Color(0xFF10B981) : kFamilyMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: kFamilyNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          confirmed
              ? 'Confirmed${time == null ? '' : ' at $time'}'
              : 'Not confirmed',
          style: TextStyle(
            color: confirmed ? const Color(0xFF059669) : kFamilyMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Form for recording a new set of readings. Any field may be left empty.
class _ReadingFormDialog extends StatefulWidget {
  const _ReadingFormDialog();

  @override
  State<_ReadingFormDialog> createState() => _ReadingFormDialogState();
}

class _ReadingFormDialogState extends State<_ReadingFormDialog> {
  static const _statuses = ['Normal', 'Needs attention', 'Critical'];

  final TextEditingController _heart = TextEditingController();
  final TextEditingController _bp = TextEditingController();
  final TextEditingController _temp = TextEditingController();
  String? _status;
  String? _error;

  @override
  void dispose() {
    _heart.dispose();
    _bp.dispose();
    _temp.dispose();
    super.dispose();
  }

  void _save() {
    final heart = _heart.text.trim();
    final bp = _bp.text.trim();
    final temp = _temp.text.trim();
    if (heart.isEmpty && bp.isEmpty && temp.isEmpty && _status == null) {
      setState(() => _error = 'Enter at least one reading.');
      return;
    }
    Navigator.pop(context, <String, String>{
      'heartRate': heart,
      'bloodPressure': bp,
      'temperature': temp,
      'status': _status ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record readings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _heart,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heart rate',
                hintText: 'e.g. 72 bpm',
              ),
            ),
            TextField(
              controller: _bp,
              decoration: const InputDecoration(
                labelText: 'Blood pressure',
                hintText: 'e.g. 120/80',
              ),
            ),
            TextField(
              controller: _temp,
              decoration: const InputDecoration(
                labelText: 'Temperature',
                hintText: 'e.g. 98.6 °F',
              ),
            ),
            const SizedBox(height: 14),
            const Text('Overall status'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final s in _statuses)
                  ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    onSelected: (selected) =>
                        setState(() => _status = selected ? s : null),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ConsultationFormDialog extends StatefulWidget {
  const _ConsultationFormDialog();

  @override
  State<_ConsultationFormDialog> createState() =>
      _ConsultationFormDialogState();
}

class _ConsultationFormDialogState extends State<_ConsultationFormDialog> {
  static const _statuses = ['Stable', 'Needs attention', 'Critical'];

  final _formKey = GlobalKey<FormState>();
  final _doctor = TextEditingController();
  final _diagnosis = TextEditingController();
  final _heartRate = TextEditingController();
  final _bloodPressure = TextEditingController();
  final _temperature = TextEditingController();
  DateTime _consultationDate = DateTime.now();
  String? _status;

  @override
  void dispose() {
    _doctor.dispose();
    _diagnosis.dispose();
    _heartRate.dispose();
    _bloodPressure.dispose();
    _temperature.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _consultationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _consultationDate = date);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final status = _status;
    if (status == null) return;

    Navigator.pop(context, <String, Object?>{
      'doctorName': _doctor.text.trim(),
      'consultationDate': _consultationDate,
      'diagnosis': _diagnosis.text.trim(),
      'status': status,
      'heartRate': _heartRate.text.trim(),
      'bloodPressure': _bloodPressure.text.trim(),
      'temperature': _temperature.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Record doctor's consultation"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _doctor,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Doctor's name"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? "Enter the doctor's name."
                    : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Consultation date'),
                subtitle: Text(
                  DateFormat('d MMM yyyy').format(_consultationDate),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _chooseDate,
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Overall status'),
                items: _statuses
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (value) => value == null
                    ? 'Choose the status from the consultation.'
                    : null,
              ),
              TextFormField(
                controller: _diagnosis,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Diagnosis / doctor's notes",
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? "Enter the doctor's notes."
                    : null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _heartRate,
                decoration: const InputDecoration(
                  labelText: 'Heart rate (optional)',
                  hintText: 'e.g. 72 bpm',
                ),
              ),
              TextField(
                controller: _bloodPressure,
                decoration: const InputDecoration(
                  labelText: 'Blood pressure (optional)',
                  hintText: 'e.g. 120/80',
                ),
              ),
              TextField(
                controller: _temperature,
                decoration: const InputDecoration(
                  labelText: 'Temperature (optional)',
                  hintText: 'e.g. 37 °C',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save consultation')),
      ],
    );
  }
}
