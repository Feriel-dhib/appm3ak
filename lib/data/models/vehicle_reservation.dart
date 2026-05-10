import 'package:equatable/equatable.dart';

import 'user_model.dart';
import 'vehicle.dart';
import 'vehicle_reservation_statut.dart';

/// Réservation de véhicule par un handicapé.
class VehicleReservation extends Equatable {
  const VehicleReservation({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.date,
    required this.heure,
    this.lieuDepart,
    this.lieuDestination,
    this.besoinsSpecifiques,
    this.qrCode,
    required this.statut,
    this.createdAt,
    this.updatedAt,
    this.vehicle,
    this.user,
    this.transportId,
  });

  factory VehicleReservation.fromJson(Map<String, dynamic> json) {
    String userIdStr;
    UserModel? userObj;
    if (json['userId'] is Map) {
      userObj = UserModel.fromJson(json['userId'] as Map<String, dynamic>);
      userIdStr = userObj.id;
    } else {
      userIdStr = json['userId']?.toString() ?? '';
    }

    String vehicleIdStr;
    Vehicle? vehicleObj;
    if (json['vehicleId'] is Map) {
      vehicleObj = Vehicle.fromJson(json['vehicleId'] as Map<String, dynamic>);
      vehicleIdStr = vehicleObj.id;
    } else {
      vehicleIdStr = json['vehicleId']?.toString() ?? '';
    }

    final dateRaw = json['date'];
    DateTime dateParsed;
    if (dateRaw is DateTime) {
      dateParsed = dateRaw;
    } else if (dateRaw is String) {
      dateParsed = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      dateParsed = DateTime.now();
    }

    return VehicleReservation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userIdStr,
      vehicleId: vehicleIdStr,
      date: dateParsed,
      heure: json['heure']?.toString() ?? '',
      lieuDepart: json['lieuDepart']?.toString(),
      lieuDestination: json['lieuDestination']?.toString(),
      besoinsSpecifiques: json['besoinsSpecifiques']?.toString(),
      qrCode: json['qrCode']?.toString(),
      statut: VehicleReservationStatut.fromString(json['statut']?.toString()) ??
          VehicleReservationStatut.enAttente,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      vehicle: vehicleObj,
      user: userObj,
      transportId: _idFromRef(json['transportId']),
    );
  }

  static String? _idFromRef(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return v;
    if (v is Map) {
      return (v['_id'] ?? v['id'])?.toString();
    }
    return v.toString().isEmpty ? null : v.toString();
  }

  final String id;
  final String userId;
  final String vehicleId;
  final DateTime date;
  final String heure;
  final String? lieuDepart;
  final String? lieuDestination;
  final String? besoinsSpecifiques;
  final String? qrCode;
  final VehicleReservationStatut statut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Vehicle? vehicle;
  final UserModel? user;
  /// Course transport liée après création (backend).
  final String? transportId;

  /// Date au format YYYY-MM-DD pour l'API.
  String get dateIso => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toCreateJson() {
    return {
      'vehicleId': vehicleId,
      'date': dateIso,
      'heure': heure,
      if (lieuDepart != null && lieuDepart!.isNotEmpty) 'lieuDepart': lieuDepart,
      if (lieuDestination != null && lieuDestination!.isNotEmpty) 'lieuDestination': lieuDestination,
      if (besoinsSpecifiques != null && besoinsSpecifiques!.isNotEmpty) 'besoinsSpecifiques': besoinsSpecifiques,
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, vehicleId, date, heure, statut, transportId];
}
