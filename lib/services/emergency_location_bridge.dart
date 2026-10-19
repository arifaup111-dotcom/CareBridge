import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EmergencyLocationBridge {
  EmergencyLocationBridge._();

  static const MethodChannel _channel = MethodChannel(
    'carebridge/emergency_location',
  );
  static void Function(
    String elderId,
    String emergencyId,
    double latitude,
    double longitude,
  )? onLocationUpdate;
  static void Function(String message)? onTrackingError;

  static void initialize({
    required void Function(
      String elderId,
      String emergencyId,
      double latitude,
      double longitude,
    ) onLocation,
    required void Function(String message) onError,
  }) {
    onLocationUpdate = onLocation;
    onTrackingError = onError;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEmergencyLocationUpdate') {
        final arguments = Map<Object?, Object?>.from(call.arguments as Map);
        final elderId = arguments['elderId'] as String;
        final emergencyId = arguments['emergencyId'] as String;
        final latitude = (arguments['latitude'] as num).toDouble();
        final longitude = (arguments['longitude'] as num).toDouble();
        onLocationUpdate?.call(elderId, emergencyId, latitude, longitude);
      } else if (call.method == 'onEmergencyLocationError') {
        onTrackingError?.call(
          call.arguments?.toString() ?? 'Emergency location tracking failed.',
        );
      }
    });
  }

  static Future<bool> start({
    required String elderId,
    required String emergencyId,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('startEmergencyLocation', {
            'elderId': elderId,
            'emergencyId': emergencyId,
          }) ==
          true;
    } on PlatformException catch (error) {
      debugPrint('Could not start emergency location sharing: $error');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stopEmergencyLocation') ==
          true;
    } on PlatformException catch (error) {
      debugPrint('Could not stop emergency location sharing: $error');
      return false;
    }
  }
}
