import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/sos_alert_model.dart';

class SosRepository {
  SosRepository({required ApiClient apiClient}) : _api = apiClient;

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

  static String _friendlyCreateError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return _extractErrorMessage(
          e,
          'Les informations SOS sont incomplètes. Vérifiez la position et les champs techniques.',
        );
      case 403:
        return 'Accès refusé pour créer une alerte SOS avec ce compte.';
      default:
        return _extractErrorMessage(
          e,
          'Impossible de créer l’alerte SOS pour le moment.',
        );
    }
  }

  static Map<String, dynamic> buildCreatePayload({
    required double latitude,
    required double longitude,
    String? niveauUrgence,
    double? voiceScore,
    String? voiceLabel,
    String? voiceLabelFr,
    String? alertSource,
    String? beneficiaryTypeHandicap,
    String? beneficiaryBesoinSpecifique,
  }) {
    final data = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (niveauUrgence != null && niveauUrgence.isNotEmpty) {
      data['niveauUrgence'] = niveauUrgence;
    }
    if (voiceScore != null) data['voiceScore'] = voiceScore;
    if (voiceLabel != null && voiceLabel.trim().isNotEmpty) {
      data['voiceLabel'] = voiceLabel.trim();
    }
    if (voiceLabelFr != null && voiceLabelFr.trim().isNotEmpty) {
      data['voiceLabelFr'] = voiceLabelFr.trim();
    }
    if (alertSource != null && alertSource.trim().isNotEmpty) {
      data['alertSource'] = alertSource.trim();
    }
    if (beneficiaryTypeHandicap != null &&
        beneficiaryTypeHandicap.trim().isNotEmpty) {
      data['beneficiaryTypeHandicap'] = beneficiaryTypeHandicap.trim();
    }
    if (beneficiaryBesoinSpecifique != null &&
        beneficiaryBesoinSpecifique.trim().isNotEmpty) {
      data['beneficiaryBesoinSpecifique'] = beneficiaryBesoinSpecifique.trim();
    }
    return data;
  }

  /// Créer une alerte SOS (niveauUrgence optionnel : CRITIQUE, HAUTE, NORMALE).
  Future<SosAlertModel> create({
    required double latitude,
    required double longitude,
    String? niveauUrgence,
    double? voiceScore,
    String? voiceLabel,
    String? voiceLabelFr,
    String? alertSource,
    String? beneficiaryTypeHandicap,
    String? beneficiaryBesoinSpecifique,
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.sosAlerts,
        data: buildCreatePayload(
          latitude: latitude,
          longitude: longitude,
          niveauUrgence: niveauUrgence,
          voiceScore: voiceScore,
          voiceLabel: voiceLabel,
          voiceLabelFr: voiceLabelFr,
          alertSource: alertSource,
          beneficiaryTypeHandicap: beneficiaryTypeHandicap,
          beneficiaryBesoinSpecifique: beneficiaryBesoinSpecifique,
        ),
      );
      return SosAlertModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_friendlyCreateError(e));
    }
  }

  /// Notifier le prochain contact urgence (chaîne hiérarchisée).
  Future<NotifyNextResult> notifyNext(String alertId) async {
    final response = await _api.dio.post(
      Endpoints.sosAlertNotifyNext(alertId),
    );
    final msg = response.data is Map
        ? (response.data as Map<String, dynamic>)['message'] as String?
        : null;
    final contactId = response.data is Map
        ? (response.data as Map<String, dynamic>)['contactId'] as String?
        : null;
    return NotifyNextResult(
      message: msg ?? '',
      contactId: contactId,
    );
  }

  /// Répondre / prendre en charge une alerte SOS à proximité.
  Future<void> respond({required String alertId}) async {
    await _api.dio.post(Endpoints.sosAlertRespond(alertId));
  }

  /// Mettre à jour le statut d'une alerte SOS.
  Future<void> updateStatut(String alertId, String statut) async {
    try {
      await _api.dio.post(
        Endpoints.sosAlertStatut(alertId),
        data: {'statut': statut},
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Impossible de mettre à jour le statut SOS.'),
      );
    }
  }

  /// Mes alertes SOS.
  Future<List<SosAlertModel>> getMyAlerts() async {
    try {
      final response = await _api.dio.get(Endpoints.sosAlertsMe);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible de récupérer votre historique SOS.',
        ),
      );
    }
  }

  /// Alertes à proximité.
  Future<List<SosAlertModel>> getNearby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _api.dio.get(
        Endpoints.sosAlertsNearby(latitude, longitude),
      );
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible de charger les alertes SOS à proximité.',
        ),
      );
    }
  }

  /// Alertes SOS reçues pour le compte accompagnant.
  Future<List<SosAlertModel>> getForAccompagnant() async {
    try {
      final response = await _api.dio.get(Endpoints.sosAlertsForAccompagnant);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Cette liste est réservée aux comptes accompagnants.');
      }
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible de charger les SOS reçus pour accompagnant.',
        ),
      );
    }
  }
}

/// Résultat de l'appel notify-next.
class NotifyNextResult {
  const NotifyNextResult({required this.message, this.contactId});
  final String message;
  final String? contactId;
}
