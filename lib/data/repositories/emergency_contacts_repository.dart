import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactsRepository {
  EmergencyContactsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static String normalizePhoneForLink(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return cleaned;
    if (cleaned.startsWith('+')) return cleaned;
    // Cas Tunisie fréquent: numéro saisi en 8 chiffres sans indicatif.
    if (RegExp(r'^\d{8}$').hasMatch(cleaned)) {
      return '+216$cleaned';
    }
    return cleaned;
  }

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

  /// Liste des contacts d'urgence (avec accompagnant peuplé).
  Future<List<EmergencyContactModel>> getMyContacts() async {
    try {
      final response = await _api.dio.get(Endpoints.emergencyContactsMe);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible de récupérer les contacts d’urgence.',
        ),
      );
    }
  }

  /// Ajouter un contact d'urgence.
  Future<EmergencyContactModel> add({
    required String accompagnantId,
    int ordrePriorite = 0,
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.emergencyContacts,
        data: {
          'accompagnantId': accompagnantId,
          'ordrePriorite': ordrePriorite,
        },
      );
      return EmergencyContactModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible d’ajouter ce contact d’urgence.',
        ),
      );
    }
  }

  /// Lier un accompagnant existant par téléphone (réservé HANDICAPE).
  Future<EmergencyContactModel> linkByPhone(String telephone) async {
    final normalizedPhone = normalizePhoneForLink(telephone);
    try {
      final response = await _api.dio.post(
        Endpoints.emergencyContactsLinkByPhone,
        data: {'telephone': normalizedPhone},
      );
      return EmergencyContactModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 400:
          throw Exception(
            _extractErrorMessage(
              e,
              'Numéro invalide. Utilisez un format international (ex: +216...).',
            ),
          );
        case 403:
          throw Exception(
            'Cette action est réservée aux comptes bénéficiaires (HANDICAPE).',
          );
        case 404:
          throw Exception(
            _extractErrorMessage(
              e,
              'Aucun accompagnant trouvé avec ce numéro.',
            ),
          );
        default:
          throw Exception(
            _extractErrorMessage(
              e,
              'Impossible de lier ce contact par téléphone.',
            ),
          );
      }
    }
  }

  /// Supprimer un contact d'urgence.
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete(Endpoints.emergencyContactId(id));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Impossible de supprimer ce contact d’urgence.',
        ),
      );
    }
  }
}
