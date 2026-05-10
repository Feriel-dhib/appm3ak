import 'package:equatable/equatable.dart';

import 'accessibilite.dart';
import 'user_model.dart';
import 'vehicle_statut.dart';

/// Modèle Vehicle pour l'API Ma3ak.
class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.accessibilite,
    required this.photos,
    required this.statut,
    this.createdAt,
    this.updatedAt,
    this.owner,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Gérer ownerId qui peut être une string ou un objet User (populate)
    String ownerIdStr;
    UserModel? ownerUser;
    
    if (json['ownerId'] is Map) {
      ownerUser = UserModel.fromJson(json['ownerId'] as Map<String, dynamic>);
      ownerIdStr = ownerUser.id;
    } else {
      ownerIdStr = json['ownerId']?.toString() ?? '';
    }

    return Vehicle(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ownerId: ownerIdStr,
      marque: json['marque']?.toString() ?? '',
      modele: json['modele']?.toString() ?? '',
      immatriculation: json['immatriculation']?.toString() ?? '',
      accessibilite: Accessibilite.fromJson(
        json['accessibilite'] as Map<String, dynamic>? ?? {},
      ),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      statut: VehicleStatut.fromString(json['statut']?.toString()) ??
          VehicleStatut.enAttente,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      owner: ownerUser,
    );
  }

  final String id;
  final String ownerId;
  final String marque;
  final String modele;
  final String immatriculation;
  final Accessibilite accessibilite;
  final List<String> photos;
  final VehicleStatut statut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? owner;

  /// Nom complet du véhicule pour l'affichage.
  String get displayName => '$marque $modele'.trim();

  /// JSON pour la création (POST).
  Map<String, dynamic> toCreateJson() {
    return {
      'ownerId': ownerId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'accessibilite': accessibilite.toJson(),
      'photos': photos,
      if (statut != VehicleStatut.enAttente) 'statut': statut.toApiString(),
    };
  }

  /// JSON pour la mise à jour (PATCH) - seulement les champs modifiés.
  Map<String, dynamic> toUpdateJson({
    String? marque,
    String? modele,
    String? immatriculation,
    Accessibilite? accessibilite,
    List<String>? photos,
    VehicleStatut? statut,
  }) {
    final map = <String, dynamic>{};
    if (marque != null) map['marque'] = marque;
    if (modele != null) map['modele'] = modele;
    if (immatriculation != null) map['immatriculation'] = immatriculation;
    if (accessibilite != null) map['accessibilite'] = accessibilite.toJson();
    if (photos != null) map['photos'] = photos;
    if (statut != null) map['statut'] = statut.toApiString();
    return map;
  }

  Vehicle copyWith({
    String? id,
    String? ownerId,
    String? marque,
    String? modele,
    String? immatriculation,
    Accessibilite? accessibilite,
    List<String>? photos,
    VehicleStatut? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? owner,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      immatriculation: immatriculation ?? this.immatriculation,
      accessibilite: accessibilite ?? this.accessibilite,
      photos: photos ?? this.photos,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        marque,
        modele,
        immatriculation,
        accessibilite,
        photos,
        statut,
        createdAt,
        updatedAt,
      ];
}

/// Réponse paginée pour GET /vehicles.
class VehicleListResponse {
  const VehicleListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory VehicleListResponse.fromJson(Map<String, dynamic> json) {
    return VehicleListResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  final List<Vehicle> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}
