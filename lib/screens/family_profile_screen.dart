import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isEditing = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String _savedPhone = '';
  String _savedEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _db.currentUid;
      if (uid == null) throw StateError('No signed-in user.');
      final profile = await _db.getUserProfile(uid);
      if (!mounted) return;
      setState(() {
        nameController.text = (profile?['name'] ?? '').toString();
        emailController.text = (profile?['email'] ?? '').toString();
        phoneController.text = (profile?['phone'] ?? '').toString();
        _savedPhone = phoneController.text.trim();
        _savedEmail = emailController.text.trim();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load profile: $error';
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }
    final email = emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }
    final requestedPhone = phoneController.text.trim();
    if (_savedPhone.isNotEmpty && requestedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number cannot be left empty.')),
      );
      return;
    }
    if (requestedPhone.isNotEmpty &&
        requestedPhone != _savedPhone &&
        !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(requestedPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final emailChangeRequested =
          email.toLowerCase() != _savedEmail.toLowerCase();
      final phoneChangeRequested =
          requestedPhone.isNotEmpty && requestedPhone != _savedPhone;
      await _db.updateCurrentUserDetails(name: name);
      if (phoneChangeRequested || emailChangeRequested) {
        await _db.requestContactChange(
          phone: phoneChangeRequested ? requestedPhone : null,
          email: emailChangeRequested ? email : null,
        );
      }
      if (!mounted) return;
      setState(() {
        isEditing = false;
        emailController.text = _savedEmail;
        phoneController.text = _savedPhone;
      });
      final requestedChanges = [
        if (emailChangeRequested) 'email',
        if (phoneChangeRequested) 'phone number',
      ].join(' and ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requestedChanges.isNotEmpty
                ? 'Profile updated. $requestedChanges change submitted for admin approval.'
                : 'Profile updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      phoneController.text = _savedPhone;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit contact change. Other profile details may already be saved. $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F8EF7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Family Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
            icon: Icon(isEditing ? Icons.close : Icons.edit),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Text(_loadError!, textAlign: TextAlign.center))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Color(0xFF4F8EF7),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    nameController.text.isEmpty
                        ? 'Family'
                        : nameController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203864),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Name
                  _buildTextField(
                    controller: nameController,
                    label: "Name",
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 18),

                  // Email
                  _buildTextField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  // Phone
                  _buildTextField(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 10),
                  _phoneRequestStatus(),

                  const SizedBox(height: 30),

                  if (isEditing)
                    Column(
                      children: [
                        const Text(
                          'Changes to your email or phone number are sent to an Admin for approval. Your Firebase sign-in details are not changed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveProfile,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F8EF7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _phoneRequestStatus() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.streamCurrentUserPhoneRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data?.docs ?? const [];
        if (requests.isEmpty) return const SizedBox.shrink();

        final latest = requests.map((request) => request.data()).reduce((a, b) {
          final aTime = a['createdAt'] is Timestamp
              ? (a['createdAt'] as Timestamp).millisecondsSinceEpoch
              : 0;
          final bTime = b['createdAt'] is Timestamp
              ? (b['createdAt'] as Timestamp).millisecondsSinceEpoch
              : 0;
          return aTime >= bTime ? a : b;
        });
        final status = (latest['status'] ?? '').toString();
        if (!{'pending', 'rejected', 'approved'}.contains(status)) {
          return const SizedBox.shrink();
        }

        final requestedPhone = (latest['requestedPhone'] ?? '').toString();
        final requestedEmail = (latest['requestedEmail'] ?? '').toString();
        final requestedChanges = [
          if (requestedEmail.isNotEmpty) requestedEmail,
          if (requestedPhone.isNotEmpty) requestedPhone,
        ].join(' and ');
        final isPending = status == 'pending';
        final isApproved = status == 'approved';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPending
                ? const Color(0xFFFFF8E7)
                : isApproved
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPending
                ? 'Your contact change request ($requestedChanges) is waiting for Admin approval. The requested details will be used only after approval.'
                : isApproved
                ? 'Your contact change request was approved. Reopen this profile to refresh the updated details.'
                : 'Your contact change request was rejected. Your current details remain unchanged; you can submit a new request.',
            style: TextStyle(
              color: isPending
                  ? const Color(0xFF7A5B00)
                  : isApproved
                  ? Colors.green.shade800
                  : Colors.red.shade800,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: isEditing,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
