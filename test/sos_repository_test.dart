import 'package:appm3ak/data/repositories/sos_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosRepository.buildCreatePayload', () {
    test('inclut les champs techniques optionnels', () {
      final body = SosRepository.buildCreatePayload(
        latitude: 36.8,
        longitude: 10.18,
        niveauUrgence: 'CRITIQUE',
        voiceScore: 88,
        voiceLabel: 'panic',
        voiceLabelFr: 'Panique',
        alertSource: 'VOICE_AUTO',
        beneficiaryTypeHandicap: 'VISUEL',
        beneficiaryBesoinSpecifique: 'Accompagnement',
      );

      expect(body['latitude'], 36.8);
      expect(body['longitude'], 10.18);
      expect(body['niveauUrgence'], 'CRITIQUE');
      expect(body['voiceScore'], 88);
      expect(body['voiceLabel'], 'panic');
      expect(body['voiceLabelFr'], 'Panique');
      expect(body['alertSource'], 'VOICE_AUTO');
      expect(body['beneficiaryTypeHandicap'], 'VISUEL');
      expect(body['beneficiaryBesoinSpecifique'], 'Accompagnement');
    });

    test('ignore les champs vides', () {
      final body = SosRepository.buildCreatePayload(
        latitude: 36.8,
        longitude: 10.18,
        voiceLabel: '   ',
        alertSource: '',
      );

      expect(body.keys, containsAll(<String>['latitude', 'longitude']));
      expect(body.containsKey('voiceLabel'), false);
      expect(body.containsKey('alertSource'), false);
    });
  });
}
