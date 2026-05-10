import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/trip_review_model.dart';
import '../models/vehicle_reservation.dart';
import '../models/vehicle_reservation_statut.dart';

class VehicleReservationRepository {
  VehicleReservationRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

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

  /// Créer une réservation (POST /vehicle-reservations).
  Future<VehicleReservation> create(VehicleReservation reservation) async {
    try {
      final response = await _api.dio.post(
        Endpoints.vehicleReservations,
        data: reservation.toCreateJson(),
      );
      return VehicleReservation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(
          _extractErrorMessage(
            e,
            'Ce véhicule n\'est pas disponible à cette date et heure.',
          ),
        );
      }
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la création de la réservation'),
      );
    }
  }

  /// Mes réservations (GET /vehicle-reservations/me).
  Future<List<VehicleReservation>> getMe() async {
    try {
      final response = await _api.dio.get(Endpoints.vehicleReservationsMe);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => VehicleReservation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la récupération des réservations'),
      );
    }
  }

  /// Réservations d'un véhicule (GET /vehicle-reservations/vehicle/:vehicleId).
  Future<List<VehicleReservation>> getByVehicle(String vehicleId) async {
    try {
      final response = await _api.dio
          .get(Endpoints.vehicleReservationsByVehicle(vehicleId));
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => VehicleReservation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la récupération des réservations'),
      );
    }
  }

  /// Détail d'une réservation (GET /vehicle-reservations/:id).
  Future<VehicleReservation> findOne(String id) async {
    try {
      final response = await _api.dio.get(Endpoints.vehicleReservationById(id));
      return VehicleReservation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Réservation non trouvée');
      }
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la récupération de la réservation'),
      );
    }
  }

  /// Mettre à jour le statut (POST /vehicle-reservations/:id/statut).
  Future<VehicleReservation> updateStatut(
    String id,
    VehicleReservationStatut statut,
  ) async {
    try {
      final response = await _api.dio.post(
        Endpoints.vehicleReservationStatut(id),
        data: {'statut': statut.toApiString()},
      );
      return VehicleReservation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la mise à jour du statut'),
      );
    }
  }

  /// Annuler une réservation (DELETE /vehicle-reservations/:id).
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete(Endpoints.vehicleReservationById(id));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Réservation non trouvée');
      }
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de l\'annulation'),
      );
    }
  }

  /// Envoyer une évaluation après trajet (POST /vehicle-reservations/:id/review).
  Future<TripReviewModel> submitReview({
    required String reservationId,
    required int note,
    String? comment,
    String? vehicleId,
    String? driverId,
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.vehicleReservationReview(reservationId),
        data: {
          'note': note,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (vehicleId != null) 'vehicleId': vehicleId,
          if (driverId != null) 'driverId': driverId,
        },
      );
      return TripReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de l\'envoi de l\'évaluation'),
      );
    }
  }

  /// Récupérer l'évaluation du trajet pour une réservation (GET /vehicle-reservations/:id/review).
  Future<TripReviewModel?> getReview(String reservationId) async {
    try {
      final response = await _api.dio.get(
        Endpoints.vehicleReservationReview(reservationId),
      );
      final data = response.data;
      if (data == null) return null;
      return TripReviewModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(
        _extractErrorMessage(e, 'Erreur lors de la récupération de l\'évaluation'),
      );
    }
  }
}
