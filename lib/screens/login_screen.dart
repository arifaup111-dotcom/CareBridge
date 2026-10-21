import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'elder_dashboard.dart';
import 'family_dashboard.dart';
import 'admin_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? selectedRole;
  final bool initialUsePhoneOtp;

  const LoginScreen({
    super.key,
    this.selectedRole,
    this.initialUsePhoneOtp = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  late bool _usePhoneOtp = widget.initialUsePhoneOtp;
  bool _rememberLogin = true;
  String? _verificationId;
  ConfirmationResult? _confirmationResult;
  String? _phoneAuthError;

  @override
  void initState() {
    super.initState();
    _loadRememberLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberLogin() async {
    final rememberLogin = await AuthService().shouldRememberLogin();
    if (mounted) setState(() => _rememberLogin = rememberLogin);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveRememberLogin();
      await _openDashboard(credential.user!);
    } on FirebaseAuthException catch (e) {
      _showMessage(_authErrorMessage(e));
    } catch (e) {
      _showMessage('Unable to sign in. Please try again. ($e)');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final enteredPhone = _phoneController.text.trim().replaceAll(
      RegExp(r'[\s()-]'),
      '',
    );
    final phone = RegExp(r'^\d{10}$').hasMatch(enteredPhone)
        ? '+91$enteredPhone'
        : RegExp(r'^91\d{10}$').hasMatch(enteredPhone)
        ? '+$enteredPhone'
        : enteredPhone;
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      _showMessage(
        'Enter your phone number with country code, e.g. +15551234567.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneAuthError = null;
      _otpController.clear();
      _verificationId = null;
      _confirmationResult = null;
    });
    try {
      if (kIsWeb) {
        _confirmationResult = await _auth.signInWithPhoneNumber(phone);
        if (!mounted) return;
        setState(() {});
        _showMessage('Verification code sent.');
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (credential) async {
            try {
              final result = await _auth.signInWithCredential(credential);
              await _saveRememberLogin();
              await _openDashboard(result.user!);
            } on FirebaseAuthException catch (e) {
              _showMessage(_authErrorMessage(e));
            } catch (e) {
              _showMessage('Unable to verify this phone number. ($e)');
            }
          },
          verificationFailed: (e) {
            debugPrint(
              'Phone OTP verification failed (${e.code}): ${e.message}',
            );
            if (!mounted) return;
            setState(() {
              _verificationId = null;
              _phoneAuthError = _authErrorMessage(e);
            });
            _showMessage(_authErrorMessage(e));
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _phoneAuthError = null;
            });
            _showMessage('Verification code sent.');
          },
          codeAutoRetrievalTimeout: (verificationId) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _phoneAuthError = null;
              });
            }
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      final message = _authErrorMessage(e);
      debugPrint('Phone OTP request failed (${e.code}): ${e.message}');
      if (mounted) setState(() => _phoneAuthError = message);
      _showMessage(message);
    } catch (e) {
      debugPrint('Phone OTP request failed: $e');
      final message = 'Could not send a verification code: $e';
      if (mounted) setState(() => _phoneAuthError = message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      _showMessage('Enter the verification code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential credential;
      if (kIsWeb) {
        final confirmation = _confirmationResult;
        if (confirmation == null) {
          _showMessage('Request a verification code first.');
          return;
        }
        credential = await confirmation.confirm(code);
      } else {
        final verificationId = _verificationId;
        if (verificationId == null) {
          _showMessage('Request a verification code first.');
          return;
        }
        credential = await _auth.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: code,
          ),
        );
      }
      await _saveRememberLogin();
      await _openDashboard(credential.user!);
    } on FirebaseAuthException catch (e) {
      debugPrint('Phone OTP verification failed (${e.code}): ${e.message}');
      _showMessage(_authErrorMessage(e));
    } catch (e) {
      debugPrint('Phone OTP verification failed: $e');
      _showMessage('Unable to verify the code. ($e)');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRememberLogin() async {
    await AuthService().setRememberLogin(_rememberLogin);
  }

  Future<void> _openDashboard(User user) async {
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!profile.exists) {
      await AuthService().signOut();
      if (mounted) {
        _showMessage(
          'Phone verified, but this phone sign-in is not linked to a CareBridge profile. Existing email accounts must link their phone in Firebase Authentication before using OTP sign-in.',
        );
      }
      return;
    }
    final storedRole = (profile.data()?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final role = storedRole == 'caregiver' ? 'family' : storedRole;

    if (!{'elder', 'family', 'admin'}.contains(role)) {
      await AuthService().signOut();
      if (mounted) {
        _showMessage(
          'Your account role is missing or unsupported. Please contact support.',
        );
      }
      return;
    }

    final expectedRole = widget.selectedRole?.trim().toLowerCase();
    if (expectedRole != null &&
        expectedRole.isNotEmpty &&
        role != (expectedRole == 'caregiver' ? 'family' : expectedRole)) {
      await AuthService().signOut();
      if (mounted) {
        _showMessage('This account is not a ${widget.selectedRole} account.');
      }
      return;
    }

    if (!mounted) return;
    final Widget dashboard = switch (role) {
      'family' => const FamilyDashboard(),
      'admin' => const AdminDashboard(),
      _ => const ElderDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address first.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(_authErrorMessage(e));
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email or phone number.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email, password, or verification code is incorrect.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code.';
      case 'operation-not-allowed':
        return 'Phone sign-in is disabled. Enable the Phone provider in Firebase Authentication settings.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'Firebase rejected this app. Add the Android app signing SHA-1 fingerprint in Firebase Project settings.';
      case 'invalid-app-credential':
      case 'captcha-check-failed':
        return 'Firebase could not verify this app. Check the Android SHA-1 fingerprint and registered App Check debug token.';
      case 'quota-exceeded':
        return 'Firebase SMS quota exceeded. Try again later or review Authentication SMS limits.';
      case 'network-request-failed':
        return 'Network request failed. Check your internet connection and retry.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'This verification code has expired. Request a new code and try again.';
      case 'missing-verification-code':
        return 'Enter the SMS verification code.';
      case 'billing-not-enabled':
        return 'Phone sign-in requires a billing-enabled Firebase project. Check Firebase Authentication settings.';
      case 'internal-error':
        return 'Firebase could not complete phone verification. Check the app configuration and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
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
    final otpSent = kIsWeb
        ? _confirmationResult != null
        : _verificationId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
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
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.selectedRole == null
                        ? 'Sign in to your CareBridge account'
                        : 'Sign in as ${widget.selectedRole}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.lock_outline),
                        label: Text('Email'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.sms_outlined),
                        label: Text('Phone OTP'),
                      ),
                    ],
                    selected: {_usePhoneOtp},
                    onSelectionChanged: _isLoading
                        ? null
                        : (selection) =>
                              setState(() => _usePhoneOtp = selection.first),
                  ),
                  const SizedBox(height: 24),
                  if (_usePhoneOtp) ...[
                    TextField(
                      controller: _phoneController,
                      enabled: !_isLoading && !otpSent,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+919876543210 or 9876543210',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _otpController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: InputDecoration(
                        labelText: 'Verification code',
                        hintText: 'Enter the SMS code',
                        prefixIcon: const Icon(Icons.password),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    if (otpSent)
                      Align(
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              child: const Text('Resend code'),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _verificationId = null;
                                        _confirmationResult = null;
                                        _phoneAuthError = null;
                                        _otpController.clear();
                                      });
                                    },
                              child: const Text('Use a different phone number'),
                            ),
                          ],
                        ),
                      ),
                    if (_phoneAuthError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _phoneAuthError!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        hintText: 'Use the email you registered with',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rememberLogin,
                    onChanged: _isLoading
                        ? null
                        : (value) =>
                              setState(() => _rememberLogin = value ?? false),
                    title: const Text('Remember me on this device'),
                    subtitle: const Text(
                      'Stay signed in securely. Your password is not saved.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _usePhoneOtp
                          ? (otpSent ? _verifyOtp : _sendOtp)
                          : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _usePhoneOtp
                                  ? (otpSent ? 'Verify code' : 'Send OTP')
                                  : 'Login',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (!_usePhoneOtp)
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                selectedRole: widget.selectedRole,
                              ),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLoginScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Admin sign in'),
                  ),
                  if (_usePhoneOtp)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Enter a 10-digit Indian number or an international number with country code. The number must be linked to this account in Firebase Authentication.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
