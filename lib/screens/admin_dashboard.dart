import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'manage_users_screen.dart';
import 'manage_phone_change_requests_screen.dart';
import 'admin_connect_elder_screen.dart';
import 'admin_login_screen.dart';

/// Admin's home screen.
///
/// Scope is intentionally narrow — see ADMIN_DASHBOARD_SETUP.md:
/// account management (view + password reset) and Family-Elder
/// connection only. This screen adds a live counts strip on top of
/// that so the admin can see the state of the system at a glance
/// without opening either sub-screen — how many elders and families
/// are registered, and how many families still need connecting.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const _bg = Color(0xFFF7FAFF);
  static const _navy = Color(0xFF203864);
  static const _blue = Color(0xFF4F8EF7);
  static const _green = Color(0xFF10B981);

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to manage users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // The counts below are a live stream, so a manual refresh
          // has nothing to fetch — this just gives the pull gesture a
          // response instead of doing nothing, which reads as broken.
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage users, review contact changes, and oversee Family–Elder connections.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 24),

              // ==========================================================
              // LIVE COUNTS
              // ==========================================================
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _StatsError(message: '${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const _StatsLoading();
                  }

                  final docs = snapshot.data!.docs;

                  int elders = 0;
                  int families = 0;
                  int connected = 0;

                  for (final doc in docs) {
                    final data = doc.data();
                    final role = (data['role'] ?? '').toString().toLowerCase();
                    switch (role) {
                      case 'elder':
                        elders++;
                        break;
                      case 'family':
                      case 'caregiver':
                        families++;
                        final linked = (data['linkedElderId'] ?? '').toString();
                        if (linked.isNotEmpty) connected++;
                        break;
                    }
                  }

                  final unconnected = families - connected;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.elderly_rounded,
                              label: 'Elders',
                              value: elders,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.family_restroom_rounded,
                              label: 'Families',
                              value: families,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.link_rounded,
                              label: 'Connected',
                              value: connected,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.link_off_rounded,
                              label: 'Unconnected',
                              value: unconnected < 0 ? 0 : unconnected,
                              color: unconnected > 0
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey,
                              highlight: unconnected > 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 26),

              // ==========================================================
              // ACTIONS
              // ==========================================================
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('phoneChangeRequests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data?.docs.length ?? 0;
                  return _ActionCard(
                    icon: Icons.contact_phone_outlined,
                    title: 'Contact Change Approvals',
                    subtitle: snapshot.hasError
                        ? 'Unable to load pending requests'
                        : '$pendingCount request${pendingCount == 1 ? '' : 's'} waiting for review',
                    color: const Color(0xFF8B5CF6),
                    page: const ManagePhoneChangeRequestsScreen(),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.manage_accounts_rounded,
                title: 'User Account Management',
                subtitle:
                    'Edit profile details, view contacts, and send password resets',
                color: _blue,
                page: const ManageUsersScreen(),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.link_rounded,
                title: 'Family–Elder Connection',
                subtitle:
                    'Connect or disconnect a Family account with an Elder',
                color: _green,
                page: const ConnectElderScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// STAT CARD
// ====================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: highlight ? Border.all(color: color, width: 1.4) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminDashboard._navy,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    Widget skeleton() => Expanded(
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );

    return Column(
      children: [
        Row(children: [skeleton(), const SizedBox(width: 12), skeleton()]),
        const SizedBox(height: 12),
        Row(children: [skeleton(), const SizedBox(width: 12), skeleton()]),
      ],
    );
  }
}

class _StatsError extends StatelessWidget {
  final String message;
  const _StatsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Could not load counts: $message',
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
      ),
    );
  }
}

// ====================================================================
// ACTION CARD
// ====================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdminDashboard._navy,
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
              const Icon(Icons.arrow_forward_ios, size: 17, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
