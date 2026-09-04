import 'package:flutter/material.dart';

import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5FF), Color(0xFFFDFDFD)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ------------------------------------------------
                // CAREBRIDGE LOGO
                // ------------------------------------------------
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.red,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------
                const Text(
                  "Welcome to\nCareBridge ❤️",
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF203864),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------
                Text(
                  "How will you be using CareBridge today?\n"
                  "Choose one role to personalize your experience.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // ELDER
                // ------------------------------------------------
                buildRoleCard(
                  emoji: "👴",
                  title: "Elder",
                  subtitle: "I need assistance",
                  color: const Color(0xFFFFF5DD),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // CAREGIVER
                // ------------------------------------------------
                buildRoleCard(
                  emoji: "❤️",
                  title: "Caregiver",
                  subtitle: "I'm caring for someone",
                  color: const Color(0xFFEAFBF3),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // FAMILY MEMBER
                // ------------------------------------------------
                buildRoleCard(
                  emoji: "👨‍👩‍👧",
                  title: "Family Member",
                  subtitle: "Stay connected with loved ones",
                  color: const Color(0xFFEEF4FF),
                ),

                const Spacer(),

                // ------------------------------------------------
                // CONTINUE BUTTON
                // ------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: selectedRole == null
                        ? null
                        : () {
                            _continueToSelectedRole();
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF4F8EF7),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ROLE CARD
  // ==============================================================

  Widget buildRoleCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final bool isSelected = selectedRole == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F8EF7) : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),

            const SizedBox(width: 18),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B53),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSelected
                  ? Container(
                      key: const ValueKey("selected"),
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F8EF7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey("empty"),
                      width: 32,
                      height: 32,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CONTINUE LOGIC
  // ==============================================================

  void _continueToSelectedRole() {
    if (selectedRole == "Elder") {
      // Elder → Elder Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // Caregiver / Family Member → Login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
