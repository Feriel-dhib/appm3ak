import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';

/// Client Socket.IO namespace `/transport` (position live, statuts).
class TransportSocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Connexion avec JWT (header Authorization).
  void connect(String baseUrl, String token) {
    disconnect();
    try {
      var base = baseUrl.trim();
      if (base.isEmpty) base = AppConfig.baseUrl.trim();
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      final uri = '$base/transport';
      _socket = io.io(
        uri,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setPath('/socket.io')
            .disableAutoConnect()
            .build(),
      )
        ..onConnect((_) => debugPrint('[Socket] Connecté /transport'))
        ..onDisconnect((_) => debugPrint('[Socket] Déconnecté'))
        ..onError((dynamic e) => debugPrint('[Socket] Erreur : $e'))
        ..connect();
    } catch (e) {
      debugPrint('[Socket] Erreur connexion : $e');
    }
  }

  /// Invité (partage) — sans JWT ; `join_ride` avec `shareToken` côté serveur.
  void connectGuest(String baseUrl) {
    disconnect();
    try {
      var base = baseUrl.trim();
      if (base.isEmpty) base = AppConfig.baseUrl.trim();
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      final uri = '$base/transport';
      _socket = io.io(
        uri,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .disableAutoConnect()
            .build(),
      )
        ..onConnect((_) => debugPrint('[Socket] Connecté /transport (invité)'))
        ..onDisconnect((_) => debugPrint('[Socket] Déconnecté'))
        ..onError((dynamic e) => debugPrint('[Socket] Erreur : $e'))
        ..connect();
    } catch (e) {
      debugPrint('[Socket] Erreur connexion invité : $e');
    }
  }

  void joinRide(String rideId) {
    _socket?.emit('join_ride', {'rideId': rideId});
    debugPrint('[Socket] Rejoint ride_$rideId');
  }

  void joinRideAsGuest(String rideId, String shareToken) {
    _socket?.emit('join_ride', {'rideId': rideId, 'shareToken': shareToken});
    debugPrint('[Socket] Rejoint ride_$rideId (invité)');
  }

  void sendDriverLocation(String rideId, double lat, double lng) {
    if (!isConnected) return;
    _socket?.emit('driver_location', {
      'rideId': rideId,
      'lat': lat,
      'lng': lng,
    });
  }

  void onDriverLocation(void Function(double lat, double lng) cb) {
    _socket?.on('location_update', (dynamic data) {
      try {
        if (data is! Map) return;
        final m = Map<String, dynamic>.from(data);
        cb((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
      } catch (e) {
        debugPrint('[Socket] Erreur parsing location_update : $e');
      }
    });
  }

  void onStatusUpdate(void Function(String statut) cb) {
    _socket?.on('ride_status_update', (dynamic data) {
      try {
        if (data is! Map) return;
        final m = Map<String, dynamic>.from(data);
        cb(m['statut'] as String);
      } catch (e) {
        debugPrint('[Socket] Erreur statut : $e');
      }
    });
  }

  void onServerError(void Function(String message) cb) {
    _socket?.on('error', (dynamic data) {
      try {
        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          cb(m['message'] as String? ?? 'Erreur serveur');
        } else {
          cb(data?.toString() ?? 'Erreur serveur');
        }
      } catch (e) {
        debugPrint('[Socket] Erreur error event : $e');
        cb('Erreur serveur');
      }
    });
  }

  void removeAllListeners() {
    _socket?.off('location_update');
    _socket?.off('ride_status_update');
    _socket?.off('error');
  }

  void disconnect() {
    removeAllListeners();
    _socket?.disconnect();
    _socket = null;
    debugPrint('[Socket] Déconnecté proprement');
  }
}
