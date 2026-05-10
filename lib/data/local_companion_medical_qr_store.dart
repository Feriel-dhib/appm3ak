import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/companion_medical_record_model.dart';

/// Fallback local (même appareil) : partage des QR médicaux vers accompagnants liés.
class LocalCompanionMedicalQrStore {
  static const _key = 'companion_medical_qr_sync_v1';

  Future<List<Map<String, dynamic>>> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeRaw(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }

  Future<void> saveForCompanions({
    required String beneficiaryId,
    required String beneficiaryName,
    required String qrPayload,
    required DateTime updatedAt,
    required List<String> companionIds,
  }) async {
    if (beneficiaryId.trim().isEmpty ||
        qrPayload.trim().isEmpty ||
        companionIds.isEmpty) {
      return;
    }
    final cleanCompanionIds = companionIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (cleanCompanionIds.isEmpty) return;
    final items = await _readRaw();
    items.removeWhere(
      (e) =>
          e['beneficiaryId']?.toString() == beneficiaryId &&
          cleanCompanionIds.contains(e['companionId']?.toString()),
    );
    for (final companionId in cleanCompanionIds) {
      items.add({
        'companionId': companionId,
        'beneficiaryId': beneficiaryId,
        'beneficiaryName': beneficiaryName,
        'qrPayload': qrPayload,
        'updatedAt': updatedAt.toIso8601String(),
      });
    }
    await _writeRaw(items);
  }

  Future<List<CompanionMedicalRecordModel>> getForCompanion(
    String companionId,
  ) async {
    final cid = companionId.trim();
    if (cid.isEmpty) return <CompanionMedicalRecordModel>[];
    final items = await _readRaw();
    final filtered =
        items
            .where((e) {
              final stored = e['companionId']?.toString().trim() ?? '';
              return stored == cid || stored == '*';
            })
            .map(
              (e) => CompanionMedicalRecordModel.fromJson({
                'beneficiaryId': e['beneficiaryId'],
                'beneficiaryName': e['beneficiaryName'],
                'qrPayload': e['qrPayload'],
                'updatedAt': e['updatedAt'],
              }),
            )
            .toList()
          ..sort((a, b) {
            final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
    return filtered;
  }
}
