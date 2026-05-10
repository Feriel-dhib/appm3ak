import 'package:flutter_test/flutter_test.dart';
import 'package:appm3ak/data/models/ai/adapt_models.dart';
import 'package:appm3ak/data/models/ai/ai_predict_models.dart';
import 'package:appm3ak/data/models/ai/air_click_models.dart';
import 'package:appm3ak/data/models/ai/ai_health_response.dart';
import 'package:appm3ak/data/models/ai/stt_response.dart';
import 'package:appm3ak/data/models/ai/tts_request.dart';
import 'package:appm3ak/data/models/ai/tts_response.dart';

void main() {
  group('AI module models', () {
    test('parse health and STT/TTS responses', () {
      expect(AiHealthResponse.fromJson({'status': 'ok'}).isOk, isTrue);
      expect(SttResponse.fromJson({'text': 'bonjour'}).text, 'bonjour');
      expect(
        TtsResponse.fromJson({'message': 'Text spoken successfully.'}).message,
        'Text spoken successfully.',
      );
      expect(TtsRequest(text: 'Salut').toJson(), {'text': 'Salut'});
    });

    test('map adapt user types and modes', () {
      expect(AiUserType.fromJson('blind'), AiUserType.blind);
      expect(AiUserType.fromJson('visuel'), AiUserType.blind);
      expect(AiUserType.fromJson('sourd'), AiUserType.deaf);
      expect(AiUserType.fromJson('moteur'), AiUserType.motor);
      expect(AiUserType.fromJson('unknown'), isNull);

      expect(
        AiInteractionMode.fromJson('voice_mode'),
        AiInteractionMode.voiceMode,
      );
      expect(AiInteractionMode.textMode.toJson(), 'text_mode');
      expect(AiInteractionMode.gestureMode.toJson(), 'gesture_mode');
    });

    test('map air-click actions with safe idle fallback', () {
      expect(AirClickAction.fromJson('click'), AirClickAction.click);
      expect(AirClickAction.fromJson('hold'), AirClickAction.hold);
      expect(AirClickAction.fromJson('move'), AirClickAction.move);
      expect(AirClickAction.fromJson('idle'), AirClickAction.idle);
      // Unknown payloads must default to `idle` (no-op) rather than `move`,
      // otherwise a misdecoded response would silently cycle the focus.
      expect(AirClickAction.fromJson('bad'), AirClickAction.idle);
      expect(AirClickAction.fromJson(null), AirClickAction.idle);
    });

    test('parse air-click response with confidence', () {
      final response = AirClickResponse.fromJson({
        'action': 'click',
        'confidence': 0.42,
      });
      expect(response.action, AirClickAction.click);
      expect(response.confidence, 0.42);

      // Backward compatibility: legacy responses without confidence default
      // to 0.0.
      final legacy = AirClickResponse.fromJson({'action': 'hold'});
      expect(legacy.action, AirClickAction.hold);
      expect(legacy.confidence, 0.0);
    });

    test('air-click request serializes optional client id', () {
      expect(
        AirClickRequest(
          landmarks: {
            '4': {'x': 0.1},
          },
        ).toJson(),
        {
          'landmarks': {
            '4': {'x': 0.1},
          },
        },
      );
      expect(
        AirClickRequest(
          landmarks: {
            '4': {'x': 0.1},
          },
          clientId: 'device-A',
        ).toJson(),
        {
          'landmarks': {
            '4': {'x': 0.1},
          },
          'client_id': 'device-A',
        },
      );
    });

    test('parse AI predict models responses', () {
      final scannerPro = ScannerProResponse.fromJson({
        'known': true,
        'name': 'Ahmed',
        'dominant_emotion': 'calm',
        'stress_score': 0.2,
        'suspicious_signals': ['none'],
      });
      expect(scannerPro.isKnown, isTrue);
      expect(scannerPro.identityLabel, 'Ahmed');

      final sign = SignTextResponse.fromJson({
        'text': 'bonjour aide',
        'sequence': ['BONJOUR', 'AIDE'],
      });
      expect(sign.visualSequence, ['BONJOUR', 'AIDE']);

      final adaptive = AdaptiveDifficultyResponse.fromJson({
        'recommended_difficulty': 2,
        'feedback': 'Continuez',
        'next_exercise_id': 11,
      });
      expect(adaptive.recommendedDifficulty, 2);
      expect(adaptive.nextExerciseId, 11);
    });
  });
}
