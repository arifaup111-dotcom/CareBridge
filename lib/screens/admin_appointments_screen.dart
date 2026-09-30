import 'package:flutter/material.dart';

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  // Temporary appointment data
  // Later this will come from Firebase
  final List<Map<String, dynamic>> appointments = const [
    {
      "elder": "Anitha",
      "doctor": "Dr. Anitha",
      "specialization": "General Physician",
      "hospital": "City Care Hospital",
      "date": "Today",
      "time": "4:00 PM",
      "type": "Doctor Consultation",
      "status": "Scheduled",
    },
    {
      "elder": "Mary",
      "doctor": "Dr. Rajesh",
      "specialization": "Cardiologist",
      "hospital": "Life Care Hospital",
      "date": "Friday, 28 August",
      "time": "10:30 AM",
      "type": "Follow-up",
      "status": "Scheduled",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F8EF7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Appointments",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appointment Management",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "View and manage scheduled appointments",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

            // Total appointments
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.purple,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Appointments",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        appointments.length.toString(),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF203864),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Scheduled Appointments",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 15),

            // Appointment list
            ...appointments.map(
              (appointment) => _buildAppointmentCard(appointment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elder name
          Row(
            children: [
              const Icon(
                Icons.elderly,
                color: Color(0xFF4F8EF7),
                size: 27,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  appointment["elder"],
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF203864),
                  ),
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appointment["status"],
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            "Elder",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const Divider(height: 25),

          // Doctor
          Row(
            children: [
              const Icon(
                Icons.medical_services,
                color: Color(0xFF4F8EF7),
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  appointment["doctor"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF203864),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              appointment["specialization"],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 15),

          _buildInfoRow(
            Icons.location_on,
            appointment["hospital"],
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            Icons.calendar_today,
            appointment["date"],
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            Icons.access_time,
            appointment["time"],
          ),

          const SizedBox(height: 15),

          // Appointment type
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              appointment["type"],
              style: const TextStyle(
                color: Color(0xFF4F8EF7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF4F8EF7),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
      ],
    );
  }
}