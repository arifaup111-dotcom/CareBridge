import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Family uses the Elder's public Elder ID to create the connection.
class ConnectElderScreen extends StatefulWidget {
  const ConnectElderScreen({super.key});

  @override
  State<ConnectElderScreen> createState() => _ConnectElderScreenState();
}

class _ConnectElderScreenState extends State<ConnectElderScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _elderIdController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _family;

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  @override
  void dispose() {
    _elderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConnection() async {
    final uid = _db.currentUid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final data = await _db.getUserProfile(uid);
    if (!mounted) return;
    setState(() {
      _family = data;
      _elderIdController.text = (data?['linkedElderPublicId'] ?? '').toString();
      _loading = false;
    });
  }

  Future<void> _connect() async {
    final id = _elderIdController.text.trim().toUpperCase();
    if (id.isEmpty) {
      _show('Please enter the Elder ID.');
      return;
    }

    setState(() => _saving = true);
    try {
      final elder = await _db.findElderByPublicId(id);
      if (elder == null) {
        _show('No Elder found with ID $id. Check the ID and try again.');
        return;
      }

      await _db.linkCurrentFamilyToElderByPublicId(id);
      await _loadConnection();
      if (!mounted) return;
      _show('Connected to ${elder['name'] ?? 'Elder'} successfully.');
    } catch (e) {
      if (mounted) _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _disconnect() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect Elder?'),
        content: const Text('This will remove the current Elder connection from your Family account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    final uid = _db.currentUid;
    if (uid == null) return;
    await _db.firestore.collection('users').doc(uid).update({
      'linkedElderId': null,
      'linkedElderPublicId': null,
    });
    await _loadConnection();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final linkedUid = (_family?['linkedElderId'] ?? '').toString();
    final linkedPublicId = (_family?['linkedElderPublicId'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF203864),
        title: const Text('Connect to Elder', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF4F8EF7), size: 42),
                  const SizedBox(height: 12),
                  const Text('Enter the Elder ID', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF203864))),
                  const SizedBox(height: 8),
                  const Text('Ask the Elder for the Elder ID shown in their CareBridge profile.', style: TextStyle(color: Color(0xFF718096), height: 1.4)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _elderIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Elder ID',
                      hintText: 'Example: ELD-A1B2C3',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _connect,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.link),
                      label: Text(_saving ? 'Connecting...' : 'Connect Elder'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F8EF7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (linkedUid.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFEAFBF3), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.check_circle, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Elder Connected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF166534)))]),
                    const SizedBox(height: 10),
                    Text('Elder ID: $linkedPublicId', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('The Family dashboard can now access this Elder\'s profile, health status, medicines and appointments.', style: TextStyle(color: Colors.green.shade900, height: 1.4)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(onPressed: _disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect Elder')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
