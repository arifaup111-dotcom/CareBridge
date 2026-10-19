import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'elder_dashboard.dart';
import 'family_dashboard.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openLogin();
  }

  Future<void> _openLogin() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final preferences = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final rememberLogin = preferences.getBool(AuthService.rememberLoginKey);
    if (rememberLogin == true && user != null) {
      try {
        final profile = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final storedRole = (profile.data()?['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final role = storedRole == 'caregiver' ? 'family' : storedRole;
        if (profile.exists && {'elder', 'family', 'admin'}.contains(role)) {
          final Widget dashboard = switch (role) {
            'family' => const FamilyDashboard(),
            'admin' => const AdminDashboard(),
            _ => const ElderDashboard(),
          };
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => dashboard),
          );
          return;
        }
      } catch (error) {
        debugPrint('Could not restore remembered CareBridge login: $error');
      }
    } else if (rememberLogin == false && user != null) {
      await AuthService().signOut();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, size: 90, color: Colors.red),

            SizedBox(height: 25),

            Text(
              "CareBridge",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Your Malayalam Voice Assistant",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),

            SizedBox(height: 50),

            const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ],
        ),
      ),
    );
  }
}
