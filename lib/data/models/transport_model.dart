import 'package:equatable/equatable.dart';

import 'motif_trajet.dart';
import 'transport_request_model.dart' show DriverInfoModel;
import 'user_model.dart';
import 'vehicle.dart';

UserModel? _userFromRef(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return UserModel.fromJson(raw);
  }
  return null;
}

String? _refIdString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is Map) {
    return (v['_id'] ?? v['id'])?.toString();
  }
  return v.toString();
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toDouble();
  }
  return null;
}

bool? _readBoolLoose(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  return null;
}

/// Type de demande de transport.
enum TransportType {
  urgence,
  quotidien;

  static TransportType? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    if (v == 'URGENCE') return TransportType.urgence;
    if (v == 'QUOTIDIEN') return TransportType.quotidien;
    return null;
  }

  String toApiString() => name.toUpperCase();
}

/// Demande de transport (aligné backend).
class TransportModel extends Equatable {
  const TransportModel({
    required this.id,
    required this.typeTransport,
    this.depart,
    this.destination,
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeArrivee,
    this.longitudeArrivee,
    this.dateHeure,
    this.statut,
    this.demandeur,
    this.accompagnant,
    this.demandeurIdString,
    this.accompagnantIdString,
    this.vehicleId,
    this.vehicle,
    this.besoinsAssistance,
    this.scoreMatching,
    this.dateHeureArrivee,
    this.dureeMinutes,
    this.distanceEstimeeKm,
    this.dureeEstimeeMinutes,
    this.prixEstimeTnd,
    this.prixFinalTnd,
    this.createdAt,
    this.driverCurrentLat,
    this.driverCurrentLng,
    this.statutLabel,
    this.driver,
    this.vehicleReservationId,
    this.motifTrajet,
    this.prioriteMedicale,
  });

