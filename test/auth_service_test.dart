import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carebridge/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService remember login preference', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('defaults to remembering the login on this device', () async {
      expect(await authService.shouldRememberLogin(), isTrue);
    });

    test('persists opting out across login screen visits', () async {
      await authService.setRememberLogin(false);

      expect(await authService.shouldRememberLogin(), isFalse);
    });

    test('can re-enable remembered login', () async {
      await authService.setRememberLogin(false);
      await authService.setRememberLogin(true);

      expect(await authService.shouldRememberLogin(), isTrue);
    });
  });
}
