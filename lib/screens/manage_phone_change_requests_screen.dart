import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ManagePhoneChangeRequestsScreen extends StatefulWidget {
  const ManagePhoneChangeRequestsScreen({super.key});

  @override
  State<ManagePhoneChangeRequestsScreen> createState() =>
      _ManagePhoneChangeRequestsScreenState();
}

class _ManagePhoneChangeRequestsScreenState
    extends State<ManagePhoneChangeRequestsScreen> {
  final FirestoreService _db = FirestoreService();
  final Set<String> _reviewing = {};

  Future<void> _review(
    QueryDocumentSnapshot<Map<String, dynamic>> request, {
    required bool approve,
  }) async {
    final data = request.data();
    final userId = (data['userId'] ?? '').toString();
    final phone = (data['requestedPhone'] ?? '').toString();
    final email = (data['requestedEmail'] ?? '').toString();
    if (userId.isEmpty || (phone.isEmpty && email.isEmpty)) {
      _showMessage('This request is missing its user or requested contact.');
      return;
    }

    final requestedChanges = [
      if (phone.isNotEmpty) 'phone number to $phone',
      if (email.isNotEmpty) 'email to $email',
    ].join(' and ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approve ? 'Approve contact change?' : 'Reject contact change?',
        ),
        content: Text(
          approve
              ? 'Apply this change to the user’s CareBridge profile: $requestedChanges?'
              : 'Reject the requested change: $requestedChanges?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _reviewing.add(request.id));
    try {
      await _db.reviewPhoneChangeRequest(
        requestId: request.id,
        userId: userId,
        requestedPhone: phone.isEmpty ? null : phone,
        requestedEmail: email.isEmpty ? null : email,
        approve: approve,
      );
      _showMessage(
        approve ? 'Contact change approved.' : 'Contact change rejected.',
      );
    } catch (error) {
      _showMessage('Could not review this request: $error');
    } finally {
      if (mounted) setState(() => _reviewing.remove(request.id));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F8EF7),
        foregroundColor: Colors.white,
        title: const Text(
          'Contact Change Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.streamPendingPhoneChangeRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load requests: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No contact changes are waiting for approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF718096), fontSize: 16),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data();
              final uid = (data['userId'] ?? '').toString();
              final phone = (data['requestedPhone'] ?? '').toString();
              final requestedEmail = (data['requestedEmail'] ?? '').toString();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _db.getUserProfile(uid),
                builder: (context, userSnapshot) {
                  final profile = userSnapshot.data;
                  final name = (profile?['name'] ?? 'Loading user...')
                      .toString();
                  final email = (profile?['email'] ?? '').toString();
                  final oldPhone = (profile?['phone'] ?? 'Not set').toString();
                  final role = (profile?['role'] ?? 'User')
                      .toString()
                      .toUpperCase();
                  final isReviewing = _reviewing.contains(request.id);

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xFFEAF2FF),
                                child: Icon(
                                  requestedEmail.isNotEmpty && phone.isEmpty
                                      ? Icons.email_outlined
                                      : Icons.phone_android_rounded,
                                  color: const Color(0xFF4F8EF7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$role${email.isEmpty ? '' : ' • $email'}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (phone.isNotEmpty) ...[
                            _numberRow('Current number', oldPhone),
                            const SizedBox(height: 8),
                            _numberRow('Requested number', phone),
                          ],
                          if (requestedEmail.isNotEmpty) ...[
                            if (phone.isNotEmpty) const SizedBox(height: 8),
                            _numberRow(
                              'Current email',
                              email.isEmpty ? 'Not set' : email,
                            ),
                            const SizedBox(height: 8),
                            _numberRow('Requested email', requestedEmail),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isReviewing
                                      ? null
                                      : () => _review(request, approve: false),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: isReviewing
                                      ? null
                                      : () => _review(request, approve: true),
                                  icon: isReviewing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded),
                                  label: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _numberRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 135,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF203864),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
