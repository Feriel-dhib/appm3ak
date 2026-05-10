import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/map/geocode_result.dart';
import '../models/map/route_result.dart';

/// Repository pour l'API Map (géocodage Nominatim, itinéraires OSRM).
/// Tous les appels passent par le backend ; aucune clé API côté client.
class MapRepository {
  MapRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Géocodage : adresse → liste de résultats (POST /map/geocode).
  Future<List<GeocodeResult>> geocode({
    required String query,
    String? countrycodes,
    int limit = 5,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        Endpoints.mapGeocode,
        data: {
          'query': query,
          if (countrycodes != null && countrycodes.isNotEmpty) 'countrycodes': countrycodes,
          if (limit > 0) 'limit': limit,
        },
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['data'] is List ? (data['data'] as List<dynamic>) : [];
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) => e is Map<String, dynamic>
              ? GeocodeResult.fromJson(e)
              : GeocodeResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : 'Erreur lors de la recherche d\'adresse',
      );
    }
  }

  /// Géocodage en GET : ?q=...&countrycodes=TN&limit=5.
  Future<List<GeocodeResult>> geocodeGet({
    required String q,
    String? countrycodes,
    int limit = 5,
  }) async {
    try {
      final response = await _api.dio.get<List<dynamic>>(
        Endpoints.mapGeocode,
        queryParameters: {
          'q': q,
          if (countrycodes != null && countrycodes.isNotEmpty) 'countrycodes': countrycodes,
          if (limit > 0) 'limit': limit,
        },
      );
      final list = response.data;
      if (list == null || list.isEmpty) return [];
      return list
          .map((e) => GeocodeResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : 'Erreur lors de la recherche d\'adresse',
      );
    }
  }

  /// Géocodage inverse : coordonnées → adresse (POST /map/reverse-geocode).
  Future<GeocodeResult?> reverseGeocode({required double lat, required double lon}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        Endpoints.mapReverseGeocode,
        data: {'lat': lat, 'lon': lon},
      );
      final data = response.data;
      if (data == null) return null;
      return GeocodeResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : 'Erreur lors de la récupération de l\'adresse',
      );
    }
  }

  /// Géocodage inverse en GET : ?lat=...&lon=... .
  Future<GeocodeResult?> reverseGeocodeGet({required double lat, required double lon}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        Endpoints.mapReverseGeocode,
        queryParameters: {'lat': lat, 'lon': lon},
      );
      final data = response.data;
      if (data == null) return null;
      return GeocodeResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : 'Erreur lors de la récupération de l\'adresse',
      );
    }
  }

  /// Calcul d'itinéraire entre origine et destination (POST /map/route).
  Future<RouteResult> route({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
    List<Map<String, double>>? waypoints,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        Endpoints.mapRoute,
        data: {
          'origin': {'lat': originLat, 'lon': originLon},
          'destination': {'lat': destinationLat, 'lon': destinationLon},
          'waypoints': waypoints ?? [],
        },
      );
      final data = response.data;
      if (data == null) throw Exception('Réponse vide');
      return RouteResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : 'Erreur lors du calcul de l\'itinéraire',
      );
    }
  }
}
