import 'package:flutter/material.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final List<Map<String, String>> medicines = [
    {
      "name": "Paracetamol",
      "dosage": "500 mg",
      "time": "8:00 PM",
      "instruction": "Take after food",
    },
    {
      "name": "Vitamin D",
      "dosage": "1000 IU",
      "time": "9:00 PM",
      "instruction": "Take with water",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Medicines",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF203864),
          ),
        ),
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // TODAY'S MEDICINE
            // -------------------------------------------------------
            const Text(
              "Today's Medicines",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 14),

            ...medicines.map(
              (medicine) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _medicineCard(
                  medicineName: medicine["name"]!,
                  dosage: medicine["dosage"]!,
                  time: medicine["time"]!,
                  instruction: medicine["instruction"]!,
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF4F8EF7),
                  backgroundColor: const Color(0xFFEAF4FF),
                  status: "Upcoming",
                ),
              ),
            ),

            const SizedBox(height: 28),

            // -------------------------------------------------------
            // MEDICINE SCHEDULE
            // -------------------------------------------------------
            const Text(
              "Medicine Schedule",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _scheduleRow(
                    day: "Morning",
                    time: "8:00 AM",
                    medicine: "Vitamin B12",
                  ),

                  const Divider(height: 28),

                  _scheduleRow(
                    day: "Afternoon",
                    time: "1:00 PM",
                    medicine: "Calcium",
                  ),

                  const Divider(height: 28),

                  _scheduleRow(
                    day: "Evening",
                    time: "8:00 PM",
                    medicine: "Paracetamol",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // -------------------------------------------------------
            // ADD MEDICINE BUTTON
            // -------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddMedicineDialog(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  "Add Medicine",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MEDICINE CARD
  // ===============================================================

  Widget _medicineCard({
    required String medicineName,
    required String dosage,
    required String time,
    required String instruction,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),

          const SizedBox(width: 14),

          // Medicine details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF243B53),
                  ),
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

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 7),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SCHEDULE ROW
  // ===============================================================

  Widget _scheduleRow({
    required String day,
    required String time,
    required String medicine,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: Color(0xFF4F8EF7),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: const TextStyle(fontSize: 14, color: Color(0xFF718096)),
              ),

              const SizedBox(height: 3),

              Text(
                medicine,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF243B53),
                ),
              ),
            ],
          ),
        ),

        Text(
          time,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F8EF7),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // ADD MEDICINE DIALOG
  // ===============================================================

  void _showAddMedicineDialog(BuildContext context) {
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                if (medicineController.text.trim().isEmpty ||
                    dosageController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  medicines.add({
                    "name": medicineController.text.trim(),
                    "dosage": dosageController.text.trim(),
                    "time": "8:00 PM",
                    "instruction": "Take as prescribed",
                  });
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Medicine added successfully.")),
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
  }
}
