import 'package:flutter/material.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

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
          "Family",
          style: TextStyle(
            color: Color(0xFF243B53),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // --------------------------------------------------
            // FAMILY INTRO CARD
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.family_restroom_rounded,
                      size: 40,
                      color: Color(0xFF4F8EF7),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Your Family",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Your family can help you manage "
                    "your medicines, appointments and reminders.",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // CONNECTION STATUS
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Family Connection",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 42,
                          color: Color(0xFF718096),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "No family member connected",
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF243B53),
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          "Your connected family member will "
                          "appear here.",
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // WHAT FAMILY CAN HELP WITH
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "How Family Can Help",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildHelpItem(
                    icon: Icons.medication_rounded,
                    title: "Medicines",
                    subtitle: "Help manage your medicine schedule.",
                  ),

                  const SizedBox(height: 15),

                  _buildHelpItem(
                    icon: Icons.calendar_month_rounded,
                    title: "Appointments",
                    subtitle: "Help manage your appointments.",
                  ),

                  const SizedBox(height: 15),

                  _buildHelpItem(
                    icon: Icons.notifications_active_rounded,
                    title: "Reminders",
                    subtitle: "Help keep track of important reminders.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // INFORMATION
            // --------------------------------------------------
            const Text(
              "Family connection will be available once "
              "your account is connected.",
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF718096),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELP ITEM
  // ==========================================================

  static Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: const Color(0xFF4F8EF7), size: 25),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243B53),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
