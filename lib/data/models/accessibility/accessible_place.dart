import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../location_model.dart';

/// Catégorie générale d'un lieu accessible (utilisée pour les filtres UI).
enum PlaceCategory {
  hopital,
  administration,
  cafe,
  commerce,
  transport,
  autre;

  String get label {
    switch (this) {
      case PlaceCategory.hopital:
        return 'Hôpital';
      case PlaceCategory.administration:
        return 'Administration';
      case PlaceCategory.cafe:
        return 'Café / Restaurant';
      case PlaceCategory.commerce:
        return 'Commerce';
      case PlaceCategory.transport:
        return 'Transport';
      case PlaceCategory.autre:
        return 'Autre';
    }
  }

  static PlaceCategory fromJson(String? raw) {
    switch ((raw ?? 'autre').toLowerCase().trim()) {
      case 'hopital':
        return PlaceCategory.hopital;
      case 'administration':
        return PlaceCategory.administration;
      case 'cafe':
        return PlaceCategory.cafe;
      case 'commerce':
        return PlaceCategory.commerce;
      case 'transport':
        return PlaceCategory.transport;
      default:
        return PlaceCategory.autre;
    }
  }
}

/// Type de handicap auquel un lieu est déclaré adapté.
enum DisabilityType {
  moteur,
  visuel,
  auditif,
  cognitif;

  String get label {
    switch (this) {
      case DisabilityType.moteur:
        return 'Mobilité';
      case DisabilityType.visuel:
        return 'Vision';
      case DisabilityType.auditif:
        return 'Audition';
      case DisabilityType.cognitif:
        return 'Cognitif';
    }
  }

  static DisabilityType? fromJson(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'moteur':
        return DisabilityType.moteur;
      case 'visuel':
        return DisabilityType.visuel;
      case 'auditif':
        return DisabilityType.auditif;
      case 'cognitif':
        return DisabilityType.cognitif;
      default:
        return null;
    }
  }
}

/// Représente un lieu accessible (hôpital, administration, café, transport…).
///
/// Alimenté soit depuis `assets/places.json` (catalogue statique), soit depuis
/// un futur endpoint backend `/lieux` (déjà prévu dans [Endpoints.lieux]).
class AccessiblePlace extends Equatable {
  const AccessiblePlace({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.wheelchairAccess,
    required this.elevator,
    required this.braille,
    required this.audioAssistance,
    required this.accessibleToilets,
    required this.accessibilityScore,
    required this.description,
    required this.category,
    required this.adaptedFor,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final bool wheelchairAccess;
  final bool elevator;
  final bool braille;
  final bool audioAssistance;
  final bool accessibleToilets;

  /// Score statique fourni par le catalogue (0–100). Complémentaire du score
  /// IA temps réel obtenu via `/accessibility/analyze`.
  final int accessibilityScore;
  final String description;
  final PlaceCategory category;
  final Set<DisabilityType> adaptedFor;
  final double distanceKm;

  factory AccessiblePlace.fromJson(Map<String, dynamic> json) {
    final adapted = <DisabilityType>{};
    final raw = json['adaptedFor'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String) {
          final t = DisabilityType.fromJson(e);
          if (t != null) adapted.add(t);
        }
      }
    }
    return AccessiblePlace(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      wheelchairAccess: json['wheelchairAccess'] as bool? ?? false,
      elevator: json['elevator'] as bool? ?? false,
      braille: json['braille'] as bool? ?? false,
      audioAssistance: json['audioAssistance'] as bool? ?? false,
      accessibleToilets: json['accessibleToilets'] as bool? ?? false,
      accessibilityScore:
          ((json['accessibilityScore'] as num?)?.toInt() ?? 0).clamp(0, 100),
      description: json['description'] as String? ?? '',
      category: PlaceCategory.fromJson(json['category'] as String?),
      adaptedFor: adapted,
      distanceKm: _asDouble(json['distanceKm']),
    );
  }

  /// Charge le catalogue depuis un asset JSON (format `{ "places": [...] }`).
  static Future<List<AccessiblePlace>> loadFromAsset(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON racine : objet attendu');
    }
    final list = decoded['places'];
    if (list is! List) {
      throw const FormatException('Clé "places" : tableau attendu');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(AccessiblePlace.fromJson)
        .toList(growable: false);
  }

  /// Carte un [LocationModel] API `/lieux` vers le format catalogue accessibilité.
  factory AccessiblePlace.fromLocation(LocationModel m) {
    final score = (m.scoreAccessibilite ?? 0).clamp(0, 100);
    final desc = (m.description ?? m.aiSummary ?? '').trim();
    final amenities = m.amenities ?? const <String>[];
    bool has(String needle) => amenities.any(
          (a) => a.toLowerCase().contains(needle),
        );

    var wheelchair = has('wheel') || has('fauteuil') || has('ramp');
    var elevator = has('elev') || has('ascenseur');
    final braille = has('braille');
    final audio = has('audio') || has('boucle') || has('hearing');
    final toilets = has('toilet') || has('wc') || has('sanitaire');

    if (m.categorie == LocationCategory.hospital) {
      elevator = elevator || true;
      wheelchair = wheelchair || score >= 50;
    }

    final adapted = <DisabilityType>{};
    if (has('moteur') || wheelchair) {
      adapted.add(DisabilityType.moteur);
    }
    if (has('visuel') || has('cecit') || braille) {
      adapted.add(DisabilityType.visuel);
    }
    if (has('auditif') || has('sourd') || audio) {
      adapted.add(DisabilityType.auditif);
    }
    if (has('cognitif')) {
      adapted.add(DisabilityType.cognitif);
    }
    if (adapted.isEmpty) {
      adapted.add(DisabilityType.moteur);
    }

    return AccessiblePlace(
      id: m.id,
      name: m.nom,
      city: m.ville,
      latitude: m.latitude,
      longitude: m.longitude,
      wheelchairAccess: wheelchair,
      elevator: elevator,
      braille: braille,
      audioAssistance: audio,
      accessibleToilets: toilets || m.categorie == LocationCategory.hospital,
      accessibilityScore: score,
      description: desc.isEmpty ? m.fullAddress : desc,
      category: _placeCategoryFromLocationCategory(m.categorie),
      adaptedFor: adapted,
      distanceKm: 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        city,
        latitude,
        longitude,
        wheelchairAccess,
        elevator,
        braille,
        audioAssistance,
        accessibleToilets,
        accessibilityScore,
        description,
        category,
        adaptedFor,
        distanceKm,
      ];
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

PlaceCategory _placeCategoryFromLocationCategory(LocationCategory c) {
  switch (c) {
    case LocationCategory.hospital:
      return PlaceCategory.hopital;
    case LocationCategory.restaurant:
      return PlaceCategory.cafe;
    case LocationCategory.pharmacy:
    case LocationCategory.shop:
      return PlaceCategory.commerce;
    case LocationCategory.publicTransport:
      return PlaceCategory.transport;
    case LocationCategory.school:
    case LocationCategory.park:
    case LocationCategory.other:
      return PlaceCategory.autre;
  }
}
