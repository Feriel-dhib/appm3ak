import 'package:appm3ak/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('fromJson crée un UserModel correctement', () {
      final json = {
        'id': 'abc123',
        'nom': 'Ben Ali',
        'prenom': 'Ahmed',
        'email': 'ahmed@test.com',
        'role': 'HANDICAPE',
        'telephone': '+21612345678',
        'typeHandicap': 'Fauteuil roulant',
        'langue': 'ar',
        'photoProfil': 'photo.jpg',
        'statut': 'ACTIF',
        'animalAssistance': false,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'abc123');
      expect(user.nom, 'Ben Ali');
      expect(user.prenom, 'Ahmed');
      expect(user.email, 'ahmed@test.com');
      expect(user.role, UserRole.handicape);
      expect(user.telephone, '+21612345678');
      expect(user.typeHandicap, 'Fauteuil roulant');
      expect(user.langue, 'ar');
      expect(user.photoProfil, 'photo.jpg');
      expect(user.statut, 'ACTIF');
      expect(user.displayName, 'Ahmed Ben Ali');
      expect(user.contact, '+21612345678');
      expect(user.preferredLanguage, PreferredLanguage.ar);
      expect(user.isBeneficiary, true);
      expect(user.isCompanion, false);
    });

    test('UserRole.fromString parse HANDICAPE et ACCOMPAGNANT', () {
      expect(UserRole.fromString('HANDICAPE'), UserRole.handicape);
      expect(UserRole.fromString('ACCOMPAGNANT'), UserRole.accompagnant);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('invalid'), null);
    });

    test('fromJson accepte _id pour compatibilité', () {
      final json = {
        '_id': 'old-id',
        'nom': 'X',
        'prenom': 'Y',
        'email': 'e@e.com',
        'role': 'ACCOMPAGNANT',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'old-id');
      expect(user.role, UserRole.accompagnant);
      expect(user.isCompanion, true);
    });
  });
}