  factory TransportModel.fromJson(Map<String, dynamic> json) {
    Vehicle? vehicle;
    if (json['vehicle'] != null || json['vehicleId'] is Map) {
      try {
        vehicle = Vehicle.fromJson(
          (json['vehicle'] ?? json['vehicleId']) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    List<String>? besoinsAssistance;
    if (json['besoinsAssistance'] is List) {
      besoinsAssistance = (json['besoinsAssistance'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    final demandeur = _userFromRef(json['demandeur']) ??
        _userFromRef(json['demandeurId']);
    final accompagnant = _userFromRef(json['accompagnant']) ??
        _userFromRef(json['accompagnantId']);

    DriverInfoModel? driver;
    if (json['driver'] is Map<String, dynamic>) {
      driver = DriverInfoModel.fromJson(json['driver'] as Map<String, dynamic>);
    }

    return TransportModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      typeTransport: TransportType.fromString(json['typeTransport']?.toString()) ??
          TransportType.quotidien,
      depart: json['depart'] as String?,
      destination: json['destination'] as String?,
      latitudeDepart: (json['latitudeDepart'] as num?)?.toDouble(),
      longitudeDepart: (json['longitudeDepart'] as num?)?.toDouble(),
      latitudeArrivee: (json['latitudeArrivee'] as num?)?.toDouble(),
      longitudeArrivee: (json['longitudeArrivee'] as num?)?.toDouble(),
      dateHeure: json['dateHeure'] != null
          ? DateTime.tryParse(json['dateHeure'].toString())
          : null,
      statut: json['statut'] as String?,
      demandeur: demandeur,
      accompagnant: accompagnant,
      demandeurIdString: _refIdString(json['demandeurId']) ?? demandeur?.id,
      accompagnantIdString: _refIdString(json['accompagnantId']) ?? accompagnant?.id,
      vehicleId: json['vehicleId'] is String
          ? json['vehicleId'] as String
          : (json['vehicleId']?['_id'] ?? json['vehicleId']?['id'])?.toString(),
      vehicle: vehicle,
      besoinsAssistance: besoinsAssistance,
      scoreMatching: (json['scoreMatching'] as num?)?.toDouble(),
      dateHeureArrivee: json['dateHeureArrivee'] != null
          ? DateTime.tryParse(json['dateHeureArrivee'].toString())
          : null,
      dureeMinutes: (json['dureeMinutes'] as num?)?.toInt(),
      distanceEstimeeKm: (json['distanceEstimeeKm'] as num?)?.toDouble(),
      dureeEstimeeMinutes: (json['dureeEstimeeMinutes'] as num?)?.toDouble(),
      prixEstimeTnd: (json['prixEstimeTnd'] as num?)?.toDouble(),
      prixFinalTnd: (json['prixFinalTnd'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      driverCurrentLat: _readDouble(json, ['driverCurrentLat', 'driver_current_lat']),
      driverCurrentLng: _readDouble(json, ['driverCurrentLng', 'driver_current_lng']),
      statutLabel: json['statutLabel'] as String?,
      driver: driver,
      vehicleReservationId: _refIdString(json['vehicleReservationId']),
      motifTrajet: MotifTrajet.fromApi(json['motifTrajet']?.toString()),
      prioriteMedicale: _readBoolLoose(json['prioriteMedicale']),
    );
  }

  final String id;
  final TransportType typeTransport;
  final String? depart;
  final String? destination;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeArrivee;
  final double? longitudeArrivee;
  final DateTime? dateHeure;
  final String? statut;
  final UserModel? demandeur;
  final UserModel? accompagnant;
  /// ID brut demandeur (même si pas peuplé).
  final String? demandeurIdString;
  /// ID brut accompagnant (même si pas peuplé).
  final String? accompagnantIdString;
  final String? vehicleId;
  final Vehicle? vehicle;
  final List<String>? besoinsAssistance;
  final double? scoreMatching;
  final DateTime? dateHeureArrivee;
  final int? dureeMinutes;
  final double? distanceEstimeeKm;
  final double? dureeEstimeeMinutes;
  final double? prixEstimeTnd;
  final double? prixFinalTnd;
  final DateTime? createdAt;
  /// Position live du chauffeur (WebSocket / API).
  final double? driverCurrentLat;
  final double? driverCurrentLng;
  final String? statutLabel;
  final DriverInfoModel? driver;
  /// Présent si la course provient d’une réservation véhicule (liaison backend).
  final String? vehicleReservationId;
  final MotifTrajet? motifTrajet;
  final bool? prioriteMedicale;

  bool get isFromVehicleReservation =>
      vehicleReservationId != null && vehicleReservationId!.isNotEmpty;

  bool get isAcceptee => statut == 'ACCEPTEE';
  bool get isTerminee => statut == 'TERMINEE';
  bool get isAnnulee => statut == 'ANNULEE';

  /// Course en cours côté API (ETA / suivi).
  bool get isActiveTrip {
    const s = {
      'ACCEPTEE',
      'EN_ROUTE',
      'ARRIVEE',
      'EN_COURS',
    };
    return statut != null && s.contains(statut);
  }

  /// Peut appeler POST /termine.
  bool get canTerminate {
    const s = {'ACCEPTEE', 'EN_ROUTE', 'ARRIVEE', 'EN_COURS'};
    return statut != null && s.contains(statut);
  }

  bool isDemandeurUser(UserModel u) =>
      demandeur?.id == u.id ||
      (demandeurIdString != null && demandeurIdString == u.id);

  bool isAssignedDriver(UserModel u) =>
      accompagnant?.id == u.id ||
      (accompagnantIdString != null && accompagnantIdString == u.id);

  @override
  List<Object?> get props => [id];
}

/// Réponse ETA — GET /transport/:id/eta
class TransportEtaResult extends Equatable {
  const TransportEtaResult({
    required this.distanceKm,
    required this.dureeMinutes,
    this.vitesseKmhUtilisee,
  });

  factory TransportEtaResult.fromJson(Map<String, dynamic> json) {
    return TransportEtaResult(
      distanceKm: _readDouble(json, ['distance_km', 'distanceKm']) ?? 0,
      dureeMinutes: _readDouble(json, ['duree_minutes', 'dureeMinutes']) ?? 0,
      vitesseKmhUtilisee: _readDouble(
        json,
        ['vitesse_kmh_utilisee', 'vitesseKmhUtilisee'],
      ),
    );
  }

  final double distanceKm;
  final double dureeMinutes;
  final double? vitesseKmhUtilisee;

  @override
  List<Object?> get props => [distanceKm, dureeMinutes];
}

/// Réponse Suivi — GET /transport/:id/suivi
class TransportSuiviResult extends Equatable {
  const TransportSuiviResult({
    this.transport,
    this.positionChauffeur,
    this.eta,
    this.itineraire,
    this.cible,
    this.driver,
    this.statutLabel,
    this.statut,
  });

  factory TransportSuiviResult.fromJson(Map<String, dynamic> json) {
    TransportModel? transport;
    if (json['transport'] != null) {
      transport = TransportModel.fromJson(json['transport'] as Map<String, dynamic>);
    }
    Map<String, double>? positionChauffeur;
    if (json['positionChauffeur'] is Map) {
      final p = json['positionChauffeur'] as Map<String, dynamic>;
      positionChauffeur = {
        'lat': (p['lat'] as num?)?.toDouble() ?? 0,
        'lon': (p['lon'] as num?)?.toDouble() ?? 0,
      };
    }
    TransportEtaResult? eta;
    if (json['eta'] != null) {
      eta = TransportEtaResult.fromJson(json['eta'] as Map<String, dynamic>);
    }
    Map<String, dynamic>? itineraire;
    if (json['itineraire'] is Map) {
      itineraire = json['itineraire'] as Map<String, dynamic>;
    }
    DriverInfoModel? driver;
    if (json['driver'] is Map<String, dynamic>) {
      driver = DriverInfoModel.fromJson(json['driver'] as Map<String, dynamic>);
    }
    final statutLabel = json['statutLabel'] as String?;
    final statutBrut = json['statut'] as String? ?? transport?.statut;
    return TransportSuiviResult(
      transport: transport,
      positionChauffeur: positionChauffeur,
      eta: eta,
      itineraire: itineraire,
      cible: json['cible'] as String?,
      driver: driver,
      statutLabel: statutLabel,
      statut: statutBrut,
    );
  }

  final TransportModel? transport;
  final Map<String, double>? positionChauffeur;
  final TransportEtaResult? eta;
  final Map<String, dynamic>? itineraire;
  /// `POINT_DEPART` ou `DESTINATION` (backend).
  final String? cible;
  /// Chauffeur détaillé (réponse suivi enrichie).
  final DriverInfoModel? driver;
  final String? statutLabel;
  /// Statut courant du trajet (racine JSON ou transport).
  final String? statut;

  @override
  List<Object?> get props => [transport?.id];
}

/// Un accompagnant proposé par le matching (Nest : camelCase ; Flask éventuel : snake_case).
class TransportMatchingEntry extends Equatable {
  const TransportMatchingEntry({
    required this.user,
    this.distanceKm,
    this.score,
    this.scoreMatching,
    this.etaMinutes,
    this.matchingSubscores,
    this.vehicles,
    this.recommendedVehicle,
  });

  factory TransportMatchingEntry.fromJson(Map<String, dynamic> json) {
    UserModel user;
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['accompagnant'] != null) {
      user = UserModel.fromJson(json['accompagnant'] as Map<String, dynamic>);
    } else {
      user = UserModel.fromJson(json);
    }
    final dist = _readDouble(json, ['distanceKm', 'distance_km']);
    final scoreMatching = _readDouble(json, ['scoreMatching', 'score_matching']);
    final scoreTop = _readDouble(json, ['score', 'Score']);
    final eta = _readDouble(json, ['etaMinutes', 'eta_minutes']);
    Map<String, dynamic>? sub;
    final ms = json['matchingSubscores'] ?? json['subscores'];
    if (ms is Map) {
      sub = Map<String, dynamic>.from(ms);
    }
    List<Vehicle>? vehicles;
    if (json['vehicles'] is List) {
      vehicles = [];
      for (final v in json['vehicles'] as List<dynamic>) {
        if (v is Map<String, dynamic>) {
          try {
            vehicles.add(Vehicle.fromJson(v));
          } catch (_) {}
        } else if (v is Map) {
          try {
            vehicles.add(Vehicle.fromJson(Map<String, dynamic>.from(v)));
          } catch (_) {}
        }
      }
      if (vehicles.isEmpty) vehicles = null;
    }
    Vehicle? recommendedVehicle;
    final rv = json['recommendedVehicle'];
    if (rv is Map<String, dynamic>) {
      try {
        recommendedVehicle = Vehicle.fromJson(rv);
      } catch (_) {}
    } else if (rv is Map) {
      try {
        recommendedVehicle = Vehicle.fromJson(Map<String, dynamic>.from(rv));
      } catch (_) {}
    }
    return TransportMatchingEntry(
      user: user,
      distanceKm: dist,
      score: scoreTop ?? scoreMatching,
      scoreMatching: scoreMatching ?? scoreTop,
      etaMinutes: eta?.round(),
      matchingSubscores: sub,
      vehicles: vehicles,
      recommendedVehicle: recommendedVehicle,
    );
  }

  final UserModel user;
  final double? distanceKm;
  /// Score global affiché (alias possible de [scoreMatching]).
  final double? score;
  final double? scoreMatching;
  final int? etaMinutes;
  final Map<String, dynamic>? matchingSubscores;
  final List<Vehicle>? vehicles;
  final Vehicle? recommendedVehicle;

  @override
  List<Object?> get props => [user.id];
}

/// Réponse `GET /transport/:id/matching-candidates`.
class TransportMatchingCandidatesResult extends Equatable {
  const TransportMatchingCandidatesResult({
    required this.transportId,
    required this.matching,
  });

  factory TransportMatchingCandidatesResult.fromJson(Map<String, dynamic> json) {
    final id = json['transportId']?.toString() ?? json['transport_id']?.toString() ?? '';
    final raw = json['matching'] as List<dynamic>? ?? json['candidates'] as List<dynamic>? ?? [];
    final list = <TransportMatchingEntry>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        try {
          list.add(TransportMatchingEntry.fromJson(e));
        } catch (_) {}
      } else if (e is Map) {
        try {
          list.add(TransportMatchingEntry.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    return TransportMatchingCandidatesResult(transportId: id, matching: list);
  }

  final String transportId;
  final List<TransportMatchingEntry> matching;

  @override
  List<Object?> get props => [transportId, matching.length];
}
