import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/medical_record_model.dart';

/// Stockage local hors ligne du dossier médical d'urgence.
class LocalMedicalRecordStore {
  static const _keyMedicalRecord = 'medical_record_local_v1';

  Future<MedicalRecordModel?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMedicalRecord);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MedicalRecordModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(MedicalRecordModel record) async {
    final prefs = await SharedPreferences.getInstance();
    final body = <String, dynamic>{
      'id': record.id,
      ...record.toJson(),
      'createdAt': record.createdAt?.toIso8601String(),
      'updatedAt': record.updatedAt?.toIso8601String(),
    };
    await prefs.setString(_keyMedicalRecord, jsonEncode(body));
  }
}
