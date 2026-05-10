import 'package:equatable/equatable.dart';

import '../../../data/models/emergency_contact_model.dart';

/// Niveau global après fusion des signaux.
enum SafetyRiskTier {
  calm,
  lightStress,
  mediumDanger,
  critical,
}

extension SafetyRiskTierX on SafetyRiskTier {
  String get labelFr {
    switch (this) {
      case SafetyRiskTier.calm:
        return 'Calme';
      case SafetyRiskTier.lightStress:
        return 'Stress léger';
      case SafetyRiskTier.mediumDanger:
        return 'Danger modéré';
      case SafetyRiskTier.critical:
        return 'Urgence grave';
    }
  }

  String get hintFr {
    switch (this) {
      case SafetyRiskTier.calm:
        return 'Aucune action automatique recommandée.';
      case SafetyRiskTier.lightStress:
        return 'Privilégier un proche ou un message rassurant.';
      case SafetyRiskTier.mediumDanger:
        return 'Notifier vos accompagnants prioritaires.';
      case SafetyRiskTier.critical:
        return 'Tous les contacts + services d’urgence si besoin.';
    }
  }
}

/// Scores individuels 0–100 (plus haut = plus de signal d’alerte).
class SignalScores extends Equatable {
  const SignalScores({
    this.text = 0,
    this.motion = 0,
    this.location = 0,
    this.voiceStress,
  });

  final int text;
  final int motion;
  final int location;
  /// Réservé futur modèle audio (TensorFlow Lite / API native).
  final int? voiceStress;

  @override
  List<Object?> get props => [text, motion, location, voiceStress];
}

/// Résultat de la fusion pondérée.
class FusionResult extends Equatable {
  const FusionResult({
    required this.globalScore,
    required this.tier,
    required this.signals,
    required this.breakdownFr,
  });

  final int globalScore;
  final SafetyRiskTier tier;
  final SignalScores signals;
  final List<String> breakdownFr;

  @override
  List<Object?> get props => [globalScore, tier, signals, breakdownFr];
}

enum MatchChannel { sms, call, smsAndCall }

/// Recommandation de contact (smart matching).
class MatchingSuggestion extends Equatable {
  const MatchingSuggestion({
    required this.title,
    required this.reasonFr,
    required this.channel,
    this.contact,
    this.isEmergencyServices = false,
  });

  final String title;
  final String reasonFr;
  final MatchChannel channel;
  final EmergencyContactModel? contact;
  final bool isEmergencyServices;

  @override
  List<Object?> get props =>
      [title, reasonFr, channel, contact?.id, isEmergencyServices];
}
