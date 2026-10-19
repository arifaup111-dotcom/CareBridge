// lib/screens/family_medicines_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'family_common.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class FamilyMedicinesTab extends StatefulWidget {
  const FamilyMedicinesTab({super.key, required this.elderUid});

  final String elderUid;

  @override
  State<FamilyMedicinesTab> createState() => _FamilyMedicinesTabState();
}

class _FamilyMedicinesTabState extends State<FamilyMedicinesTab> {
  final FirestoreService _db = FirestoreService();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Nudges the Elder's phone to re-read medicines and reschedule alarms.
  Future<void> _syncElderAlarms() async {
    try {
      await _db.touchCareSync(widget.elderUid);
    } catch (_) {
      // Not critical: the Elder's phone also refreshes when the app opens.
    }
  }

  Future<void> _openForm({_Doc? doc}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _MedicineFormDialog(existing: doc?.data()),
    );
    if (result == null) return;

    try {
      if (doc == null) {
        await _db.addMedicine(
          elderId: widget.elderUid,
          name: result['name']!,
          dosage: result['dosage']!,
          time: result['time']!,
          instruction: result['instruction']!,
        );
      } else {
        await _db.updateMedicine(
          elderId: widget.elderUid,
          medicineId: doc.id,
          data: {
            'name': result['name'],
            'dosage': result['dosage'],
            'time': result['time'],
            'instruction': result['instruction'],
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      await _syncElderAlarms();
      _snack(doc == null ? 'Medicine added.' : 'Medicine updated.');
    } catch (_) {
      _snack(
        'Could not save the medicine. Check your connection and try again.',
      );
    }
  }

  Future<void> _confirmDelete(_Doc doc) async {
    final name = (doc.data()['name'] ?? 'this medicine').toString();
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove $name from the Elder\'s medicine list?'),
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
      await _db.deleteMedicine(elderId: widget.elderUid, medicineId: doc.id);
      await _syncElderAlarms();
      _snack('Medicine deleted.');
    } catch (_) {
      _snack('Could not delete the medicine.');
    }
  }

  Future<void> _setTaken(_Doc doc, bool taken) async {
    try {
      await _db.markMedicineTaken(
        elderId: widget.elderUid,
        medicineId: doc.id,
        taken: taken,
      );
    } catch (_) {
      _snack('Could not update the medicine status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFamilyBg,
      appBar: familyAppBar(context, 'Medicines'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kFamilyBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.streamMedicines(widget.elderUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load medicines.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sort by the actual time of day (the stored text would sort
          // "10:00 AM" before "8:00 AM").
          final docs = snapshot.data!.docs.toList()
            ..sort(
              (a, b) => timeSortKey(
                (a.data()['time'] ?? '').toString(),
              ).compareTo(timeSortKey((b.data()['time'] ?? '').toString())),
            );

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No medicines yet.\nTap "Add medicine" to add the first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kFamilyMuted,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }

          final takenCount = docs
              .where((d) => FirestoreService.isMedicineTakenToday(d.data()))
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _SummaryCard(taken: takenCount, total: docs.length),
              const SizedBox(height: 14),
              for (final doc in docs)
                _MedicineCard(
                  data: doc.data(),
                  onToggle: (v) => _setTaken(doc, v),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.taken, required this.total});

  final int taken;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : taken / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$taken of $total medicines marked as taken',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kFamilyNavy,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5EDFB),
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.data,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final dosage = (data['dosage'] ?? '').toString();
    final time = (data['time'] ?? '').toString();
    final instruction = (data['instruction'] ?? '').toString();
    final taken = FirestoreService.isMedicineTakenToday(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF2FF),
                child: Icon(Icons.medication, color: kFamilyBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Medicine' : name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kFamilyNavy,
                      ),
                    ),
                    if (dosage.isNotEmpty)
                      Text(dosage, style: const TextStyle(color: kFamilyMuted)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: kFamilyMuted),
              const SizedBox(width: 6),
              Text(
                time.isEmpty ? 'No time set' : time,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                taken ? 'Taken' : 'Not taken yet',
                style: TextStyle(
                  color: taken ? const Color(0xFF10B981) : kFamilyMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(value: taken, onChanged: onToggle),
            ],
          ),
          if (instruction.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Text(
                instruction,
                style: const TextStyle(color: kFamilyMuted, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Add / edit form. Owns its own controllers so they are disposed safely.
class _MedicineFormDialog extends StatefulWidget {
  const _MedicineFormDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<_MedicineFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _instruction;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: (e?['name'] ?? '').toString());
    _dosage = TextEditingController(text: (e?['dosage'] ?? '').toString());
    _instruction = TextEditingController(
      text: (e?['instruction'] ?? 'Take as prescribed').toString(),
    );
    _time =
        parseTime((e?['time'] ?? '').toString()) ??
        const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter the medicine name.');
      return;
    }
    final instruction = _instruction.text.trim();
    Navigator.pop(context, <String, String>{
      'name': name,
      'dosage': _dosage.text.trim(),
      'time': formatTime12h(_time),
      'instruction': instruction.isEmpty ? 'Take as prescribed' : instruction,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add medicine' : 'Edit medicine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Medicine name'),
            ),
            TextField(
              controller: _dosage,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 1 tablet, 5 ml',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(formatTime12h(_time)),
              onTap: _pickTime,
            ),
            TextField(
              controller: _instruction,
              decoration: const InputDecoration(labelText: 'Instruction'),
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
