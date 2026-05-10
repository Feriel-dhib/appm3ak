import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Zone approximative Tunisie (évite adresses USA sur émulateur si le profil a des coords TN).
bool isRoughlyInTunisia(double lat, double lon) {
  return lat >= 30.2 && lat <= 37.8 && lon >= 7.4 && lon <= 11.8;
}

/// Si le GPS est hors Tunisie alors que le profil a un point en Tunisie, on garde le profil.
({double lat, double lon}) preferTunisiaProfileWhenGpsMismatch({
  required double gpsLat,
  required double gpsLon,
  double? profileLat,
  double? profileLon,
}) {
  if (profileLat != null &&
      profileLon != null &&
      isRoughlyInTunisia(profileLat, profileLon) &&
      !isRoughlyInTunisia(gpsLat, gpsLon)) {
    return (lat: profileLat, lon: profileLon);
  }
  return (lat: gpsLat, lon: gpsLon);
}

/// Erreurs métier géolocalisation (messages courts pour l’UI).
enum GeolocationError {
  permissionDenied,
  serviceDisabled,
  timeout,
}

/// Obtient une position sans bloquer indéfiniment l’app (réduit les ANR sur Android).
///
/// 1. Vérifie permission + service.
/// 2. Utilise [Geolocator.getLastKnownPosition] si récente (≤ 30 min).
/// 3. Sinon [getCurrentPosition] en précision **medium** + **timeLimit** (réseau / fused, adapté émulateur).
Future<Position> resolveUserPosition({
  Duration timeLimit = const Duration(seconds: 15),
  Duration maxLastKnownAge = const Duration(minutes: 30),
}) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw GeolocationError.permissionDenied;
  }

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw GeolocationError.serviceDisabled;
  }

  final last = await Geolocator.getLastKnownPosition();
  if (last != null) {
    final age = DateTime.now().difference(last.timestamp);
    if (age <= maxLastKnownAge) {
      return last;
    }
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: timeLimit,
      ),
    );
  } on TimeoutException {
    if (last != null) return last;
    throw GeolocationError.timeout;
  }
}

/// Après échec GPS (timeout / service), utiliser le profil s’il contient des coordonnées.
({double lat, double lon})? profileCoordinatesFallback(
  double? profileLat,
  double? profileLon,
) {
  if (profileLat != null && profileLon != null) {
    return (lat: profileLat, lon: profileLon);
  }
  return null;
}
