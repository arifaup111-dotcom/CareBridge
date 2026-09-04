import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  // ==============================================================
  // TEMPORARY APPOINTMENT DATA
  // Later this will come from Firebase / Family Dashboard
  // ==============================================================

  final List<Map<String, dynamic>> appointments = const [
    {
      "doctor": "Dr. Anitha",
      "specialization": "General Physician",
      "hospital": "City Care Hospital",
      "date": "Today",
      "time": "4:00 PM",
      "type": "Doctor Consultation",
    },
    {
      "doctor": "Dr. Rajesh",
      "specialization": "Cardiologist",
      "hospital": "Life Care Hospital",
      "date": "Friday, 28 August",
      "time": "10:30 AM",
      "type": "Follow-up",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF203864),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Appointments",
          style: TextStyle(
            color: Color(0xFF203864),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // INTRO
              // ----------------------------------------------------
              const Text(
                "Your Appointments",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Here are your upcoming doctor appointments.",
                style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------
              // TODAY'S APPOINTMENT
              // ----------------------------------------------------
              const Text(
                "Today's Appointment",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 12),

              _buildTodayAppointment(appointments[0]),

              const SizedBox(height: 28),

              // ----------------------------------------------------
              // UPCOMING
              // ----------------------------------------------------
              const Text(
                "Upcoming Appointments",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 12),

              ...appointments
                  .skip(1)
                  .map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildAppointmentCard(appointment),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TODAY APPOINTMENT CARD
  // ================================================================

  Widget _buildTodayAppointment(Map<String, dynamic> appointment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F8EF7), Color(0xFF6FA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODAY
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white, size: 25),

              const SizedBox(width: 10),

              const Text(
                "TODAY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // DOCTOR
          Text(
            appointment["doctor"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            appointment["specialization"],
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 18),

          // TIME
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 21,
              ),

              const SizedBox(width: 8),

              Text(
                appointment["time"],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // HOSPITAL
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 21,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  appointment["hospital"],
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // TYPE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              appointment["type"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // UPCOMING APPOINTMENT CARD
  // ================================================================

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4F8EF7),
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment["doctor"],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF243B53),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  appointment["specialization"],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xFF4F8EF7),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        appointment["date"],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF4F8EF7),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      appointment["time"],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF4F8EF7),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        appointment["hospital"],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
