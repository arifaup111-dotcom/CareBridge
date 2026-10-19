import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'family_connection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/background_voice_bridge.dart';
import '../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  String name = "Not available";
  String age = "Not added";
  String phone = "Not added";
  String email = "Not added";
  String assistantName = "Care";
  String elderId = "Loading...";

  final FirestoreService _db = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _db.currentUid;
      if (uid == null) return;
      final profile = await _db.getUserProfile(uid);
      final id = await _db.getOrCreateElderPublicId();
      if (!mounted) return;
      setState(() {
        name = (profile?['name'] ?? 'Not available').toString();
        age = (profile?['age'] ?? 'Not added').toString();
        phone = (profile?['phone'] ?? 'Not added').toString();
        email = (profile?['email'] ?? 'Not added').toString();
        assistantName = (profile?['assistantName'] ?? 'Care').toString();
        elderId = id ?? 'Not available';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => elderId = 'Not available');
    }
  }

  Widget _phoneChangeStatus() {
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
        if (status != 'pending' && status != 'rejected') {
          return const SizedBox.shrink();
        }

        final isPending = status == 'pending';
        final requestedPhone = (latest['requestedPhone'] ?? '').toString();
        final requestedEmail = (latest['requestedEmail'] ?? '').toString();
        final requestedContacts = [
          if (requestedPhone.isNotEmpty) 'phone $requestedPhone',
          if (requestedEmail.isNotEmpty) 'email $requestedEmail',
        ].join(' and ');
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPending
                ? const Color(0xFFFFF8E7)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPending
                ? 'Your change request for $requestedContacts is waiting for admin approval. Current contact details remain active until approved.'
                : 'Your contact change request was rejected. You can submit a new request.',
            style: TextStyle(
              color: isPending ? const Color(0xFF7A5B00) : Colors.red.shade800,
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeProfilePicture() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    setState(() {
      _profileImage = File(pickedImage.path);
    });
  }

  void _editDetails() {
    final nameController = TextEditingController(text: name);
    final ageController = TextEditingController(
      text: age == 'Not added' ? '' : age,
    );
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(
      text: email == 'Not added' ? '' : email,
    );
    final assistantController = TextEditingController(text: assistantName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Edit Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Age",
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assistantController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: "Name to call the app",
                    prefixIcon: Icon(Icons.record_voice_over_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text.trim();
                final ageText = ageController.text.trim();
                final requestedPhone = phoneController.text.trim();
                final requestedEmail = emailController.text.trim();
                final requestedAssistantName = assistantController.text.trim();
                final parsedAge = ageText.isEmpty
                    ? null
                    : int.tryParse(ageText);
                if (updatedName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required.')),
                  );
                  return;
                }
                if (ageText.isNotEmpty &&
                    (parsedAge == null || parsedAge < 0 || parsedAge > 130)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid age.')),
                  );
                  return;
                }
                if (requestedPhone.isEmpty && phone != 'Not added') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number cannot be left empty.'),
                    ),
                  );
                  return;
                }
                if (requestedPhone.isNotEmpty &&
                    requestedPhone != phone &&
                    !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(requestedPhone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid phone number.'),
                    ),
                  );
                  return;
                }
                if (requestedEmail.isEmpty && email != 'Not added') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email cannot be left empty.'),
                    ),
                  );
                  return;
                }
                if (requestedEmail.isNotEmpty &&
                    !RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(requestedEmail)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid email address.'),
                    ),
                  );
                  return;
                }
                if (requestedAssistantName.isEmpty ||
                    requestedAssistantName.length > 30) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter an app name up to 30 characters.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                try {
                  final phoneChangeRequested =
                      requestedPhone.isNotEmpty && requestedPhone != phone;
                  final emailChangeRequested =
                      requestedEmail.isNotEmpty &&
                      requestedEmail.toLowerCase() != email.toLowerCase();
                  final assistantNameChanged =
                      requestedAssistantName != assistantName;
                  await _db.updateCurrentUserDetails(
                    name: updatedName,
                    age: ageText.isEmpty ? null : ageText,
                  );
                  if (phoneChangeRequested || emailChangeRequested) {
                    await _db.requestContactChange(
                      phone: phoneChangeRequested ? requestedPhone : null,
                      email: emailChangeRequested ? requestedEmail : null,
                    );
                  }
                  if (assistantNameChanged) {
                    await _db.updateAssistantName(requestedAssistantName);
                  }
                  var wakeListenerUpdated = true;
                  if (assistantNameChanged &&
                      defaultTargetPlatform == TargetPlatform.android) {
                    wakeListenerUpdated =
                        await BackgroundVoiceBridge.startForegroundService(
                          wakePhrase: requestedAssistantName,
                        );
                  }
                  if (!mounted) return;
                  setState(() {
                    name = updatedName;
                    age = ageText.isEmpty ? 'Not added' : ageText;
                    assistantName = requestedAssistantName;
                  });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !wakeListenerUpdated
                            ? 'Profile saved, but the wake name could not be applied. Reopen the Elder dashboard to retry.'
                            : phoneChangeRequested || emailChangeRequested
                            ? 'Profile updated. Contact change submitted for admin approval.'
                            : 'Profile updated.',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Could not update profile.')),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await BackgroundVoiceBridge.stopForegroundService();
      }
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Delete Account",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete your account? "
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account deletion will be connected later."),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color(0xFF243B53),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeProfilePicture,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFEAF2FF),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Color(0xFF4F8EF7),
                                )
                              : null,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F8EF7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Elder Account",
                    style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF4F8EF7),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Elder ID",
                          style: TextStyle(color: Color(0xFF718096)),
                        ),
                        const Spacer(),
                        Text(
                          elderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF203864),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  OutlinedButton.icon(
                    onPressed: _changeProfilePicture,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("Change Profile Picture"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PERSONAL DETAILS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Personal Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF243B53),
                          ),
                        ),
                      ),

                      TextButton.icon(
                        onPressed: _editDetails,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text("Edit"),
                      ),
                    ],
                  ),

                  const Divider(),

                  _detailRow(Icons.person_outline, "Name", name),

                  _detailRow(Icons.cake_outlined, "Age", age),

                  _detailRow(Icons.phone_outlined, "Phone", phone),
                  _detailRow(Icons.email_outlined, "Email", email),
                  _detailRow(
                    Icons.record_voice_over_outlined,
                    "App wake name",
                    assistantName,
                  ),
                  _phoneChangeStatus(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ELDER ID
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Elder ID",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Give this ID to your family member to connect with you.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            elderId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Color(0xFF4F8EF7),
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed:
                            elderId == 'Loading...' ||
                                elderId == 'Not available'
                            ? null
                            : () async {
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(text: elderId),
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not copy the Elder ID.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('$elderId copied')),
                                );
                              },
                        icon: const Icon(Icons.copy_rounded),
                        color: const Color(0xFF4F8EF7),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FAMILY CONNECTION
            // FAMILY CONNECTION
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyConnectionScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 30,
                        color: Color(0xFF4F8EF7),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Family Connection",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF243B53),
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Manage your family connection",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Color(0xFF718096),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LOGOUT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Logout"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF243B53),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFFD9E2EC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // DELETE ACCOUNT
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F8EF7), size: 24),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243B53),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
