import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/speech_output_service.dart';

class AppointmentsScreen extends StatefulWidget {
  final bool readOnly;

  const AppointmentsScreen({super.key, this.readOnly = false});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final FirestoreService _db = FirestoreService();
  final SpeechOutputService _speechOutput = SpeechOutputService();
  String? _elderId;
  bool _loading = true;

  Future<void> _speakAppointment(Map<String, dynamic> data) async {
    final speech = [
      'അപ്പോയിന്റ്മെന്റ്.',
      (data['doctor'] ?? 'ഡോക്ടർ').toString(),
      (data['specialization'] ?? '').toString(),
      (data['date'] ?? '').toString(),
      (data['time'] ?? '').toString(),
      (data['hospital'] ?? '').toString(),
    ].where((part) => part.isNotEmpty).join('. ');
    try {
      await _speechOutput.speak(speech);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadElderId();
  }

  Future<void> _loadElderId() async {
    final id = await _db.resolveElderId();
    if (!mounted) return;
    setState(() {
      _elderId = id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_elderId == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'No Elder account linked yet.\nConnect an Elder from the Family Dashboard first.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF203864),
        elevation: 0,
        title: Text(
          widget.readOnly ? 'My Appointments' : 'Manage Appointments',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.streamAppointments(_elderId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load appointments.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No appointments have been added yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF718096), fontSize: 16),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index];
              return _card(d.id, d.data());
            },
          );
        },
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAppointmentDialog(),
              backgroundColor: const Color(0xFF4F8EF7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Appointment'),
            ),
    );
  }

  Widget _card(String id, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF8B5CF6),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (data['doctor'] ?? 'Doctor').toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF203864),
                  ),
                ),
              ),
              if (widget.readOnly)
                IconButton(
                  tooltip: 'Hear appointment details',
                  onPressed: () => _speakAppointment(data),
                  icon: const Icon(Icons.volume_up_rounded),
                  color: const Color(0xFF4F8EF7),
                ),
              if (!widget.readOnly)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAppointmentDialog(id: id, existing: data);
                    }
                    if (value == 'delete') {
                      _delete(id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data['specialization'] ?? '').toString(),
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Text(
            (data['hospital'] ?? '').toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 19,
                color: Color(0xFF4F8EF7),
              ),
              const SizedBox(width: 7),
              Text(
                '${data['date'] ?? 'Date not set'}  •  ${data['time'] ?? 'Time not set'}',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text(
          'This appointment will be removed from the Elder\'s care plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await _db.deleteAppointment(elderId: _elderId!, appointmentId: id);
    }
  }

  Future<void> _showAppointmentDialog({
    String? id,
    Map<String, dynamic>? existing,
  }) async {
    final doctor = TextEditingController(
      text: (existing?['doctor'] ?? '').toString(),
    );
    final specialization = TextEditingController(
      text: (existing?['specialization'] ?? '').toString(),
    );
    final hospital = TextEditingController(
      text: (existing?['hospital'] ?? '').toString(),
    );
    DateTime date =
        _parseDate((existing?['date'] ?? '').toString()) ?? DateTime.now();
    TimeOfDay time =
        _parseTime((existing?['time'] ?? '').toString()) ??
        const TimeOfDay(hour: 10, minute: 0);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(id == null ? 'Add Appointment' : 'Edit Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: doctor,
                      decoration: const InputDecoration(
                        labelText: 'Doctor name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specialization,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hospital,
                      decoration: const InputDecoration(
                        labelText: 'Hospital',
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: const Text('Date'),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => date = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(time.format(dialogContext)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: time,
                        );
                        if (picked != null) {
                          setDialogState(() => time = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (doctor.text.trim().isEmpty) return;
                    final data = <String, String>{
                      'doctor': doctor.text.trim(),
                      'specialization': specialization.text.trim(),
                      'hospital': hospital.text.trim(),
                      'date': '${date.day}/${date.month}/${date.year}',
                      'time': time.format(dialogContext),
                    };
                    Navigator.pop(dialogContext);
                    if (id == null) {
                      await _db.addAppointment(
                        elderId: _elderId!,
                        doctor: data['doctor']!,
                        specialization: data['specialization']!,
                        hospital: data['hospital']!,
                        date: data['date']!,
                        time: data['time']!,
                      );
                    } else {
                      await _db.updateAppointment(
                        elderId: _elderId!,
                        appointmentId: id,
                        data: data,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(id == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    doctor.dispose();
    specialization.dispose();
    hospital.dispose();
  }

  DateTime? _parseDate(String value) {
    final p = value.split('/');
    if (p.length != 3) return null;
    return DateTime.tryParse(
      '${p[2].padLeft(4, '0')}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}',
    );
  }

  TimeOfDay? _parseTime(String value) {
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (m == null) return null;
    var h = int.tryParse(m.group(1)!) ?? 10;
    final min = int.tryParse(m.group(2)!) ?? 0;
    final ap = (m.group(3) ?? '').toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: min);
  }
}
