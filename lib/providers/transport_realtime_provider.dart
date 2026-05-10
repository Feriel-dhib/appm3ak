import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/services/transport_socket_service.dart';

/// Instance unique — se déconnecte proprement au dispose du provider.
final transportSocketProvider = Provider<TransportSocketService>((ref) {
  final service = TransportSocketService();
  ref.onDispose(service.disconnect);
  return service;
});

/// Position live du chauffeur (écoute WebSocket côté passager).
final driverLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Statut live du trajet (synchronisé via WebSocket).
final rideStatusProvider = StateProvider<String>((ref) => 'EN_ATTENTE');

/// Timer d'envoi position (chauffeur solidaire uniquement).
/// Annuler explicitement dans l'écran chauffeur ([DriverActiveRideScreen]).
final locationTimerProvider = StateProvider<Timer?>((ref) => null);
