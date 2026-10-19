import 'package:permission_handler/permission_handler.dart';

/// Central permission gate for CareBridge.
///
/// The elder should never be dropped into a broken screen because a
/// permission was silently denied. Every method here returns a plain
/// bool so the calling screen can show a friendly Malayalam message
/// and keep the touch-based fallback working.
class PermissionService {
  // ================================================================
  // SINGLE PERMISSIONS
  // ================================================================

  /// Microphone — required for speech-to-text.
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Location — required for emergency location sharing.
  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Notifications — required on Android 13+ for reminders.
  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Phone call — required to dial the emergency contact directly.
  static Future<bool> requestPhone() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// SMS — required to send an emergency location text automatically.
  static Future<bool> requestSms() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // ================================================================
  // COMBINED REQUEST
  // ================================================================

  /// Asks for everything the elder dashboard needs, in one pass.
  ///
  /// Returns a map rather than a single bool so the dashboard can
  /// degrade gracefully — for example still allowing voice input when
  /// only the location permission was refused.
  static Future<Map<String, bool>> requestElderDashboardPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.location,
      Permission.notification,
    ].request();

    return {
      'microphone': statuses[Permission.microphone]?.isGranted ?? false,
      'location': statuses[Permission.location]?.isGranted ?? false,
      'notification': statuses[Permission.notification]?.isGranted ?? false,
    };
  }

  // ================================================================
  // STATUS CHECKS (no prompt)
  // ================================================================

  static Future<bool> hasMicrophone() => Permission.microphone.isGranted;

  static Future<bool> hasLocation() => Permission.location.isGranted;

  static Future<bool> hasNotifications() => Permission.notification.isGranted;

  /// True when the user chose "Don't ask again". The caller should then
  /// offer to open system settings instead of prompting again, because
  /// a repeated request will return immediately without a dialog.
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    return await permission.isPermanentlyDenied;
  }

  /// Opens the CareBridge entry in Android system settings.
  static Future<void> openSettings() => openAppSettings();
}
