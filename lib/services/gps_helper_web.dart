import 'dart:async';
import 'dart:js_interop';

@JS('navigator.geolocation.getCurrentPosition')
external void _getCurrentPosition(
  JSFunction success,
  JSFunction error,
  _PositionOptions options,
);

extension type _GeolocationPosition._(JSObject _) implements JSObject {
  external _GeolocationCoordinates get coords;
}

extension type _GeolocationCoordinates._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
}

extension type _GeolocationError._(JSObject _) implements JSObject {
  external int get code;
  external String get message;
}

extension type _PositionOptions._(JSObject _) implements JSObject {
  external factory _PositionOptions({
    bool enableHighAccuracy,
    int timeout,
    int maximumAge,
  });
}

/// Mengambil koordinat GPS asli dari browser (HTML5 Geolocation API)
Future<({double lat, double lng})?> getBrowserGpsPosition() async {
  final completer = Completer<({double lat, double lng})?>();

  void onSuccess(_GeolocationPosition pos) {
    if (!completer.isCompleted) {
      completer.complete((
        lat: pos.coords.latitude,
        lng: pos.coords.longitude,
      ));
    }
  }

  void onError(_GeolocationError err) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  try {
    _getCurrentPosition(
      onSuccess.toJS,
      onError.toJS,
      _PositionOptions(
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      ),
    );
  } catch (_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  return completer.future.timeout(
    const Duration(seconds: 12),
    onTimeout: () => null,
  );
}

