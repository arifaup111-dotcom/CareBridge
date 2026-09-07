import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

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
          "Reminders",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // TODAY
            // --------------------------------------------------
            const Text(
              "Today's Reminders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF243B53),
              ),
            ),

            const SizedBox(height: 15),

            _buildReminderCard(
              icon: Icons.medication_rounded,
              title: "Morning Medicine",
              subtitle: "Take your prescribed medicine",
              time: "8:00 AM",
              iconColor: const Color(0xFF4F8EF7),
            ),

            const SizedBox(height: 12),

            _buildReminderCard(
              icon: Icons.restaurant_rounded,
              title: "Breakfast",
              subtitle: "Have your morning meal",
              time: "9:00 AM",
              iconColor: const Color(0xFFE58B2A),
            ),

            const SizedBox(height: 12),

            _buildReminderCard(
              icon: Icons.water_drop_rounded,
              title: "Drink Water",
              subtitle: "Drink one glass of water",
              time: "11:00 AM",
              iconColor: const Color(0xFF3BA7D8),
            ),

            const SizedBox(height: 12),

            _buildReminderCard(
              icon: Icons.calendar_month_rounded,
              title: "Doctor Appointment",
              subtitle: "Visit your doctor",
              time: "3:00 PM",
              iconColor: const Color(0xFF7A5AF8),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // UPCOMING
            // --------------------------------------------------
            const Text(
              "Upcoming",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF243B53),
              ),
            ),

            const SizedBox(height: 15),

            _buildReminderCard(
              icon: Icons.directions_walk_rounded,
              title: "Evening Walk",
              subtitle: "Walk for 20 minutes",
              time: "Tomorrow • 6:00 PM",
              iconColor: const Color(0xFF43A047),
            ),

            const SizedBox(height: 12),

            _buildReminderCard(
              icon: Icons.medication_rounded,
              title: "Medicine Refill",
              subtitle: "Refill your medicines",
              time: "30 Aug",
              iconColor: const Color(0xFF4F8EF7),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // ADD REMINDER BUTTON
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddReminderDialog(context);
                },

                icon: const Icon(Icons.add_rounded),

                label: const Text(
                  "Add Reminder",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                "Reminders can later be managed by your family.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // REMINDER CARD
  // ==========================================================

  static Widget _buildReminderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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

          Text(
            time,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F8EF7),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ADD REMINDER DIALOG
  // ==========================================================

  static void _showAddReminderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Center(
                child: Text(
                  "Add Reminder",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF243B53),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              _buildReminderType(context, Icons.medication_rounded, "Medicine"),

              _buildReminderType(context, Icons.restaurant_rounded, "Food"),

              _buildReminderType(context, Icons.water_drop_rounded, "Water"),

              _buildReminderType(
                context,
                Icons.calendar_month_rounded,
                "Appointment",
              ),

              _buildReminderType(
                context,
                Icons.directions_walk_rounded,
                "Activity",
              ),

              _buildReminderType(
                context,
                Icons.notifications_rounded,
                "Other Reminder",
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // REMINDER TYPE
  // ==========================================================

  static Widget _buildReminderType(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Container(
        width: 45,
        height: 45,

        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(13),
        ),

        child: Icon(icon, color: const Color(0xFF4F8EF7)),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF243B53),
        ),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Color(0xFF718096),
      ),

      onTap: () {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$title reminder selected.")));
      },
    );
  }
}
