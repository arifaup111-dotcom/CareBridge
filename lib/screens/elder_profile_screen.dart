import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ElderProfileScreen extends StatelessWidget {
  final String elderUid;

  const ElderProfileScreen({super.key, required this.elderUid});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF203864),
        title: const Text('Elder Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.streamElderProfile(elderUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load Elder profile.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() ?? {};
          final name = (data['name'] ?? 'Elder').toString();
          final elderId = (data['elderId'] ?? 'Not available').toString();
          final email = (data['email'] ?? 'Not available').toString();
          final phone = (data['phone'] ?? 'Not available').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _header(name, elderId),
                const SizedBox(height: 18),
                _section('Personal Information', [
                  _row(Icons.person_outline, 'Name', name),
                  _row(Icons.badge_outlined, 'Elder ID', elderId),
                  _row(Icons.phone_outlined, 'Phone', phone),
                  _row(Icons.email_outlined, 'Email', email),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(String name, String elderId) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F8EF7), Color(0xFF6BA4FF)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.elderly, color: Colors.white, size: 44)),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(elderId, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _section(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203864))), const SizedBox(height: 12), ...children]),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [Icon(icon, size: 22, color: const Color(0xFF4F8EF7)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF718096)))), const SizedBox(width: 10), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF243B53))))]),
      );
}
