import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/speech_output_service.dart';

class MedicinesScreen extends StatefulWidget {
  /// When true, this screen only displays the care plan.
  final bool readOnly;

  const MedicinesScreen({super.key, this.readOnly = false});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final FirestoreService _db = FirestoreService();
  final SpeechOutputService _speechOutput = SpeechOutputService();

  String? _elderId;
  bool _loading = true;

  Future<void> _speakMedicine({
    required String name,
    required String dosage,
    required String time,
    required String instruction,
  }) async {
    try {
      await _speechOutput.speak(
        'മരുന്ന്: $name. അളവ്: $dosage. സമയം: $time. $instruction.',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update medicine status: $error')),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.readOnly ? "My Medicines" : "Manage Medicine",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF203864),
          ),
        ),
        centerTitle: false,
      ),

      body: _buildBody(),

      floatingActionButton: (_elderId == null || widget.readOnly)
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddMedicineDialog,
              backgroundColor: const Color(0xFF4F8EF7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add Medicine"),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_elderId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            "No elder account linked yet.\nAsk the admin to link your account.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamMedicines(_elderId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Could not load medicines."));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Medicines",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 14),

              if (docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 46,
                        color: Color(0xFFB0BEC5),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No medicines added yet.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...docs.map((doc) {
                  final m = doc.data();
                  final taken = FirestoreService.isMedicineTakenToday(m);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _medicineCard(
                      medicineId: doc.id,
                      medicineName: (m['name'] ?? '').toString(),
                      dosage: (m['dosage'] ?? '').toString(),
                      time: (m['time'] ?? '').toString(),
                      instruction: (m['instruction'] ?? '').toString(),
                      taken: taken,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // MEDICINE CARD
  // ===============================================================

  Widget _medicineCard({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required String time,
    required String instruction,
    required bool taken,
  }) {
    final Color accent = taken
        ? const Color(0xFF10B981)
        : const Color(0xFF4F8EF7);
    final Color soft = taken
        ? const Color(0xFFE6F7F1)
        : const Color(0xFFEAF4FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.medication_rounded, color: accent, size: 30),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medicineName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF243B53),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hear medicine details',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _speakMedicine(
                        name: medicineName,
                        dosage: dosage,
                        time: time,
                        instruction: instruction,
                      ),
                      icon: const Icon(Icons.volume_up_rounded),
                      color: const Color(0xFF4F8EF7),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  dosage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),

              const SizedBox(height: 7),

              if (taken)
                InkWell(
                  onTap: () => _toggleMedicineTaken(medicineId, false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "കഴിച്ചു (Taken)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _toggleMedicineTaken(medicineId, true),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text(
                    "കഴിച്ചു",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: const Size(64, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              // Family can edit or remove medicines from the care plan.
              if (!widget.readOnly) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showEditMedicineDialog(
                        medicineId: medicineId,
                        name: medicineName,
                        dosage: dosage,
                        timeText: time,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xFF4F8EF7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _confirmDelete(medicineId, medicineName),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // DELETE
  // ===============================================================

  void _confirmDelete(String medicineId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Remove medicine"),
        content: Text("Remove $name from the list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _db.deleteMedicine(
                elderId: _elderId!,
                medicineId: medicineId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // ADD MEDICINE DIALOG
  // ===============================================================

  void _showAddMedicineDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              title: const Text(
                "Add Medicine",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: medicineController,
                    decoration: InputDecoration(
                      labelText: "Medicine name",
                      prefixIcon: const Icon(Icons.medication_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: "Dosage",
                      prefixIcon: const Icon(Icons.science_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Time",
                        prefixIcon: const Icon(Icons.access_time_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(selectedTime.format(dialogContext)),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = medicineController.text.trim();
                    final dosage = dosageController.text.trim();

                    if (name.isEmpty || dosage.isEmpty) return;

                    final formattedTime = selectedTime.format(dialogContext);
                    Navigator.pop(dialogContext);

                    await _db.addMedicine(
                      elderId: _elderId!,
                      name: name,
                      dosage: dosage,
                      time: formattedTime,
                    );

                    if (!mounted) return;

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Medicine added successfully."),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===============================================================
  // EDIT MEDICINE
  // ===============================================================

  void _showEditMedicineDialog({
    required String medicineId,
    required String name,
    required String dosage,
    required String timeText,
  }) {
    final medicineController = TextEditingController(text: name);
    final dosageController = TextEditingController(text: dosage);
    TimeOfDay selectedTime =
        _parseTime(timeText) ?? const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Edit Medicine',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: medicineController,
                    decoration: InputDecoration(
                      labelText: 'Medicine name',
                      prefixIcon: const Icon(Icons.medication_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      prefixIcon: const Icon(Icons.science_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        prefixIcon: const Icon(Icons.access_time_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(selectedTime.format(dialogContext)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = medicineController.text.trim();
                    final newDosage = dosageController.text.trim();
                    if (newName.isEmpty || newDosage.isEmpty) return;
                    Navigator.pop(dialogContext);
                    await _db.updateMedicine(
                      elderId: _elderId!,
                      medicineId: medicineId,
                      data: {
                        'name': newName,
                        'dosage': newDosage,
                        'time': selectedTime.format(context),
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 8;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final period = (match.group(3) ?? '').toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }
}
