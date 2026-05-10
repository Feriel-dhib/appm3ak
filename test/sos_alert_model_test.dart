import 'package:appm3ak/data/models/sos_alert_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosAlertModel', () {
    test('fromJson lit tous les nouveaux champs optionnels', () {
      final json = <String, dynamic>{
        'id': 's1',
        'userId': 'u1',
        'latitude': 36.8,
        'longitude': 10.18,
        'niveauUrgence': 'HAUTE',
        'statut': 'EN_ATTENTE',
        'voiceScore': 74,
        'voiceLabel': 'high_stress',
        'voiceLabelFr': 'Stress eleve',
        'alertSource': 'VOICE_AUTO',
        'beneficiaryTypeHandicap': 'MOTEUR',
        'beneficiaryBesoinSpecifique': 'Rampe',
      };

      final alert = SosAlertModel.fromJson(json);
      expect(alert.id, 's1');
      expect(alert.userId, 'u1');
      expect(alert.niveauUrgence, NiveauUrgenceSos.haute);
      expect(alert.voiceScore, 74);
      expect(alert.voiceLabel, 'high_stress');
      expect(alert.voiceLabelFr, 'Stress eleve');
      expect(alert.alertSource, 'VOICE_AUTO');
      expect(alert.beneficiaryTypeHandicap, 'MOTEUR');
      expect(alert.beneficiaryBesoinSpecifique, 'Rampe');
    });

    test('toCreateJson inclut uniquement les champs fournis', () {
      const alert = SosAlertModel(
        id: 'tmp',
        latitude: 36.8,
        longitude: 10.18,
        voiceScore: 67,
        alertSource: 'MANUAL',
      );

      final body = alert.toCreateJson();
      expect(body['latitude'], 36.8);
      expect(body['longitude'], 10.18);
      expect(body['voiceScore'], 67);
      expect(body['alertSource'], 'MANUAL');
      expect(body.containsKey('voiceLabelFr'), false);
    });
  });
}
