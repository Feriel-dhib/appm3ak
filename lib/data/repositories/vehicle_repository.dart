import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/vehicle.dart';
import '../models/vehicle_statut.dart';

class VehicleRepository {
  VehicleRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Créer un véhicule (POST /vehicles).
  Future<Vehicle> create(Vehicle vehicle) async {
    try {
      final response = await _api.dio.post(
        Endpoints.vehicles,
        data: vehicle.toCreateJson(),
      );
      return Vehicle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Cette immatriculation est déjà enregistrée');
      }
      throw Exception(_extractErrorMessage(e, 'Erreur lors de la création du véhicule'));
    }
  }

  /// Extrait le message d'erreur du backend (message peut être String ou List).
  static String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is! Map) return fallback;
    final message = data['message'];
    if (message is List && message.isNotEmpty) {
      return message.map((e) => e.toString()).join(', ');
    }
    if (message != null) return message.toString();
    return fallback;
  }

  /// Liste paginée des véhicules (GET /vehicles).
  /// [nearLatitude] / [nearLongitude] : filtre côté API (propriétaire à ≤ [maxDistanceKm] km, défaut 10).
  Future<VehicleListResponse> findAll({
    String? ownerId,
    String? statut,
    int page = 1,
    int limit = 20,
    double? nearLatitude,
    double? nearLongitude,
    double? maxDistanceKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (ownerId != null && ownerId.isNotEmpty) {
        queryParams['ownerId'] = ownerId;
      }
      if (statut != null && statut.isNotEmpty) {
        queryParams['statut'] = statut;
      }
      if (nearLatitude != null &&
          nearLongitude != null &&
          nearLatitude.isFinite &&
          nearLongitude.isFinite) {
        queryParams['latitude'] = nearLatitude.toString();
        queryParams['longitude'] = nearLongitude.toString();
        if (maxDistanceKm != null && maxDistanceKm > 0) {
          queryParams['maxDistanceKm'] = maxDistanceKm.toString();
        }
      }

      final response = await _api.dio.get(
        Endpoints.vehicles,
        queryParameters: queryParams,
      );
      return VehicleListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ??
            'Erreur lors de la récupération des véhicules',
      );
    }
  }

  /// Véhicules d'un propriétaire (GET /vehicles/owner/:ownerId).
  Future<List<Vehicle>> findByOwner(String ownerId) async {
    try {
      final response = await _api.dio.get(
        Endpoints.vehiclesByOwner(ownerId),
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ??
            'Erreur lors de la récupération des véhicules du propriétaire',
      );
    }
  }

  /// Détail d'un véhicule (GET /vehicles/:id).
  Future<Vehicle> findOne(String id) async {
    try {
      final response = await _api.dio.get(Endpoints.vehicleById(id));
      return Vehicle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Véhicule non trouvé');
      }
      throw Exception(
        e.response?.data?['message']?.toString() ??
            'Erreur lors de la récupération du véhicule',
      );
    }
  }

  /// Modifier un véhicule (PATCH /vehicles/:id).
  Future<Vehicle> update(String id, Map<String, dynamic> body) async {
    try {
      final response = await _api.dio.patch(
        Endpoints.vehicleById(id),
        data: body,
      );
      return Vehicle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
          _extractErrorMessage(
            e,
            'Vous n\'avez pas l\'autorisation de modifier ce véhicule.',
          ),
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Véhicule non trouvé');
      }
      if (e.response?.statusCode == 409) {
        throw Exception('Cette immatriculation est déjà enregistrée');
      }
      throw Exception(_extractErrorMessage(e, 'Erreur lors de la mise à jour du véhicule'));
    }
  }

  /// Mettre à jour uniquement le statut d'un véhicule (PATCH /vehicles/:id).
  /// Utilisé par les Chauffeurs solidaires et les Administrateurs.
  Future<Vehicle> updateStatus(String id, VehicleStatut newStatut) async {
    try {
      final response = await _api.dio.patch(
        Endpoints.vehicleById(id),
        data: {'statut': newStatut.toApiString()},
      );
      return Vehicle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
          _extractErrorMessage(
            e,
            'Vous n\'avez pas l\'autorisation de modifier le statut de ce véhicule.',
          ),
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Véhicule non trouvé');
      }
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la mise à jour du statut'),
      );
    }
  }

  /// Supprimer un véhicule (DELETE /vehicles/:id).
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete(Endpoints.vehicleById(id));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Véhicule non trouvé');
      }
      throw Exception(
        e.response?.data?['message']?.toString() ??
            'Erreur lors de la suppression du véhicule',
      );
    }
  }
}
