// lib/screens/family_appointments_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'family_common.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class FamilyAppointmentsTab extends StatefulWidget {
  const FamilyAppointmentsTab({super.key, required this.elderUid});

  final String elderUid;

  @override
  State<FamilyAppointmentsTab> createState() => _FamilyAppointmentsTabState();
}

class _FamilyAppointmentsTabState extends State<FamilyAppointmentsTab> {
  final FirestoreService _db = FirestoreService();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Nudges the Elder's phone to re-read appointments and reschedule alarms.
  Future<void> _syncElderAlarms() async {
    try {
      await _db.touchCareSync(widget.elderUid);
    } catch (_) {
      // Not critical: the Elder's phone also refreshes when the app opens.
    }
  }

  DateTime _when(Map<String, dynamic> data) {
    final date = parseDate((data['date'] ?? '').toString());
    if (date == null) return DateTime(9999);
    final t = parseTime((data['time'] ?? '').toString());
    return DateTime(date.year, date.month, date.day, t?.hour ?? 0, t?.minute ?? 0);
  }

  Future<void> _openForm({_Doc? doc}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AppointmentFormDialog(existing: doc?.data()),
    );
    if (result == null) return;

    try {
      if (doc == null) {
        await _db.addAppointment(
          elderId: widget.elderUid,
          doctor: result['doctor']!,
          specialization: result['specialization']!,
          hospital: result['hospital']!,
          date: result['date']!,
          time: result['time']!,
        );
      } else {
        await _db.updateAppointment(
          elderId: widget.elderUid,
          appointmentId: doc.id,
          data: {
            'doctor': result['doctor'],
            'specialization': result['specialization'],
            'hospital': result['hospital'],
            'date': result['date'],
            'time': result['time'],
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      await _syncElderAlarms();
      _snack(doc == null ? 'Appointment added.' : 'Appointment updated.');
    } catch (_) {
      _snack('Could not save the appointment. Check your connection and try again.');
    }
  }

  Future<void> _confirmDelete(_Doc doc) async {
    final doctor = (doc.data()['doctor'] ?? 'this appointment').toString();
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: Text('Remove the appointment with $doctor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await _db.deleteAppointment(
        elderId: widget.elderUid,
        appointmentId: doc.id,
      );
      await _syncElderAlarms();
      _snack('Appointment deleted.');
    } catch (_) {
      _snack('Could not delete the appointment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFamilyBg,
      appBar: familyAppBar(context, 'Appointments'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kFamilyBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add appointment'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.streamAppointments(widget.elderUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load appointments.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) => _when(a.data()).compareTo(_when(b.data())));

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No appointments yet.\nTap "Add appointment" to schedule one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kFamilyMuted, fontSize: 16, height: 1.4),
                ),
              ),
            );
          }

          final now = DateTime.now();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final doc in docs)
                _AppointmentCard(
                  data: doc.data(),
                  isPast: _when(doc.data()).isBefore(now),
                  onEdit: () => _openForm(doc: doc),
                  onDelete: () => _confirmDelete(doc),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.data,
    required this.isPast,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final bool isPast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final doctor = (data['doctor'] ?? '').toString();
    final specialization = (data['specialization'] ?? '').toString();
    final hospital = (data['hospital'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final time = (data['time'] ?? '').toString();
    final subtitle = [
      if (specialization.isNotEmpty) specialization,
      if (hospital.isNotEmpty) hospital,
    ].join(' • ');

    return Opacity(
      opacity: isPast ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.local_hospital, color: kFamilyBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.isEmpty ? 'Appointment' : doctor,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kFamilyNavy,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(color: kFamilyMuted),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: kFamilyMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${date.isEmpty ? 'Date not set' : date}  •  '
                        '${time.isEmpty ? 'Time not set' : time}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Past',
                          style: TextStyle(color: kFamilyMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit form. Owns its own controllers so they are disposed safely.
class _AppointmentFormDialog extends StatefulWidget {
  const _AppointmentFormDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<_AppointmentFormDialog> {
  late final TextEditingController _doctor;
  late final TextEditingController _specialization;
  late final TextEditingController _hospital;
  late DateTime _date;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _doctor = TextEditingController(text: (e?['doctor'] ?? '').toString());
    _specialization =
        TextEditingController(text: (e?['specialization'] ?? '').toString());
    _hospital = TextEditingController(text: (e?['hospital'] ?? '').toString());
    _date = parseDate((e?['date'] ?? '').toString()) ?? DateTime.now();
    _time = parseTime((e?['time'] ?? '').toString()) ??
        const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _doctor.dispose();
    _specialization.dispose();
    _hospital.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Allow keeping an existing past date when editing.
    final first = _date.isBefore(today) ? _date : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final doctor = _doctor.text.trim();
    if (doctor.isEmpty) {
      setState(() => _error = 'Please enter the doctor\'s name.');
      return;
    }
    Navigator.pop(context, <String, String>{
      'doctor': doctor,
      'specialization': _specialization.text.trim(),
      'hospital': _hospital.text.trim(),
      'date': formatDate(_date),
      'time': formatTime12h(_time),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add appointment' : 'Edit appointment',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _doctor,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Doctor'),
            ),
            TextField(
              controller: _specialization,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                hintText: 'e.g. Cardiologist',
              ),
            ),
            TextField(
              controller: _hospital,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Hospital / clinic'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Date'),
              subtitle: Text(formatDate(_date)),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(formatTime12h(_time)),
              onTap: _pickTime,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
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
