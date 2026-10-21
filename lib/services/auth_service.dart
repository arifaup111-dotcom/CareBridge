import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String rememberLoginKey = 'rememberLogin';
  static const bool defaultRememberLogin = true;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;

  Future<bool> shouldRememberLogin() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(rememberLoginKey) ?? defaultRememberLogin;
  }

  Future<void> setRememberLogin(bool remember) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(rememberLoginKey, remember);
  }

  // Register User
  Future<UserCredential> registerUser({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
