import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/motif_trajet.dart';
import '../models/transport_history_unified.dart';
import '../models/transport_model.dart';
import '../models/transport_review_model.dart';
import '../models/transport_share_result.dart';

Dio _transportPublicDio() {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: const {'Accept': 'application/json'},
    ),
  );
}

List<TransportMatchingEntry> _parseMatchingList(dynamic data) {
  if (data is! List) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final inner = m['matching'] ?? m['candidates'] ?? m['data'];
      if (inner is List) {
        return _parseMatchingList(inner);
      }
    }
    return [];
  }
  final out = <TransportMatchingEntry>[];
  for (final e in data) {
    try {
      if (e is Map<String, dynamic>) {
        out.add(TransportMatchingEntry.fromJson(e));
      } else if (e is Map) {
        out.add(TransportMatchingEntry.fromJson(Map<String, dynamic>.from(e)));
      }
    } catch (_) {}
  }
  return out;
}

class TransportRepository {
  TransportRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Demandes en attente (pour accompagnants). Backend : priorité médicale, puis urgence, etc.
  Future<List<TransportModel>> getAvailable() async {
    final response = await _api.dio.get(Endpoints.transportAvailable);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mes demandes (asDemandeur, asAccompagnant). Trajets TERMINEE contiennent dureeMinutes et dateHeureArrivee.
  Future<Map<String, List<TransportModel>>> getMe() async {
    final response = await _api.dio.get(Endpoints.transportMe);
    final data = response.data as Map<String, dynamic>? ?? {};
    final asDemandeur = (data['asDemandeur'] as List<dynamic>? ?? [])
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final asAccompagnant = (data['asAccompagnant'] as List<dynamic>? ?? [])
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'asDemandeur': asDemandeur, 'asAccompagnant': asAccompagnant};
  }

