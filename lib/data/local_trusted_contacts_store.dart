import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/emergency_contact_model.dart';
import 'models/local_trusted_contact.dart';
import 'models/user_model.dart';

const _prefsKey = 'local_trusted_contacts_v1';

/// Stockage local des proches (nom + téléphone) pour SOS sans backend.
class LocalTrustedContactsStore {
  Future<List<LocalTrustedContact>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LocalTrustedContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<LocalTrustedContact> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _prefsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// Convertit en [EmergencyContactModel] pour réutiliser le matching / appels.
  static EmergencyContactModel toEmergencyModel(LocalTrustedContact e) {
    final parts = e.displayName.trim().split(RegExp(r'\s+'));
    final prenom = parts.length > 1 ? parts.first : '';
    final nom = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;

    return EmergencyContactModel(
      id: 'local_${e.id}',
      accompagnantId: 'local_${e.id}',
      ordrePriorite: e.priority,
      accompagnant: UserModel(
        id: 'local_${e.id}',
        nom: nom.isEmpty ? e.displayName : nom,
        prenom: prenom,
        email: 'local@device.ma3ak',
        role: UserRole.accompagnant,
        telephone: e.phone,
      ),
    );
  }

  /// Fusionne : **contacts locaux en premier** (priorité), puis API.
  static List<EmergencyContactModel> mergeWithApi(
    List<LocalTrustedContact> local,
    List<EmergencyContactModel> api,
  ) {
    final localModels = local.map(toEmergencyModel).toList();
    final adjustedApi = api
        .map(
          (c) => EmergencyContactModel(
            id: c.id,
            accompagnantId: c.accompagnantId,
            ordrePriorite: 100 + c.ordrePriorite,
            accompagnant: c.accompagnant,
          ),
        )
        .toList();
    final all = [...localModels, ...adjustedApi];
    all.sort((a, b) => a.ordrePriorite.compareTo(b.ordrePriorite));
    return all;
  }
}
