import 'package:equatable/equatable.dart';

import 'type_accompagnant.dart';

/// Rôles utilisateur (nouvelle API).
enum UserRole {
  handicape,
  accompagnant,
  admin;

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    for (final r in UserRole.values) {
      if (r.toApiString() == v) return r;
    }
    return null;
  }

  String toApiString() => name.toUpperCase();
}

/// Langue préférée (ar, fr, etc.).
enum PreferredLanguage {
  ar,
  fr,
  en;

  static PreferredLanguage? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'ar':
        return PreferredLanguage.ar;
      case 'fr':
        return PreferredLanguage.fr;
      case 'en':
        return PreferredLanguage.en;
      default:
        return null;
    }
  }
}

/// Modèle User aligné sur la nouvelle API Ma3ak.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    this.typeHandicap,
    this.besoinSpecifique,
    this.animalAssistance = false,
    this.animalType,
    this.animalName,
    this.animalNotes,
    this.typeAccompagnant,
    this.specialisation,
    this.disponible = false,
    this.noteMoyenne = 0.0,
    this.langue = 'fr',
    this.photoProfil,
    this.statut = 'ACTIF',
    this.latitude,
    this.longitude,
    this.lastLocationAt,
    this.createdAt,
    this.updatedAt,
    this.trustPoints = 0,
    this.isPartenaire = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role']?.toString()) ?? UserRole.handicape,
      telephone: json['telephone'] as String?,
      typeHandicap: json['typeHandicap'] as String?,
      besoinSpecifique: json['besoinSpecifique'] as String?,
      animalAssistance: json['animalAssistance'] as bool? ?? false,
      animalType: json['animalType'] as String?,
      animalName: json['animalName'] as String?,
      animalNotes: json['animalNotes'] as String?,
      typeAccompagnant: json['typeAccompagnant'] as String?,
      specialisation: json['specialisation'] as String?,
      disponible: json['disponible'] as bool? ?? false,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
      langue: json['langue'] as String? ?? 'fr',
      photoProfil: json['photoProfil'] as String?,
      statut: json['statut'] as String? ?? 'ACTIF',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastLocationAt: json['lastLocationAt'] != null
          ? DateTime.tryParse(json['lastLocationAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      trustPoints: (json['trustPoints'] as num?)?.toInt() ?? 0,
      isPartenaire: json['isPartenaire'] as bool? ??
          json['partenaire'] as bool? ??
          false,
    );
  }

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final String? telephone;
  final String? typeHandicap;
  final String? besoinSpecifique;
  final bool animalAssistance;
  /// Valeurs typiques : `chien`, `autre` (API Nest).
  final String? animalType;
  final String? animalName;
  final String? animalNotes;
  final String? typeAccompagnant;
  final String? specialisation;
  final bool disponible;
  final double noteMoyenne;
  final String langue;
  /// URL absolue (OAuth, etc.) ou chemin API `uploads/...` — affichage via [UserRepository.photoUrl].
  final String? photoProfil;
  final String statut;
  /// Dernière position connue (API `/user/me`).
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Points confiance communauté (réputation).
  final int trustPoints;
  /// Compte labellisé partenaire (association, commerce engagé).
  final bool isPartenaire;

  /// Nom complet pour l'affichage.
  String get displayName => '$prenom $nom'.trim();
  /// Contact affiché (téléphone ou email).
  String get contact => telephone ?? email;

  /// Langue préférée pour l'UI (ar/fr).
  PreferredLanguage? get preferredLanguage => PreferredLanguage.fromString(langue);

  bool get isAdmin => role == UserRole.admin;

  /// Alias attendu par l’UI communauté (`post.user?.partenaire`).
  bool get partenaire => isPartenaire;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role.toApiString(),
        'telephone': telephone,
        'typeHandicap': typeHandicap,
        'besoinSpecifique': besoinSpecifique,
        'animalAssistance': animalAssistance,
        'animalType': animalType,
        'animalName': animalName,
        'animalNotes': animalNotes,
        'typeAccompagnant': typeAccompagnant,
        'specialisation': specialisation,
        'disponible': disponible,
        'noteMoyenne': noteMoyenne,
        'langue': langue,
        'photoProfil': photoProfil,
        'statut': statut,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (lastLocationAt != null)
          'lastLocationAt': lastLocationAt!.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'trustPoints': trustPoints,
        'isPartenaire': isPartenaire,
      };

  UserModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    UserRole? role,
    String? telephone,
    String? typeHandicap,
    String? besoinSpecifique,
    bool? animalAssistance,
    String? animalType,
    String? animalName,
    String? animalNotes,
    String? typeAccompagnant,
    String? specialisation,
    bool? disponible,
    double? noteMoyenne,
    String? langue,
    String? photoProfil,
    String? statut,
    double? latitude,
    double? longitude,
    DateTime? lastLocationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trustPoints,
    bool? isPartenaire,
  }) =>
      UserModel(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        role: role ?? this.role,
        telephone: telephone ?? this.telephone,
        typeHandicap: typeHandicap ?? this.typeHandicap,
        besoinSpecifique: besoinSpecifique ?? this.besoinSpecifique,
        animalAssistance: animalAssistance ?? this.animalAssistance,
        animalType: animalType ?? this.animalType,
        animalName: animalName ?? this.animalName,
        animalNotes: animalNotes ?? this.animalNotes,
        typeAccompagnant: typeAccompagnant ?? this.typeAccompagnant,
        specialisation: specialisation ?? this.specialisation,
        disponible: disponible ?? this.disponible,
        noteMoyenne: noteMoyenne ?? this.noteMoyenne,
        langue: langue ?? this.langue,
        photoProfil: photoProfil ?? this.photoProfil,
        statut: statut ?? this.statut,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        lastLocationAt: lastLocationAt ?? this.lastLocationAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        trustPoints: trustPoints ?? this.trustPoints,
        isPartenaire: isPartenaire ?? this.isPartenaire,
      );

  bool get isBeneficiary => role == UserRole.handicape;
  bool get isCompanion => role == UserRole.accompagnant;

  /// Accompagnant « chauffeur solidaire » (seul type autorisé côté app pour le transport pro).
  bool get isChauffeurSolidaire {
    if (!isCompanion || typeAccompagnant == null) return false;
    final a = typeAccompagnant!.toLowerCase().trim();
    final ref = TypeAccompagnant.chauffeursSolidaires.backendValue.toLowerCase().trim();
    return a == ref;
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        prenom,
        email,
        role,
        telephone,
        photoProfil,
        langue,
        latitude,
        longitude,
        trustPoints,
        isPartenaire,
        animalAssistance,
        animalType,
        animalName,
        animalNotes,
      ];
}
