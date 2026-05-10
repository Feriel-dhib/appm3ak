import 'package:appm3ak/core/errors/ai_module_exception.dart';
import 'package:appm3ak/data/api/ai_module_api_client.dart';
import 'package:appm3ak/data/models/ai/adapt_models.dart';
import 'package:appm3ak/data/models/ai/ai_predict_models.dart';
import 'package:appm3ak/data/models/ai/air_click_models.dart';
import 'package:appm3ak/data/repositories/ai_module_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiModuleApiClient extends AiModuleApiClient {
  _FakeAiModuleApiClient() : super(dio: Dio());

  Map<String, dynamic> health = {'status': 'ok'};
  Map<String, dynamic> stt = {'text': 'bonjour'};
  Map<String, dynamic> tts = {'message': 'Text spoken successfully.'};
  Map<String, dynamic> airClick = {'action': 'move'};
  Map<String, dynamic> adapt = {'mode': 'text_mode'};
  Map<String, dynamic> models = {
    'models': ['scanner_pro', 'recognize', 'adaptive_difficulty'],
  };
  Map<String, dynamic> predictResult = {'recommended_difficulty': 2};
  FormData? lastSttFormData;
  FormData? lastPredictFormData;
  Map<String, dynamic>? lastTtsJson;
  Map<String, dynamic>? lastAirClickJson;
  Map<String, dynamic>? lastAdaptJson;
  String? lastModelName;
  Map<String, dynamic>? lastPredictJson;

  @override
  Future<Response<Map<String, dynamic>>> getHealth() async {
    return _response(health);
  }

  @override
  Future<Response<Map<String, dynamic>>> postStt(FormData formData) async {
    lastSttFormData = formData;
    return _response(stt);
  }

  @override
  Future<Response<Map<String, dynamic>>> postTts(
    Map<String, dynamic> json,
  ) async {
    lastTtsJson = json;
    return _response(tts);
  }

  @override
  Future<Response<Map<String, dynamic>>> postAirClick(
    Map<String, dynamic> json,
  ) async {
    lastAirClickJson = json;
    return _response(airClick);
  }

  @override
  Future<Response<Map<String, dynamic>>> postAdapt(
    Map<String, dynamic> json,
  ) async {
    lastAdaptJson = json;
    return _response(adapt);
  }

  @override
  Future<Response<Map<String, dynamic>>> listModels() async {
    return _response(models);
  }

  @override
  Future<Response<Map<String, dynamic>>> predictJson(
    String modelName,
    Map<String, dynamic> payload, {
    Duration sendTimeout = const Duration(seconds: 25),
    Duration receiveTimeout = const Duration(seconds: 45),
  }) async {
    lastModelName = modelName;
    lastPredictJson = payload;
    return _response(predictResult);
  }

  @override
  Future<Response<Map<String, dynamic>>> predictMultipart(
    String modelName,
    FormData payload, {
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) async {
    lastModelName = modelName;
    lastPredictFormData = payload;
    return _response(predictResult);
  }

  Response<Map<String, dynamic>> _response(Map<String, dynamic> data) {
    return Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(path: '/'),
    );
  }
}

void main() {
  group('AiModuleRepository', () {
    test('checks health', () async {
      final fake = _FakeAiModuleApiClient();
      final repo = AiModuleRepository(apiClient: fake);

      expect(await repo.isHealthy(), isTrue);
    });

    test('maps /adapt request and response', () async {
      final fake = _FakeAiModuleApiClient()..adapt = {'mode': 'gesture_mode'};
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.adaptForUserType(AiUserType.motor);

      expect(response.mode, AiInteractionMode.gestureMode);
      expect(fake.lastAdaptJson, {'user_type': 'motor'});
    });

    test('maps /tts request and rejects empty text', () async {
      final fake = _FakeAiModuleApiClient();
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.speakText('  salut  ');

      expect(response.message, 'Text spoken successfully.');
      expect(fake.lastTtsJson, {'text': 'salut'});
      expect(() => repo.speakText(' '), throwsA(isA<AiModuleException>()));
    });

    test('maps /air-click request, response and forwards client_id', () async {
      final fake = _FakeAiModuleApiClient()
        ..airClick = {'action': 'click', 'confidence': 0.9};
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.detectAirClick(
        {
          '4': {'x': 0.1, 'y': 0.1, 'z': 0.0},
          '8': {'x': 0.12, 'y': 0.1, 'z': 0.0},
        },
        clientId: 'device-A',
      );

      expect(response.action, AirClickAction.click);
      expect(response.confidence, 0.9);
      expect(fake.lastAirClickJson?['landmarks'], isA<Map<String, dynamic>>());
      expect(fake.lastAirClickJson?['client_id'], 'device-A');
    });

    test('builds /stt multipart using audio field', () async {
      final fake = _FakeAiModuleApiClient();
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.transcribeAudioFile(
        'test/fixtures/sample.wav',
      );

      expect(response.text, 'bonjour');
      expect(fake.lastSttFormData?.files.single.key, 'audio');
    });

    test('lists available models', () async {
      final fake = _FakeAiModuleApiClient();
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.listModels();

      expect(response.models.map((m) => m.name), contains('scanner_pro'));
      expect(response.models.map((m) => m.name), contains('recognize'));
    });

    test('calls adaptive_difficulty endpoint mapping payload', () async {
      final fake = _FakeAiModuleApiClient()
        ..predictResult = {
          'recommended_difficulty': 3,
          'feedback': 'Excellent',
          'next_exercise_id': 42,
        };
      final repo = AiModuleRepository(apiClient: fake);

      final response = await repo.adaptiveDifficulty(
        const AdaptiveDifficultyRequest(
          avgLast5Scores: 0.72,
          errorsCount: 2,
          successStreak: 4,
          exerciseId: 12,
        ),
      );

      expect(fake.lastModelName, 'adaptive_difficulty');
      expect(fake.lastPredictJson?['avg_last_5_scores'], 0.72);
      expect(response.recommendedDifficulty, 3);
      expect(response.nextExerciseId, 42);
    });
  });
}
