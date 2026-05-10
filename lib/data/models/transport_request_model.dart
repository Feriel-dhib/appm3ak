import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Profil chauffeur enrichi (ex. GET /transport/:id/suivi).
class DriverInfoModel extends Equatable {
  const DriverInfoModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.noteMoyenne,
    this.typeAccompagnant,
    this.telephone,
    this.photoProfil,
  });

  factory DriverInfoModel.fromJson(Map<String, dynamic> json) {
    return DriverInfoModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      typeAccompagnant: json['typeAccompagnant'] as String?,
      telephone: json['telephone'] as String?,
      photoProfil: json['photoProfil'] as String?,
    );
  }

  final String id;
  final String nom;
  final String prenom;
  final double noteMoyenne;
  final String? typeAccompagnant;
  final String? telephone;
  final String? photoProfil;

  @override
  List<Object?> get props => [id];
}

/// Utilitaires UI / API pour les demandes de transport (libellés statut, couleurs).
abstract class TransportRequestModel {
  TransportRequestModel._();

  static String labelForStatut(String statut) => {
        'EN_ATTENTE': 'En attente d\'un chauffeur',
        'ACCEPTEE': 'Chauffeur assigné',
        'EN_ROUTE': 'Chauffeur en route',
        'ARRIVEE': 'Votre chauffeur est arrivé',
        'EN_COURS': 'Trajet en cours',
        'TERMINEE': 'Trajet terminé',
        'ANNULEE': 'Course annulée',
      }[statut] ??
      statut;

  static Color colorForStatut(String statut) => {
        'EN_ATTENTE': const Color(0xFFFA9F42),
        'ACCEPTEE': const Color(0xFF7F77DD),
        'EN_ROUTE': const Color(0xFF378ADD),
        'ARRIVEE': const Color(0xFF1D9E75),
        'EN_COURS': const Color(0xFF639922),
        'TERMINEE': const Color(0xFF888780),
        'ANNULEE': const Color(0xFFE24B4A),
      }[statut] ??
      const Color(0xFF888780);
}
