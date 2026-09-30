import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_users_screen.dart';
import 'admin_appointments_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F8EF7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
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
              "Welcome, Admin",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Manage and monitor CareBridge",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

            // User Statistics
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    "Unable to load user statistics",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  );
                }

                final users = snapshot.data?.docs ?? [];

                int familyMembers = 0;
                int caregivers = 0;
                int elders = 0;

                for (final user in users) {
                  final data =
                      user.data() as Map<String, dynamic>;

                  if (data['role'] == 'Family Member') {
                    familyMembers++;
                  }

                  if (data['role'] == 'Caregiver') {
                    caregivers++;
                  }

                  if (data['role'] == 'Elder') {
                    elders++;
                  }
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: _buildStatCard(
                          title: "Total Users",
                          count: users.length.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 10),

                      SizedBox(
                        width: 120,
                        child: _buildStatCard(
                          title: "Family Members",
                          count: familyMembers.toString(),
                          icon: Icons.family_restroom,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 10),

                      SizedBox(
                        width: 120,
                        child: _buildStatCard(
                          title: "Caregivers",
                          count: caregivers.toString(),
                          icon: Icons.medical_services,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 10),

                      SizedBox(
                        width: 120,
                        child: _buildStatCard(
                          title: "Elders",
                          count: elders.toString(),
                          icon: Icons.elderly,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // Manage Users
            _buildDashboardCard(
              context,
              icon: Icons.people_alt_rounded,
              title: "Manage Users",
              subtitle: "View and manage registered users",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ManageUsersScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Appointments
            _buildDashboardCard(
              context,
              icon: Icons.calendar_month_rounded,
              title: "Appointments",
              subtitle: "View and manage appointments",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdminAppointmentsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Health Monitoring
            _buildDashboardCard(
              context,
              icon: Icons.health_and_safety_rounded,
              title: "Health Monitoring",
              subtitle: "Monitor elder health information",
              color: Colors.green,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Health monitoring coming soon",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Reports
            _buildDashboardCard(
              context,
              icon: Icons.analytics_rounded,
              title: "Reports",
              subtitle: "View system reports and activities",
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Reports coming soon",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Logout
            _buildDashboardCard(
              context,
              icon: Icons.logout_rounded,
              title: "Logout",
              subtitle: "Sign out from admin account",
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Statistics Card
  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF203864),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard Card
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203864),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}