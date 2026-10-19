import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class HealthStatusScreen extends StatefulWidget {
  const HealthStatusScreen({super.key});

  @override
  State<HealthStatusScreen> createState() => _HealthStatusScreenState();
}

class _HealthStatusScreenState extends State<HealthStatusScreen> {
  final FirestoreService _db = FirestoreService();
  String? _elderId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadElder();
  }

  Future<void> _loadElder() async {
    final id = await _db.resolveElderId();
    if (!mounted) return;
    setState(() {
      _elderId = id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_elderId == null) return _empty('Connect an Elder first from the Family Dashboard.');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(backgroundColor: const Color(0xFF4F8EF7), foregroundColor: Colors.white, elevation: 0, title: const Text('Health Status', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.streamElderProfile(_elderId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load health information.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? {};
          final name = (data['name'] ?? 'Connected Elder').toString();
          final health = data['health'] is Map ? Map<String, dynamic>.from(data['health'] as Map) : data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.elderly, color: Color(0xFF4F8EF7))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Connected Elder', style: TextStyle(color: Color(0xFF718096))), const SizedBox(height: 4), Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF203864)))]))])),
              const SizedBox(height: 18),
              const Text('Current Health Status', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF203864))),
              const SizedBox(height: 12),
              _healthCard(Icons.favorite, 'Heart Rate', _value(health, ['heartRate', 'heart_rate']), Colors.red),
              _healthCard(Icons.monitor_heart, 'Blood Pressure', _value(health, ['bloodPressure', 'blood_pressure']), Colors.purple),
              _healthCard(Icons.thermostat, 'Temperature', _value(health, ['temperature']), Colors.orange),
              _healthCard(Icons.health_and_safety, 'Overall Status', _value(health, ['status', 'healthStatus']), Colors.green),
              if (_value(health, ['heartRate', 'heart_rate']) == 'Not available' && _value(health, ['bloodPressure', 'blood_pressure']) == 'Not available' && _value(health, ['temperature']) == 'Not available')
                Container(width: double.infinity, margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(16)), child: const Text('No health readings have been stored for this Elder yet. The Family view will update automatically when health data is added.', style: TextStyle(color: Color(0xFF7A5B00), height: 1.4))),
            ]),
          );
        },
      ),
    );
  }

  String _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return 'Not available';
  }

  Widget _healthCard(IconData icon, String label, String value, Color color) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [Icon(icon, color: color, size: 26), const SizedBox(width: 14), Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569)))), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF203864)))]));

  Widget _empty(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF203864),
        elevation: 0,
        title: const Text('Health Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
