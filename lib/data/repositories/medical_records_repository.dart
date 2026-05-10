import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/companion_medical_record_model.dart';
import '../models/medical_record_model.dart';

class MedicalRecordsRepository {
  MedicalRecordsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Mon dossier médical.
  Future<MedicalRecordModel?> getMe() async {
    try {
      final response = await _api.dio.get(Endpoints.medicalRecordsMe);
      return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Créer mon dossier médical.
  Future<MedicalRecordModel> create({
    String? typeHandicap,
    String? groupeSanguin,
    String? allergies,
    String? maladiesChroniques,
    String? medicaments,
    String? antecedentsImportants,
    String? medecinTraitant,
    String? medecinContact,
    String? contactUrgence,
  }) async {
    final body = <String, dynamic>{};
    if (typeHandicap != null) body['typeHandicap'] = typeHandicap;
    if (groupeSanguin != null) body['groupeSanguin'] = groupeSanguin;
    if (allergies != null) body['allergies'] = allergies;
    if (maladiesChroniques != null)
      body['maladiesChroniques'] = maladiesChroniques;
    if (medicaments != null) body['medicaments'] = medicaments;
    if (antecedentsImportants != null) {
      body['antecedentsImportants'] = antecedentsImportants;
    }
    if (medecinTraitant != null) body['medecinTraitant'] = medecinTraitant;
    if (medecinContact != null) body['medecinContact'] = medecinContact;
    if (contactUrgence != null) body['contactUrgence'] = contactUrgence;

    final response = await _api.dio.post(Endpoints.medicalRecords, data: body);
    return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mettre à jour mon dossier médical.
  Future<MedicalRecordModel> updateMe({
    String? typeHandicap,
    String? groupeSanguin,
    String? allergies,
    String? maladiesChroniques,
    String? medicaments,
    String? antecedentsImportants,
    String? medecinTraitant,
    String? medecinContact,
    String? contactUrgence,
  }) async {
    final body = <String, dynamic>{};
    if (typeHandicap != null) body['typeHandicap'] = typeHandicap;
    if (groupeSanguin != null) body['groupeSanguin'] = groupeSanguin;
    if (allergies != null) body['allergies'] = allergies;
    if (maladiesChroniques != null)
      body['maladiesChroniques'] = maladiesChroniques;
    if (medicaments != null) body['medicaments'] = medicaments;
    if (antecedentsImportants != null) {
      body['antecedentsImportants'] = antecedentsImportants;
    }
    if (medecinTraitant != null) body['medecinTraitant'] = medecinTraitant;
    if (medecinContact != null) body['medecinContact'] = medecinContact;
    if (contactUrgence != null) body['contactUrgence'] = contactUrgence;

    final response = await _api.dio.patch(
      Endpoints.medicalRecordsMe,
      data: body,
    );
    return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Publie le QR médical pour synchronisation vers accompagnants liés.
  Future<void> publishMyQr({
    required String qrPayload,
    DateTime? qrUpdatedAt,
  }) async {
    await _api.dio.post(
      Endpoints.medicalRecordsPublishQr,
      data: {
        'qrPayload': qrPayload,
        'qrUpdatedAt': (qrUpdatedAt ?? DateTime.now()).toIso8601String(),
      },
    );
  }

  /// Côté accompagnant : récupère les dossiers médicaux synchronisés.
  Future<List<CompanionMedicalRecordModel>> getForAccompagnant() async {
    final response = await _api.dio.get(
      Endpoints.medicalRecordsForAccompagnant,
    );
    final raw = response.data;
    final list = switch (raw) {
      List<dynamic> _ => raw,
      Map<String, dynamic> _ when raw['items'] is List<dynamic> =>
        raw['items'] as List<dynamic>,
      Map<String, dynamic> _ when raw['data'] is List<dynamic> =>
        raw['data'] as List<dynamic>,
      _ => <dynamic>[],
    };
    return list
        .whereType<Map<String, dynamic>>()
        .map(CompanionMedicalRecordModel.fromJson)
        .where((e) => e.qrPayload.trim().isNotEmpty)
        .toList();
  }
}