  /// Historique unifié (courses + réservations véhicule).
  Future<TransportHistoryPage> getHistory({int page = 1, int limit = 50}) async {
    final response = await _api.dio.get(Endpoints.transportHistory(page: page, limit: limit));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return TransportHistoryPage.fromJson(data);
    }
    if (data is Map) {
      return TransportHistoryPage.fromJson(Map<String, dynamic>.from(data));
    }
    return const TransportHistoryPage(items: []);
  }

  /// Détail d'une demande — GET /transport/:id (demandeur, accompagnant, vehicle peuplés).
  Future<TransportModel> findById(String id) async {
    final response = await _api.dio.get(Endpoints.transportById(id));
    return TransportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Créer une demande. dateHeure obligatoire côté backend (ISO 8601) ; si null, on envoie maintenant (ex. "Immédiat").
  Future<TransportModel> create({
    required String typeTransport,
    String? depart,
    String? destination,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeArrivee,
    double? longitudeArrivee,
    DateTime? dateHeure,
    List<String>? besoinsAssistance,
    String? vehicleId,
    MotifTrajet? motifTrajet,
    bool? prioriteMedicale,
  }) async {
    final body = <String, dynamic>{
      'typeTransport': typeTransport,
      if (depart != null) 'depart': depart,
      if (destination != null) 'destination': destination,
      if (latitudeDepart != null) 'latitudeDepart': latitudeDepart,
      if (longitudeDepart != null) 'longitudeDepart': longitudeDepart,
      if (latitudeArrivee != null) 'latitudeArrivee': latitudeArrivee,
      if (longitudeArrivee != null) 'longitudeArrivee': longitudeArrivee,
      'dateHeure': (dateHeure ?? DateTime.now().toUtc()).toIso8601String(),
      'besoinsAssistance': besoinsAssistance ?? <String>[],
      if (vehicleId != null && vehicleId.isNotEmpty) 'vehicleId': vehicleId,
      if (motifTrajet != null) 'motifTrajet': motifTrajet.apiValue,
      if (prioriteMedicale != null) 'prioriteMedicale': prioriteMedicale,
    };
    final response = await _api.dio.post(Endpoints.transport, data: body);
    return TransportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Matching — GET /transport/matching
  Future<List<TransportMatchingEntry>> getMatching({
    required double latitude,
    required double longitude,
    String? typeHandicap,
    bool urgence = false,
    double? rayonKm,
    List<String>? besoinsAssistance,
    String? typeTransport,
    MotifTrajet? motifTrajet,
    bool? prioriteMedicale,
  }) async {
    final url = Endpoints.transportMatching(
      latitude: latitude,
      longitude: longitude,
      typeHandicap: typeHandicap,
      urgence: urgence,
      rayonKm: rayonKm,
      besoinsAssistance: besoinsAssistance,
    );
    final response = await _api.dio.get(url);
    return _parseMatchingList(response.data);
  }

  /// Matching — POST /transport/matching (mêmes champs, évite une URL trop longue).
  Future<List<TransportMatchingEntry>> postMatching({
    required double latitude,
    required double longitude,
    String? typeHandicap,
    bool urgence = false,
    double? rayonKm,
    List<String>? besoinsAssistance,
    String? typeTransport,
    MotifTrajet? motifTrajet,
    bool? prioriteMedicale,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (typeHandicap != null && typeHandicap.isNotEmpty) 'typeHandicap': typeHandicap,
      'urgence': urgence,
      if (rayonKm != null && rayonKm > 0) 'rayonKm': rayonKm,
      'besoinsAssistance': besoinsAssistance ?? <String>[],
      if (typeTransport != null && typeTransport.isNotEmpty) 'typeTransport': typeTransport,
      if (motifTrajet != null) 'motifTrajet': motifTrajet.apiValue,
      if (prioriteMedicale != null) 'prioriteMedicale': prioriteMedicale,
    };
    final response = await _api.dio.post(Endpoints.transportMatchingPath, data: body);
    return _parseMatchingList(response.data);
  }

  /// Matching à partir d’une demande existante.
  Future<TransportMatchingCandidatesResult> getMatchingCandidates(String transportId) async {
    final response = await _api.dio.get(Endpoints.transportMatchingCandidates(transportId));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return TransportMatchingCandidatesResult.fromJson(data);
    }
    return TransportMatchingCandidatesResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Lien de partage — POST /transport/:id/share
  Future<TransportShareResult> createShare(String transportId) async {
    final response = await _api.dio.post(Endpoints.transportShare(transportId));
    return TransportShareResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> revokeShare(String transportId) async {
    await _api.dio.delete(Endpoints.transportShare(transportId));
  }

  /// Suivi invité (sans JWT).
  Future<TransportSuiviResult> getSuiviPublic(String id, String shareToken) async {
    final dio = _transportPublicDio();
    final q = Uri.encodeQueryComponent(shareToken);
    final response = await dio.get(
      '${Endpoints.transportSuiviPublic(id)}?token=$q',
      options: Options(headers: {'X-Transport-Share-Token': shareToken}),
    );
    return TransportSuiviResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// ETA invité (sans JWT).
  Future<TransportEtaResult> getEtaPublic(String id, String shareToken) async {
    final dio = _transportPublicDio();
    final q = Uri.encodeQueryComponent(shareToken);
    final response = await dio.get(
      '${Endpoints.transportEtaPublic(id)}?token=$q',
      options: Options(headers: {'X-Transport-Share-Token': shareToken}),
    );
    return TransportEtaResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Accepter une demande (accompagnant). Optionnel : scoreMatching, vehicleId, matchingSubscores.
  Future<void> accept(
    String id, {
    double? scoreMatching,
    String? vehicleId,
    Map<String, dynamic>? matchingSubscores,
  }) async {
    final data = <String, dynamic>{};
    if (scoreMatching != null) data['scoreMatching'] = scoreMatching;
    if (vehicleId != null) data['vehicleId'] = vehicleId;
    if (matchingSubscores != null && matchingSubscores.isNotEmpty) {
      data['matchingSubscores'] = matchingSubscores;
    }
    await _api.dio.post(
      Endpoints.transportAccept(id),
      data: data.isNotEmpty ? data : null,
    );
  }

  /// Mise à jour du statut de la course (chauffeur assigné) — POST /transport/:id/statut
  Future<TransportModel> updateStatut(String id, String statut) async {
    final response = await _api.dio.post(
      Endpoints.transportStatut(id),
      data: {'statut': statut},
    );
    return TransportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Marquer le trajet comme terminé — POST /transport/:id/termine
  Future<TransportModel> terminer(String id, {int? dureeMinutes, DateTime? dateHeureArrivee}) async {
    final body = <String, dynamic>{};
    if (dureeMinutes != null) body['dureeMinutes'] = dureeMinutes;
    if (dateHeureArrivee != null) {
      body['dateHeureArrivee'] = dateHeureArrivee.toUtc().toIso8601String();
    }
    final response = await _api.dio.post(
      Endpoints.transportTermine(id),
      data: body.isNotEmpty ? body : null,
    );
    return TransportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// ETA — GET /transport/:id/eta
  Future<TransportEtaResult> getEta(String id) async {
    final response = await _api.dio.get(Endpoints.transportEta(id));
    return TransportEtaResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Suivi en direct — GET /transport/:id/suivi
  Future<TransportSuiviResult> getSuivi(String id) async {
    final response = await _api.dio.get(Endpoints.transportSuivi(id));
    return TransportSuiviResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Estimation distance / durée / prix — GET /transport/:id/price-estimate
  Future<TransportPriceEstimate> getPriceEstimate(String id) async {
    final response = await _api.dio.get(Endpoints.transportPriceEstimate(id));
    return TransportPriceEstimate.fromJson(response.data as Map<String, dynamic>);
  }

  /// Annuler une demande — body optionnel `{ raison }`.
  Future<void> cancel(String id, {String? raison}) async {
    final body = <String, dynamic>{};
    if (raison != null && raison.trim().isNotEmpty) {
      body['raison'] = raison.trim();
    }
    await _api.dio.post(
      Endpoints.transportCancel(id),
      data: body.isNotEmpty ? body : null,
    );
  }

  /// Liste des avis pour un transport — GET /transport-reviews/transport/:id
  Future<List<TransportReviewModel>> getReviewsForTransport(String transportId) async {
    final response = await _api.dio.get(Endpoints.transportReviewsByTransportId(transportId));
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => TransportReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Créer un avis (demandeur, transport TERMINEE) — POST /transport-reviews/transport/:id
  /// Lance [StateError] avec message si réponse 409 (déjà évalué).
  Future<TransportReviewModel> createReview(
    String transportId, {
    required int note,
    String? commentaire,
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.transportReviewsByTransportId(transportId),
        data: {
          'note': note,
          if (commentaire != null && commentaire.trim().isNotEmpty)
            'commentaire': commentaire.trim(),
        },
      );
      return TransportReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw StateError('TRANSPORT_REVIEW_CONFLICT');
      }
      rethrow;
    }
  }
}
