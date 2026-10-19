import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';

/// Shows the real Elder ID stored for the signed-in Elder.
/// Family members use this ID to connect from their Family Dashboard.
class FamilyConnectionScreen extends StatefulWidget {
  const FamilyConnectionScreen({super.key});

  @override
  State<FamilyConnectionScreen> createState() => _FamilyConnectionScreenState();
}

class _FamilyConnectionScreenState extends State<FamilyConnectionScreen> {
  final FirestoreService _db = FirestoreService();
  String _elderId = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadElderId();
  }

  Future<void> _loadElderId() async {
    try {
      final id = await _db.getOrCreateElderPublicId();
      if (!mounted) return;
      setState(() => _elderId = id ?? 'Not available');
    } catch (_) {
      if (!mounted) return;
      setState(() => _elderId = 'Not available');
    }
  }

  Future<void> _copyElderId() async {
    if (_elderId == 'Loading...' || _elderId == 'Not available') return;
    try {
      await Clipboard.setData(ClipboardData(text: _elderId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not copy the Elder ID.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Elder ID $_elderId copied')));
  }

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Family Connection',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.family_restroom_rounded,
                    size: 55,
                    color: Color(0xFF4F8EF7),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Family Connection',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your family can manage your medicines, appointments and reminders for you.',
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
                    'Your Elder ID',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your family member can use this ID to connect their account with yours.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF4F8EF7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _elderId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Color(0xFF243B53),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy Elder ID',
                          onPressed:
                              _elderId == 'Loading...' ||
                                  _elderId == 'Not available'
                              ? null
                              : _copyElderId,
                          icon: const Icon(Icons.copy_rounded),
                          color: const Color(0xFF4F8EF7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the copy button to copy the exact ID. The Family member should paste this ID into Connect to Elder.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    'Connected Family',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xFFEAF2FF),
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF4F8EF7),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No family member connected',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF243B53),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Waiting for a family member to connect.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
