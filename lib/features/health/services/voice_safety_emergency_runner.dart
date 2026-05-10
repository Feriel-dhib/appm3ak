import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/emergency_contact_model.dart';
import '../../../providers/api_providers.dart';
import 'health_voice_lang.dart';
import 'voice_safety_analyzer.dart';
import 'voice_safety_dialer.dart';

/// Enchaîne : API smart matching → sinon contacts locaux → appel téléphonique.
class VoiceSafetyEmergencyRunner {
  VoiceSafetyEmergencyRunner._();

  static DateTime? _cooldownUntil;

  static bool _acquireCooldown() {
    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return false;
    }
    _cooldownUntil = now.add(const Duration(seconds: 60));
    return true;
  }

  /// À appeler uniquement si [VoiceSafetyAnalyzer.isEmergency] est déjà vrai.
  static Future<void> run({
    required WidgetRef ref,
    required String transcript,
    required HealthVoiceLang voiceLang,
    required AppStrings strings,
    void Function(String message)? onNotify,
  }) async {
    if (kIsWeb) return;
    if (!VoiceSafetyAnalyzer.isEmergency(transcript)) return;
    if (!_acquireCooldown()) return;

    onNotify?.call(strings.healthVoiceSafetyDetected);

    final locale = voiceLang == HealthVoiceLang.fr ? 'fr' : 'en';
    String? phone;
    String? name;

    try {
      final repo = ref.read(safetyRepositoryProvider);
      final r = await repo.triggerVoiceEmergency(
        transcript: transcript,
        locale: locale,
      );
      phone = r.primaryPhone;
      name = r.matchedName;
    } catch (_) {
      final picked = await _fallbackFromContacts(ref);
      phone = picked?.$2;
      name = picked?.$1;
    }

    if (phone == null || phone.isEmpty) {
      onNotify?.call(strings.healthVoiceSafetyNoPhone);
      return;
    }

    final label = name != null && name.isNotEmpty ? name : phone;
    onNotify?.call(strings.healthVoiceSafetyCalling(label));

    final ok = await VoiceSafetyDialer.dialEmergency(phone);
    if (!ok) {
      onNotify?.call(strings.healthVoiceSafetyCallFailed);
    }
  }

  static Future<(String name, String phone)?> _fallbackFromContacts(
    WidgetRef ref,
  ) async {
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      final list = await repo.getMyContacts();
      return _pickContact(list);
    } catch (_) {
      return null;
    }
  }

  static (String name, String phone)? _pickContact(
    List<EmergencyContactModel> list,
  ) {
    if (list.isEmpty) return null;
    final sorted = [...list]..sort((a, b) {
        final da = a.accompagnant?.disponible == true ? 0 : 1;
        final db = b.accompagnant?.disponible == true ? 0 : 1;
        final c = da.compareTo(db);
        if (c != 0) return c;
        return a.ordrePriorite.compareTo(b.ordrePriorite);
      });
    for (final c in sorted) {
      final tel = c.accompagnant?.telephone;
      if (tel != null && tel.trim().isNotEmpty) {
        final name = c.accompagnant?.displayName ?? '';
        return (name, tel);
      }
    }
    return null;
  }
}
