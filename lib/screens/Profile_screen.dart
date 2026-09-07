import 'dart:io';
import 'family_connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  String name = "Elder User";
  String age = "65";
  String phone = "Not added";

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
    final ageController = TextEditingController(text: age);
    final phoneController = TextEditingController(text: phone);

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
              onPressed: () {
                setState(() {
                  name = nameController.text.trim().isEmpty
                      ? "Elder User"
                      : nameController.text.trim();

                  age = ageController.text.trim().isEmpty
                      ? "Not added"
                      : ageController.text.trim();

                  phone = phoneController.text.trim().isEmpty
                      ? "Not added"
                      : phoneController.text.trim();
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Logout will be connected later."),
                  ),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
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
                            "CB-ELD-4827",
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Elder ID copied")),
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
