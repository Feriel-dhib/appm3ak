import 'package:equatable/equatable.dart';

/// Caractéristiques d'accessibilité d'un véhicule.
class Accessibilite extends Equatable {
  const Accessibilite({
    this.coffreVaste = false,
    this.rampeAcces = false,
    this.siegePivotant = false,
    this.climatisation = false,
    this.animalAccepte = false,
  });

  final bool coffreVaste;
  final bool rampeAcces;
  final bool siegePivotant;
  final bool climatisation;
  final bool animalAccepte;

  factory Accessibilite.fromJson(Map<String, dynamic> json) {
    return Accessibilite(
      coffreVaste: json['coffreVaste'] as bool? ?? false,
      rampeAcces: json['rampeAcces'] as bool? ?? false,
      siegePivotant: json['siegePivotant'] as bool? ?? false,
      climatisation: json['climatisation'] as bool? ?? false,
      animalAccepte: json['animalAccepte'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'coffreVaste': coffreVaste,
        'rampeAcces': rampeAcces,
        'siegePivotant': siegePivotant,
        'climatisation': climatisation,
        'animalAccepte': animalAccepte,
      };

  Accessibilite copyWith({
    bool? coffreVaste,
    bool? rampeAcces,
    bool? siegePivotant,
    bool? climatisation,
    bool? animalAccepte,
  }) {
    return Accessibilite(
      coffreVaste: coffreVaste ?? this.coffreVaste,
      rampeAcces: rampeAcces ?? this.rampeAcces,
      siegePivotant: siegePivotant ?? this.siegePivotant,
      climatisation: climatisation ?? this.climatisation,
      animalAccepte: animalAccepte ?? this.animalAccepte,
    );
  }

  @override
  List<Object?> get props => [
        coffreVaste,
        rampeAcces,
        siegePivotant,
        climatisation,
        animalAccepte,
      ];
}
