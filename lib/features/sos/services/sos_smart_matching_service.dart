import '../../../data/models/emergency_contact_model.dart';
import '../../../data/models/user_model.dart';
import '../models/safety_risk_models.dart';

/// Décide **qui** contacter selon le niveau de risque + ordre des accompagnants.
class SosSmartMatchingService {
  const SosSmartMatchingService();

  List<MatchingSuggestion> buildSuggestions({
    required SafetyRiskTier tier,
    required List<EmergencyContactModel> contacts,
    UserModel? beneficiary,
  }) {
    final sorted = [...contacts]..sort((a, b) {
      final da = a.accompagnant?.disponible == true ? 0 : 1;
      final db = b.accompagnant?.disponible == true ? 0 : 1;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.ordrePriorite.compareTo(b.ordrePriorite);
    });

    final handicapHint = beneficiary?.typeHandicap ?? '';

    switch (tier) {
      case SafetyRiskTier.calm:
        return [
          const MatchingSuggestion(
            title: 'Veille légère',
            reasonFr:
                'Aucun contact automatique. Vous pouvez prévenir un proche par vous-même si besoin.',
            channel: MatchChannel.sms,
          ),
        ];

      case SafetyRiskTier.lightStress:
        if (sorted.isEmpty) {
          return _fallbackNoContact();
        }
        final c = sorted.first;
        return [
          MatchingSuggestion(
            title: 'Contact de confiance (priorité ${c.ordrePriorite})',
            reasonFr:
                'Stress léger : message ou appel à votre premier accompagnant listé.'
                '${handicapHint.isNotEmpty ? ' — profil : $handicapHint.' : ''}',
            channel: MatchChannel.sms,
            contact: c,
          ),
        ];

      case SafetyRiskTier.mediumDanger:
        if (sorted.isEmpty) {
          return _fallbackNoContact();
        }
        final out = <MatchingSuggestion>[];
        for (var i = 0; i < sorted.length && i < 2; i++) {
          final c = sorted[i];
          out.add(
            MatchingSuggestion(
              title: 'Accompagnant prioritaire ${i + 1}',
              reasonFr:
                  'Danger modéré : notification SMS + appel conseillé. Proximité & disponibilité à affiner côté serveur.',
              channel: MatchChannel.smsAndCall,
              contact: c,
            ),
          );
        }
        out.add(
          const MatchingSuggestion(
            title: 'Bénévoles & pairs (à venir)',
            reasonFr:
                'Matching étendu : bénévoles proches + personnes avec le même type de handicap — nécessite API backend.',
            channel: MatchChannel.sms,
          ),
        );
        return out;

      case SafetyRiskTier.critical:
        final out = <MatchingSuggestion>[];
        for (final c in sorted) {
          out.add(
            MatchingSuggestion(
              title: c.accompagnant?.displayName ?? 'Accompagnant',
              reasonFr:
                  'Urgence grave : tous les contacts d’urgence + localisation.',
              channel: MatchChannel.smsAndCall,
              contact: c,
            ),
          );
        }
        out.add(
          const MatchingSuggestion(
            title: 'Services d’urgence (SAMU / police secours)',
            reasonFr:
                'En cas de danger vital, composez le 190 (Tunisie) ou le numéro local d’urgence.',
            channel: MatchChannel.call,
            isEmergencyServices: true,
          ),
        );
        return out;
    }
  }

  List<MatchingSuggestion> _fallbackNoContact() {
    return [
      const MatchingSuggestion(
        title: 'Aucun accompagnant enregistré',
        reasonFr:
            'Ajoutez des contacts dans Profil → Contacts d’urgence pour activer le matching.',
        channel: MatchChannel.sms,
      ),
    ];
  }
}
