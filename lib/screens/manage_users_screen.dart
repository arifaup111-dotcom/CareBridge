import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Admin's user list with account details and password-reset support.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  static const _blue = Color(0xFF4F8EF7);
  static const _navy = Color(0xFF203864);

  String _query = '';
  String _roleFilter = 'all';

  final _searchController = TextEditingController();
  final FirestoreService _db = FirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to send reset link')),
      );
    }
  }

  Future<void> _confirmReset(
    BuildContext context,
    String name,
    String userId,
    String profileEmail,
  ) async {
    var signInEmail = profileEmail;
    try {
      final privateProfile = await FirebaseFirestore.instance
          .collection('userPrivate')
          .doc(userId)
          .get();
      final storedEmail = (privateProfile.data()?['authEmail'] ?? '')
          .toString()
          .trim();
      if (storedEmail.isNotEmpty) signInEmail = storedEmail;
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load the sign-in email: $error')),
      );
      return;
    }

    if (signInEmail.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sign-in email is available for this account.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Reset password?'),
        content: Text(
          'Send a Firebase password reset link to $name ($signInEmail)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await _resetPassword(context, signInEmail);
    }
  }

  Future<void> _editUserProfile({
    required BuildContext context,
    required String uid,
    required String name,
    required String email,
  }) async {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit user profile'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name.'
                      : null,
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Profile email'),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())
                      ? 'Enter a valid email address.'
                      : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin edits update the CareBridge profile only. Family-submitted email and phone changes must be reviewed under Contact Change Approvals.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != true || !context.mounted) return;

      await _db.updateUserProfileByAdmin(
        uid: uid,
        name: nameController.text,
        email: emailController.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile updated.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update user profile: $error')),
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'elder':
        return Icons.elderly_rounded;
      case 'family':
      case 'caregiver':
        return Icons.family_restroom_rounded;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'User Account Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ==============================================================
          // SEARCH + FILTER
          // ==============================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _roleChip('all', 'All'),
                _roleChip('elder', 'Elder'),
                _roleChip('family', 'Family'),
                _roleChip('admin', 'Admin'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ==============================================================
          // LIST
          // ==============================================================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load users: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                if (_roleFilter != 'all') {
                  docs = docs.where((d) {
                    final role = (d.data()['role'] ?? '')
                        .toString()
                        .toLowerCase();
                    return role == _roleFilter ||
                        (_roleFilter == 'family' && role == 'caregiver');
                  }).toList();
                }

                if (_query.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    final phone = (data['phone'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_query) ||
                        email.contains(_query) ||
                        phone.contains(_query);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.isEmpty && _roleFilter == 'all'
                            ? 'No registered users found.'
                            : 'No users match this search.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = (data['name'] ?? 'Unnamed user').toString();
                    final email = (data['email'] ?? '').toString();
                    final phone = (data['phone'] ?? '').toString();
                    final storedRole = (data['role'] ?? 'unknown').toString();
                    final role = storedRole.toLowerCase() == 'caregiver'
                        ? 'Family'
                        : storedRole;
                    final linked = (data['linkedElderId'] ?? '').toString();

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _blue.withValues(alpha: .12),
                              child: Icon(_roleIcon(role), color: _blue),
                            ),
                            const SizedBox(width: 14),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Phone: $phone',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _RoleBadge(role: role),
                                      if ((role.toLowerCase() == 'family' ||
                                              storedRole.toLowerCase() ==
                                                  'caregiver') &&
                                          linked.isNotEmpty)
                                        const _LinkedBadge(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit user profile',
                              onPressed: () => _editUserProfile(
                                context: context,
                                uid: doc.id,
                                name: name,
                                email: email,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              color: _navy,
                            ),
                            IconButton(
                              tooltip: 'Send password reset link',
                              onPressed: () =>
                                  _confirmReset(context, name, doc.id, email),
                              icon: const Icon(Icons.lock_reset_rounded),
                              color: _navy,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String value, String label) {
    final selected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _roleFilter = value),
        selectedColor: _blue,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _navy,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? _blue : Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 12, color: Color(0xFF10B981)),
          SizedBox(width: 3),
          Text(
            'LINKED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
