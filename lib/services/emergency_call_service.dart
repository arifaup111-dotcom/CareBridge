import 'package:flutter/services.dart';

/// Native Android bridge for an immediate emergency call.
///
/// CareBridge already asks for CALL_PHONE permission. Using ACTION_CALL
/// means the Emergency SOS action can place the call immediately instead of
/// only opening the dialer with the number filled in.
class EmergencyCallService {
  EmergencyCallService._();

  static const MethodChannel _channel = MethodChannel(
    'carebridge/emergency_call',
  );

  static Future<bool> sendEmergencyLocationSms({
    required String phoneNumber,
    required double latitude,
    required double longitude,
  }) async {
    final number = phoneNumber.trim();
    if (number.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'sendEmergencyLocationSms',
        <String, dynamic>{
          'phoneNumber': number,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return result == true;
    } on PlatformException catch (error) {
      // ignore: avoid_print
      print('Emergency location SMS failed: ${error.code} ${error.message}');
      return false;
    } catch (error) {
      // ignore: avoid_print
      print('Emergency location SMS failed: $error');
      return false;
    }
  }

  static Future<bool> call(String phoneNumber) async {
    final number = phoneNumber.trim();
    if (number.isEmpty) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'directCall',
        <String, dynamic>{'phoneNumber': number},
      );
      return result == true;
    } on PlatformException catch (e) {
      // Keep the dashboard alive even if the native call cannot be started.
      // The caller can show a friendly fallback message.
      // ignore: avoid_print
      print('Emergency call failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Emergency call failed: $e');
      return false;
    }
  }
}
