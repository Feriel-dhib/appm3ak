import 'package:equatable/equatable.dart';

/// Niveau d'urgence SOS.
enum NiveauUrgenceSos {
  critique,
  haute,
  normale;

  static NiveauUrgenceSos? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    if (v == 'CRITIQUE') return NiveauUrgenceSos.critique;
    if (v == 'HAUTE') return NiveauUrgenceSos.haute;
    if (v == 'NORMALE') return NiveauUrgenceSos.normale;
    return null;
  }

  String toApiString() => name.toUpperCase();
}

/// Alerte SOS.
class SosAlertModel extends Equatable {
  const SosAlertModel({
    required this.id,
    this.userId,
    required this.latitude,
    required this.longitude,
    this.niveauUrgence,
    this.statut,
    this.notifiedContactIds,
    this.voiceScore,
    this.voiceLabel,
    this.voiceLabelFr,
    this.alertSource,
    this.beneficiaryTypeHandicap,
    this.beneficiaryBesoinSpecifique,
    this.createdAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    final notified = json['notifiedContactIds'] as List<dynamic>?;
    return SosAlertModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      niveauUrgence: NiveauUrgenceSos.fromString(json['niveauUrgence'] as String?),
      statut: json['statut'] as String?,
      notifiedContactIds:
          notified?.map((e) => e.toString()).toList(),
      voiceScore: (json['voiceScore'] as num?)?.toDouble(),
      voiceLabel: json['voiceLabel'] as String?,
      voiceLabelFr: json['voiceLabelFr'] as String?,
      alertSource: json['alertSource'] as String?,
      beneficiaryTypeHandicap: json['beneficiaryTypeHandicap'] as String?,
      beneficiaryBesoinSpecifique:
          json['beneficiaryBesoinSpecifique'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final String? userId;
  final double latitude;
  final double longitude;
  final NiveauUrgenceSos? niveauUrgence;
  final String? statut;
  final List<String>? notifiedContactIds;
  final double? voiceScore;
  final String? voiceLabel;
  final String? voiceLabelFr;
  final String? alertSource;
  final String? beneficiaryTypeHandicap;
  final String? beneficiaryBesoinSpecifique;
  final DateTime? createdAt;

  /// Heuristique pour l’écran d’aide haptique (statuts variables selon le backend).
  bool get isEnRoute {
    final s = statut?.toUpperCase() ?? '';
    return s.contains('ROUTE') ||
        s == 'EN_COURS' ||
        s == 'ACCEPTE' ||
        s == 'ACCEPTED' ||
        s == 'PRIS_EN_CHARGE';
  }

  String? get responderSummary => voiceLabelFr ?? voiceLabel;

  String? get reporterSummary =>
      voiceLabelFr ?? voiceLabel ?? beneficiaryTypeHandicap;

  Map<String, dynamic> toCreateJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (niveauUrgence != null) 'niveauUrgence': niveauUrgence!.toApiString(),
      if (voiceScore != null) 'voiceScore': voiceScore,
      if (voiceLabel != null && voiceLabel!.trim().isNotEmpty)
        'voiceLabel': voiceLabel!.trim(),
      if (voiceLabelFr != null && voiceLabelFr!.trim().isNotEmpty)
        'voiceLabelFr': voiceLabelFr!.trim(),
      if (alertSource != null && alertSource!.trim().isNotEmpty)
        'alertSource': alertSource!.trim(),
      if (beneficiaryTypeHandicap != null &&
          beneficiaryTypeHandicap!.trim().isNotEmpty)
        'beneficiaryTypeHandicap': beneficiaryTypeHandicap!.trim(),
      if (beneficiaryBesoinSpecifique != null &&
          beneficiaryBesoinSpecifique!.trim().isNotEmpty)
        'beneficiaryBesoinSpecifique': beneficiaryBesoinSpecifique!.trim(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        statut,
        voiceScore,
        voiceLabel,
        voiceLabelFr,
        alertSource,
      ];
}
