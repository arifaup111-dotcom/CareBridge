import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'elder_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOGIN
  // ================================================================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Check empty fields
    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter your email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      // Login successful → Elder Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ElderDashboard()),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email.";
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = "Incorrect email or password.";
          break;

        case 'invalid-email':
          message = "Please enter a valid email address.";
          break;

        case 'user-disabled':
          message = "This account has been disabled.";
          break;

        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;

        default:
          message = e.message ?? "Login failed. Please try again.";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================================================================
  // FORGOT PASSWORD
  // ================================================================

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Please enter your email first.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      _showMessage("Password reset email sent. Check your inbox.");
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Unable to send password reset email.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),

          child: Column(
            children: [
              const SizedBox(height: 30),

              // ----------------------------------------------------
              // LOGO
              // ----------------------------------------------------
              Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                  size: 50,
                ),
              ),

              const SizedBox(height: 25),

              // ----------------------------------------------------
              // TITLE
              // ----------------------------------------------------
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Sign in to continue using CareBridge",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ----------------------------------------------------
              // EMAIL
              // ----------------------------------------------------
              TextField(
                controller: emailController,

                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  labelText: "Email",

                  prefixIcon: const Icon(Icons.email_outlined),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------
              // PASSWORD
              // ----------------------------------------------------
              TextField(
                controller: passwordController,

                obscureText: _obscurePassword,

                decoration: InputDecoration(
                  labelText: "Password",

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------
              // FORGOT PASSWORD
              // ----------------------------------------------------
              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: _forgotPassword,

                  child: const Text("Forgot Password?"),
                ),
              ),

              const SizedBox(height: 15),

              // ----------------------------------------------------
              // LOGIN BUTTON
              // ----------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 25,
                          height: 25,

                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // ----------------------------------------------------
              // REGISTER
              // ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text("Don't have an account?"),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },

                    child: const Text("Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
