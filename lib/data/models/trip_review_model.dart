import 'package:equatable/equatable.dart';

/// Évaluation d'un trajet (véhicule + chauffeur) après une réservation terminée.
class TripReviewModel extends Equatable {
  const TripReviewModel({
    required this.id,
    required this.reservationId,
    required this.note,
    this.comment,
    this.vehicleId,
    this.driverId,
    this.createdAt,
  });

  factory TripReviewModel.fromJson(Map<String, dynamic> json) {
    return TripReviewModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      reservationId: json['reservationId']?.toString() ?? json['vehicleReservationId']?.toString() ?? '',
      note: (json['note'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      vehicleId: json['vehicleId']?.toString(),
      driverId: json['driverId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final String reservationId;
  /// Note de 1 à 5.
  final int note;
  final String? comment;
  final String? vehicleId;
  final String? driverId;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'note': note,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (driverId != null) 'driverId': driverId,
      };

  @override
  List<Object?> get props => [id, reservationId, note];
}
