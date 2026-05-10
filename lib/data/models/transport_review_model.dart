import 'package:equatable/equatable.dart';

/// Avis sur un transport terminé — aligné backend `transport-reviews`.
class TransportReviewModel extends Equatable {
  const TransportReviewModel({
    required this.id,
    required this.transportId,
    required this.note,
    this.commentaire,
    this.createdAt,
  });

  factory TransportReviewModel.fromJson(Map<String, dynamic> json) {
    final tid = json['transportId'];
    String transportIdStr = '';
    if (tid is String) {
      transportIdStr = tid;
    } else if (tid is Map<String, dynamic>) {
      transportIdStr =
          (tid['_id'] ?? tid['id'])?.toString() ?? '';
    }

    return TransportReviewModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      transportId: transportIdStr,
      note: (json['note'] as num?)?.toInt() ?? 0,
      commentaire: json['commentaire'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final String transportId;
  final int note;
  final String? commentaire;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}

/// Réponse GET `/transport/:id/price-estimate`.
class TransportPriceEstimate extends Equatable {
  const TransportPriceEstimate({
    required this.transportId,
    required this.distanceKm,
    required this.dureeMinutes,
    required this.prixEstimeTnd,
    this.devise = 'TND',
  });

  factory TransportPriceEstimate.fromJson(Map<String, dynamic> json) {
    return TransportPriceEstimate(
      transportId: json['transportId'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      dureeMinutes: (json['dureeMinutes'] as num?)?.toDouble() ?? 0,
      prixEstimeTnd: (json['prixEstimeTnd'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'TND',
    );
  }

  final String transportId;
  final double distanceKm;
  final double dureeMinutes;
  final double prixEstimeTnd;
  final String devise;

  @override
  List<Object?> get props => [transportId, prixEstimeTnd];
}
