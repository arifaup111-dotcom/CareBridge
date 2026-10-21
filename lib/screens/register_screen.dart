import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  /// Role chosen on the role-selection screen, or null for a direct signup.
  /// Saved to users/{uid}.role so FirestoreService.resolveElderId()
  /// knows whose data this account should read and write.
  final String? selectedRole;

  const RegisterScreen({super.key, this.selectedRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final AuthService authService = AuthService();
  final FirestoreService _db = FirestoreService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  late String? _selectedRole = widget.selectedRole?.toLowerCase();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF4F8EF7), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: 80,
                    color: Color(0xFF4F8EF7),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "Create Account",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "Join CareBridge and stay connected",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 35),

                TextFormField(
                  controller: nameController,
                  decoration: inputDecoration(
                    label: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter your name" : null,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration(
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter email" : null,
                ),

                const SizedBox(height: 18),

                if (_selectedRole == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: inputDecoration(
                      label: "Account Type",
                      icon: Icons.people_outline,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'elder', child: Text('Elder')),
                      DropdownMenuItem(
                        value: 'family',
                        child: Text('Family Member'),
                      ),
                    ],
                    onChanged: (role) => setState(() => _selectedRole = role),
                    validator: (role) =>
                        role == null ? 'Choose an account type' : null,
                  ),
                  const SizedBox(height: 18),
                ],

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration(
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Enter phone number"
                      : null,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: inputDecoration(
                    label: "Password",
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: inputDecoration(
                    label: "Confirm Password",
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8EF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          final cred = await authService.registerUser(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          // Every Elder receives a short public Elder ID.
                          // Family members use this ID to connect from their dashboard.
                          final role = _selectedRole;
                          if (role == null) {
                            throw StateError('Choose an account type.');
                          }
                          final isElder = role == 'elder';
                          final publicElderId = isElder
                              ? _db.createElderId(cred.user!.uid)
                              : null;

                          await _db.saveUserProfile(
                            uid: cred.user!.uid,
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            role: role,
                            phone: phoneController.text.trim(),
                            elderId: publicElderId,
                          );

                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                publicElderId == null
                                    ? 'Registration Successful'
                                    : 'Registration Successful. Your Elder ID is $publicElderId',
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );

                          navigator.pop();
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
