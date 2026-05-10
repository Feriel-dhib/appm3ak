import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Statut d'une relation handicapé–accompagnant.
enum RelationStatut {
  enAttente,
  acceptee;

  static RelationStatut? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase().replaceAll('-', '_');
    if (v == 'EN_ATTENTE') return RelationStatut.enAttente;
    if (v == 'ACCEPTEE') return RelationStatut.acceptee;
    return null;
  }

  String toApiString() {
    switch (this) {
      case RelationStatut.enAttente:
        return 'EN_ATTENTE';
      case RelationStatut.acceptee:
        return 'ACCEPTEE';
    }
  }
}

/// Liaison many-to-many entre un handicapé et un accompagnant.
/// Les champs [handicapId] / [accompagnantId] peuvent être populés (objet User) côté API.
class RelationModel extends Equatable {
  const RelationModel({
    required this.id,
    required this.handicapId,
    required this.accompagnantId,
    required this.statut,
    this.handicapUser,
    this.accompagnantUser,
    this.createdAt,
    this.updatedAt,
  });

  factory RelationModel.fromJson(Map<String, dynamic> json) {
    final rawHandicap = json['handicapId'];
    final rawAccompagnant = json['accompagnantId'];
    String hid = '';
    String aid = '';
    UserModel? handicapUser;
    UserModel? accompagnantUser;

    if (rawHandicap is Map<String, dynamic>) {
      handicapUser = UserModel.fromJson(rawHandicap);
      hid = handicapUser.id;
    } else if (rawHandicap != null) {
      hid = rawHandicap.toString();
    }
    if (rawAccompagnant is Map<String, dynamic>) {
      accompagnantUser = UserModel.fromJson(rawAccompagnant);
      aid = accompagnantUser.id;
    } else if (rawAccompagnant != null) {
      aid = rawAccompagnant.toString();
    }

    return RelationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      handicapId: hid,
      accompagnantId: aid,
      statut: RelationStatut.fromString(json['statut']?.toString()) ?? RelationStatut.enAttente,
      handicapUser: handicapUser,
      accompagnantUser: accompagnantUser,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String handicapId;
  final String accompagnantId;
  final RelationStatut statut;
  final UserModel? handicapUser;
  final UserModel? accompagnantUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Utilisateur handicapé (quand populé par l'API).
  UserModel? get handicap => handicapUser;
  /// Utilisateur accompagnant (quand populé par l'API).
  UserModel? get accompagnant => accompagnantUser;

  bool get isEnAttente => statut == RelationStatut.enAttente;
  bool get isAcceptee => statut == RelationStatut.acceptee;

  @override
  List<Object?> get props => [id, handicapId, accompagnantId, statut];
}
