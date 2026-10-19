// lib/screens/family_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'family_appointments_tab.dart';
import 'family_common.dart';
import 'family_health_tab.dart';
import 'family_medicines_tab.dart';
import 'family_profile_screen.dart';

/// Family dashboard: Health, Medicines, Appointments and Profile tabs.
///
/// The Family account document (users/{uid}) is streamed, so the dashboard
/// switches from the "Connect to an Elder" prompt to the live Elder data as
/// soon as the Elder ID has been linked.
class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  final FirestoreService _db = FirestoreService();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.streamCurrentFamilyProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final elderUid = (data['linkedElderId'] ?? '').toString().trim();
        final linked = elderUid.isNotEmpty;

        final pages = <Widget>[
          linked
              ? FamilyHealthTab(key: ValueKey('health-$elderUid'), elderUid: elderUid)
              : const FamilyUnlinkedPage(title: 'Health'),
          linked
              ? FamilyMedicinesTab(key: ValueKey('meds-$elderUid'), elderUid: elderUid)
              : const FamilyUnlinkedPage(title: 'Medicines'),
          linked
              ? FamilyAppointmentsTab(key: ValueKey('appts-$elderUid'), elderUid: elderUid)
              : const FamilyUnlinkedPage(title: 'Appointments'),
          const FamilyProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Health',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication),
                label: 'Medicines',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Appointments',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
