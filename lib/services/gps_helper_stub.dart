import 'dart:io';
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

/// Membuka URL Google Maps secara langsung di aplikasi Google Maps / Browser perangkat
Future<bool> openExternalMapUrl(String url) async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final opened = await _gpsChannel.invokeMethod<bool>(
        'openExternalUrl',
        {'url': url},
      );
      if (opened == true) return true;
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (_) {}
  return false;
}
