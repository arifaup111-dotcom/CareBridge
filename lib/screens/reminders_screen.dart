import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/care_alarm_service.dart';
import '../services/firestore_service.dart';
import '../services/speech_output_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FirestoreService _db = FirestoreService();
  final SpeechOutputService _speechOutput = SpeechOutputService();
  String? _elderId;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadElderId();
  }

  Future<void> _loadElderId() async {
    try {
      final elderId = await _db.resolveElderId();
      if (!mounted) return;
      setState(() {
        _elderId = elderId;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _toggleMedicineTaken(String medicineId, bool taken) async {
    if (_elderId == null) return;
    try {
      await _db.markMedicineTaken(
        elderId: _elderId!,
        medicineId: medicineId,
        taken: taken,
      );
      if (taken) {
        _speechOutput
            .speak('മരുന്ന് കഴിച്ചതായി അടയാളപ്പെടുത്തി.')
            .catchError((_) {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update medicine status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF243B53)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Reminders & Schedule",
          style: TextStyle(
            color: Color(0xFF243B53),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return const Center(child: Text('Could not load your care schedule.'));
    }
    if (_elderId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No Elder is connected to this account yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamMedicines(_elderId!),
      builder: (context, medicineSnapshot) {
        if (medicineSnapshot.hasError) {
          return const Center(
            child: Text('Could not load medicine schedules.'),
          );
        }
        if (!medicineSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.streamAppointments(_elderId!),
          builder: (context, appointmentSnapshot) {
            if (appointmentSnapshot.hasError) {
              return const Center(
                child: Text('Could not load appointment schedules.'),
              );
            }
            if (!appointmentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.streamCareReminderSettings(_elderId!),
              builder: (context, careReminderSnapshot) {
                if (careReminderSnapshot.hasError) {
                  return const Center(
                    child: Text('Could not load meal and water alarms.'),
                  );
                }
                if (!careReminderSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Sync alarms in background
                final medicineDocs = medicineSnapshot.data!.docs;
                final appointmentDocs = appointmentSnapshot.data!.docs;
                final careReminders = careReminderSnapshot.data!.data() ?? {};

                unawaited(
                  _syncAlarms(medicineDocs, appointmentDocs, careReminders),
                );

                return _buildSchedule(
                  medicineDocs,
                  appointmentDocs,
                  careReminders,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _syncAlarms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> medicines,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
    Map<String, dynamic> careReminders,
  ) async {
    try {
      final medList = medicines.map((d) => {'id': d.id, ...d.data()}).toList();
      await CareAlarmService.instance.scheduleMedicineReminders(
        medicines: medList,
      );
      await CareAlarmService.instance.scheduleDailyReminders(
        mealTimes: _stringList(careReminders['mealTimes']),
        waterTimes: _stringList(careReminders['waterTimes']),
        wakeUpTime: (careReminders['wakeUpTime'] ?? '7:00 AM').toString(),
        exerciseTime: (careReminders['exerciseTime'] ?? '8:00 AM').toString(),
      );

      final apptList = appointments
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      await CareAlarmService.instance.scheduleAppointmentReminders(
        appointments: apptList,
      );
    } catch (e) {
      debugPrint('Alarm sync error in reminders screen: $e');
    }
  }

  Widget _buildSchedule(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> medicines,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
    Map<String, dynamic> careReminders,
  ) {
    final mealTimes = _stringList(careReminders['mealTimes']);
    final waterTimes = _stringList(careReminders['waterTimes']);
    final wakeUpTime = (careReminders['wakeUpTime'] ?? '7:00 AM').toString();
    final exerciseTime = (careReminders['exerciseTime'] ?? '8:00 AM')
        .toString();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Medicine Schedule (മരുന്നുകൾ)'),
        if (medicines.isEmpty)
          _emptySection('No medicines are scheduled.')
        else
          ...medicines.map((document) {
            final data = document.data();
            final taken = FirestoreService.isMedicineTakenToday(data);
            final medName = (data['name'] ?? 'Medicine').toString();
            final dosage = (data['dosage'] ?? '').toString();
            final instruction = (data['instruction'] ?? '').toString();
            final time = (data['time'] ?? 'Time not set').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReminderCard(
                icon: Icons.medication_rounded,
                title: medName,
                subtitle: [
                  dosage,
                  instruction,
                ].where((value) => value.isNotEmpty).join(' · '),
                time: time,
                iconColor: taken
                    ? const Color(0xFF10B981)
                    : const Color(0xFF4F8EF7),
                taken: taken,
                onToggleTaken: () => _toggleMedicineTaken(document.id, !taken),
                onSpeak: () => _speakReminder(
                  'മരുന്ന്: $medName. അളവ്: $dosage. സമയം: $time. $instruction.',
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
        _sectionTitle('Doctor Appointments (അപ്പോയിന്റ്മെന്റുകൾ)'),
        if (appointments.isEmpty)
          _emptySection('No appointments are scheduled.')
        else
          ...appointments.map((document) {
            final data = document.data();
            final doctor = (data['doctor'] ?? 'Doctor appointment').toString();
            final hospital = (data['hospital'] ?? '').toString();
            final date = (data['date'] ?? 'Date not set').toString();
            final time = (data['time'] ?? 'Time not set').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReminderCard(
                icon: Icons.calendar_month_rounded,
                title: doctor,
                subtitle: hospital,
                time: '$date · $time',
                iconColor: const Color(0xFF7A5AF8),
                onSpeak: () => _speakReminder(
                  'അപ്പോയിന്റ്മെന്റ്: $doctor. ആശുപത്രി: $hospital. തീയതി: $date, സമയം: $time.',
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
        _sectionTitle('Meal Alarms (ഭക്ഷണ സമയം)'),
        _buildTimeReminders(
          times: mealTimes,
          label: 'Meal time',
          malayalamLabel: 'ഭക്ഷണം കഴിക്കാനുള്ള സമയമായി.',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFE6A21A),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Water Alarms (കുടിവെള്ള സമയം)'),
        _buildTimeReminders(
          times: waterTimes,
          label: 'Water time',
          malayalamLabel: 'വെള്ളം കുടിക്കാനുള്ള സമയമായി. ദാഹം മാറ്റൂ.',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Morning Wake-up (രാവിലെ എഴുന്നേൽക്കാം)'),
        _buildTimeReminders(
          times: [wakeUpTime],
          label: 'Wake-up time',
          malayalamLabel:
              'സുപ്രഭാതം. എഴുന്നേൽക്കാനുള്ള സമയമായി. പുതിയ ദിവസം സന്തോഷത്തോടെ ആരംഭിക്കാം.',
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFFE6A21A),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Exercise (വ്യായാമം)'),
        _buildTimeReminders(
          times: [exerciseTime],
          label: 'Exercise time',
          malayalamLabel:
              'വ്യായാമം ചെയ്യാനുള്ള സമയമായി. ആരോഗ്യത്തിന് അനുയോജ്യമായ ലഘുവ്യായാമം ചെയ്യൂ.',
          icon: Icons.fitness_center_rounded,
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  List<String> _stringList(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : [];

  Widget _buildTimeReminders({
    required List<String> times,
    required String label,
    required String malayalamLabel,
    required IconData icon,
    required Color color,
  }) {
    if (times.isEmpty) return _emptySection('No times have been set.');
    return Column(
      children: times
          .map(
            (time) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildReminderCard(
                icon: icon,
                title: label,
                subtitle: time,
                time: '',
                iconColor: color,
                onSpeak: () => _speakReminder('$malayalamLabel $time.'),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _speakReminder(String text) async {
    try {
      await _speechOutput.speak(text);
    } catch (error) {
      debugPrint('Could not speak care reminder: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF243B53),
      ),
    ),
  );

  Widget _emptySection(String message) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(message, style: const TextStyle(color: Color(0xFF718096))),
  );

  // ==========================================================
  // REMINDER CARD
  // ==========================================================

  Widget _buildReminderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
    VoidCallback? onSpeak,
    bool taken = false,
    VoidCallback? onToggleTaken,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(icon, color: iconColor, size: 27),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243B53),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (time.isNotEmpty)
                Text(
                  time,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),

              const SizedBox(height: 6),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSpeak != null)
                    IconButton(
                      tooltip: 'Hear reminder',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up_rounded),
                      color: iconColor,
                    ),

                  if (onToggleTaken != null) ...[
                    const SizedBox(width: 4),
                    if (taken)
                      InkWell(
                        onTap: onToggleTaken,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "കഴിച്ചു",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: onToggleTaken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          minimumSize: const Size(56, 28),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "കഴിച്ചു",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
