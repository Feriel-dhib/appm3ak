import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/accessibility/accessible_route_result.dart';
import '../models/accessibility/ai_accessibility_result.dart';

/// Échec logique de l'API d'accessibilité (message lisible pour l'UI).
class AccessibilityApiException implements Exception {
  AccessibilityApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AccessibilityApiException($statusCode): $message';
}

/// Accès aux endpoints "Accès & Lieux accessibles" du backend NestJS.
///
/// Stratégie :
///   1. Appel du chemin principal `/accessibility/*`.
///   2. Si le serveur renvoie `404 Not Found`, on retente automatiquement
///      l'alias racine (ex. `/analyze`) pour rester compatible avec le
///      module Python standalone du collègue.
///   3. Toute autre erreur est propagée en [AccessibilityApiException]
///      avec un message lisible.
class AccessibilityPlacesRepository {
  AccessibilityPlacesRepository({required ApiClient apiClient})
      : _dio = apiClient.dio;

  final Dio _dio;

  // ────────────────────────────────────────────────────────────────────────
  // Health check
  // ────────────────────────────────────────────────────────────────────────
  Future<bool> isBackendOnline() async {
    try {
      final response = await _getWithFallback(
        Endpoints.accessibilityHealth,
        Endpoints.accessibilityHealthLegacy,
      );
      if (response.statusCode != 200) return false;
      final data = response.data;
      if (data is Map && data['ok'] == true) return true;
      // Certains backends répondent juste 200 sans body → considéré OK.
      return true;
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // /analyze — scores IA par handicap
  // ────────────────────────────────────────────────────────────────────────
  Future<AIAccessibilityResult> analyze({
    required String placeName,
    required double latitude,
    required double longitude,
    bool wheelchairAccess = false,
    bool elevator = false,
    bool braille = false,
    bool audioAssistance = false,
    bool accessibleToilets = false,
    List<String> userComments = const [],
  }) async {
    final body = <String, dynamic>{
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'wheelchair_access': wheelchairAccess,
      'elevator': elevator,
      'braille': braille,
      'audio_assistance': audioAssistance,
      'accessible_toilets': accessibleToilets,
      'user_comments': userComments,
    };

    final response = await _postWithFallback(
      Endpoints.accessibilityAnalyze,
      Endpoints.accessibilityAnalyzeLegacy,
      data: body,
      timeout: const Duration(seconds: 45),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw AccessibilityApiException(
        'Réponse invalide du service d\'analyse IA.',
        statusCode: response.statusCode,
      );
    }
    return AIAccessibilityResult.fromJson(data);
  }

  // ────────────────────────────────────────────────────────────────────────
  // /osm-tags
  // ────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchOsmTags({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _getWithFallback(
      Endpoints.accessibilityOsmTags,
      Endpoints.accessibilityOsmTagsLegacy,
      query: {'lat': latitude, 'lon': longitude},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return const <String, dynamic>{};
  }

  // ────────────────────────────────────────────────────────────────────────
  // /nearest_node
  // ────────────────────────────────────────────────────────────────────────
  Future<int?> nearestNode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _postWithFallback(
        Endpoints.accessibilityNearestNode,
        Endpoints.accessibilityNearestNodeLegacy,
        data: {'lat': latitude, 'lon': longitude},
        timeout: const Duration(seconds: 20),
      );
      final data = response.data;
      if (data is Map) {
        final id = data['node_id'];
        if (id is int) return id;
        if (id is num) return id.toInt();
        if (id is String) return int.tryParse(id);
      }
      return null;
    } on AccessibilityApiException {
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // /accessible_route_full — itinéraire A* pondéré accessibilité
  // ────────────────────────────────────────────────────────────────────────
  Future<AccessibleRouteResult> accessibleRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final startNode = await nearestNode(
      latitude: start.latitude,
      longitude: start.longitude,
    );
    if (startNode == null) {
      return AccessibleRouteResult.failure(
        'Nœud de départ introuvable. Vérifiez la zone couverte par OSM.',
      );
    }
    final endNode = await nearestNode(
      latitude: end.latitude,
      longitude: end.longitude,
    );
    if (endNode == null) {
      return AccessibleRouteResult.failure(
        'Nœud d\'arrivée introuvable. Vérifiez la zone couverte par OSM.',
      );
    }

    try {
      final response = await _postWithFallback(
        Endpoints.accessibilityRouteFull,
        Endpoints.accessibilityRouteFullLegacy,
        data: {'start_node': startNode, 'end_node': endNode},
        timeout: const Duration(seconds: 30),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return AccessibleRouteResult.failure(
          'Réponse invalide du service d\'itinéraire.',
        );
      }
      if (data.containsKey('error')) {
        return AccessibleRouteResult.failure(
          data['error']?.toString() ?? 'Itinéraire indisponible.',
        );
      }

      final coords = _parseCoordinates(data);
      if (coords.length < 2) {
        return AccessibleRouteResult.failure(
          'Aucun tracé accessible trouvé entre ces deux points.',
        );
      }

      final bestPath = _parseBestPath(data);
      final score = _parseAccessibilityScore(data);

      double distM = 0;
      for (var i = 0; i < coords.length - 1; i++) {
        distM += const Distance().as(LengthUnit.Meter, coords[i], coords[i + 1]);
      }
      // Approximation piéton : 4.5 km/h (cohérent OSRM foot).
      final durS = distM / 1000.0 / 4.5 * 3600.0;

      return AccessibleRouteResult.success(
        coordinates: coords,
        bestPath: bestPath,
        accessibilityScore: score,
        distanceMeters: distM,
        durationSeconds: durS,
      );
    } on AccessibilityApiException catch (e) {
      return AccessibleRouteResult.failure(e.message);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Helpers HTTP avec fallback /accessibility → racine
  // ────────────────────────────────────────────────────────────────────────
  Future<Response<dynamic>> _getWithFallback(
    String primary,
    String legacy, {
    Map<String, dynamic>? query,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await _dio.get<dynamic>(
        primary,
        queryParameters: query,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
    } on DioException catch (e) {
      if (_isNotFound(e)) {
        return _dio.get<dynamic>(
          legacy,
          queryParameters: query,
          options: Options(
            receiveTimeout: timeout,
            sendTimeout: timeout,
          ),
        );
      }
      throw AccessibilityApiException(
        _humanizeDioError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<dynamic>> _postWithFallback(
    String primary,
    String legacy, {
    required Object data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await _dio.post<dynamic>(
        primary,
        data: data,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
    } on DioException catch (e) {
      if (_isNotFound(e)) {
        try {
          return await _dio.post<dynamic>(
            legacy,
            data: data,
            options: Options(
              receiveTimeout: timeout,
              sendTimeout: timeout,
            ),
          );
        } on DioException catch (e2) {
          throw AccessibilityApiException(
            _humanizeDioError(e2),
            statusCode: e2.response?.statusCode,
          );
        }
      }
      throw AccessibilityApiException(
        _humanizeDioError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  bool _isNotFound(DioException e) =>
      e.response?.statusCode == 404 ||
      e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 404;

  String _humanizeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Le serveur accessibilité ne répond pas (délai dépassé).';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur accessibilité. Vérifiez votre réseau.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = e.response?.data;
        if (msg is Map && msg['message'] != null) {
          return 'Erreur $code : ${msg['message']}';
        }
        return 'Erreur serveur (HTTP $code).';
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      case DioExceptionType.badCertificate:
        return 'Certificat serveur invalide.';
      case DioExceptionType.unknown:
        return 'Erreur réseau inattendue : ${e.message ?? 'inconnue'}.';
    }
  }

  List<LatLng> _parseCoordinates(Map<String, dynamic> data) {
    final dynamic source = data['coordinates'] ??
        data['path_coordinates'] ??
        data['route_coordinates'];
    if (source is! List) return const [];
    final pts = <LatLng>[];
    for (final item in source) {
      if (item is Map) {
        final lat = item['lat'] ?? item['latitude'];
        final lon = item['lon'] ?? item['lng'] ?? item['longitude'];
        if (lat is num && lon is num) {
          pts.add(LatLng(lat.toDouble(), lon.toDouble()));
        }
      } else if (item is List && item.length >= 2) {
        final a = item[0];
        final b = item[1];
        if (a is num && b is num) {
          // Heuristique : la latitude a une valeur absolue <= 90.
          final looksLikeLatLon = a.abs() <= 90 && b.abs() > 90;
          final lat = looksLikeLatLon ? a.toDouble() : b.toDouble();
          final lon = looksLikeLatLon ? b.toDouble() : a.toDouble();
          pts.add(LatLng(lat, lon));
        }
      }
    }
    return pts;
  }

  List<int> _parseBestPath(Map<String, dynamic> data) {
    final raw = data['best_path'] ?? data['path_nodes'] ?? data['nodes'];
    if (raw is! List) return const [];
    return raw
        .map<int?>((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        })
        .whereType<int>()
        .toList();
  }

  double _parseAccessibilityScore(Map<String, dynamic> data) {
    final raw = data['average_accessibility_score'] ??
        data['accessibility_score'] ??
        data['score'];
    if (raw is! num) return 0.0;
    final v = raw.toDouble();
    if (v > 1.0) return (v / 100).clamp(0.0, 1.0);
    return v.clamp(0.0, 1.0);
  }
}
