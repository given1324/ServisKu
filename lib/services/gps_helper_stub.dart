import 'package:flutter/services.dart';

const MethodChannel _gpsChannel = MethodChannel('com.example.serviceku/gps');

/// Mengambil koordinat GPS asli dari perangkat Android melalui MethodChannel native
Future<({double lat, double lng})?> getBrowserGpsPosition() async {
  try {
    final result = await _gpsChannel.invokeMapMethod<String, double>('getCurrentLocation');
    if (result != null && result['lat'] != null && result['lng'] != null) {
      return (lat: result['lat']!, lng: result['lng']!);
    }
  } catch (_) {}
  return null;
}
