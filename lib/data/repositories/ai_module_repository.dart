import 'package:dio/dio.dart';

import '../../core/errors/ai_module_exception.dart';
import '../api/ai_module_api_client.dart';
import '../models/ai/adapt_models.dart';
import '../models/ai/ai_health_response.dart';
import '../models/ai/ai_predict_models.dart';
import '../models/ai/air_click_models.dart';
import '../models/ai/stt_response.dart';
import '../models/ai/tts_request.dart';
import '../models/ai/tts_response.dart';
import '../models/ai/voice_intent_models.dart';

class AiModuleRepository {
  AiModuleRepository({
    required AiModuleApiClient apiClient,
    AiModuleApiClient? secondaryApiClient,
  })  : _apiClient = apiClient,
        _secondaryApiClient = secondaryApiClient;

  final AiModuleApiClient _apiClient;
  final AiModuleApiClient? _secondaryApiClient;

  // Modèles routés vers le backend secondaire (ai-model) s'il est configuré.
  static const Set<String> _secondaryPredictModels = {
    'adaptive_difficulty',
  };

  Future<bool> isHealthy() async {
    try {
      final response = await _apiClient.getHealth();
      return AiHealthResponse.fromJson(_requireJson(response.data)).isOk;
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  /// Réveille l’instance Render (`GET /health`, sans clé) avant STT ou flux dense.
  /// Les erreurs sont ignorées pour ne pas bloquer l’UI si le réseau est capricieux.
  Future<void> prewarmRemoteInstance() async {
    try {
      await _apiClient.getHealth();
    } catch (_) {}
  }

  Future<AiModelsResponse> listModels() async {
    try {
      final response = await _apiClient.listModels();
      return AiModelsResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<SttResponse> transcribeAudioFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final response = await _apiClient.postStt(formData);
      return SttResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<TtsResponse> speakText(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Le texte à prononcer est vide.',
      );
    }
    try {
      final response = await _apiClient.postTts(
        TtsRequest(text: normalized).toJson(),
      );
      return TtsResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<AirClickResponse> detectAirClick(
    Map<String, dynamic> landmarks, {
    String? clientId,
    MotorSensitivity? sensitivity,
  }) async {
    if (landmarks.isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Les landmarks de la main sont absents.',
      );
    }
    try {
      final response = await _apiClient.postAirClick(
        AirClickRequest(
          landmarks: landmarks,
          clientId: clientId,
          sensitivity: sensitivity,
        ).toJson(),
      );
      return AirClickResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  /// Sélection par maintien — l'app envoie périodiquement l'index focalisé,
  /// le backend renvoie quand la durée de maintien dépasse `dwellMs`.
  Future<DwellSelectResponse> dwellSelect(DwellSelectRequest req) async {
    try {
      final response = await _apiClient.postDwellSelect(req.toJson());
      return DwellSelectResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  /// Réinitialise l'état dwell d'un client donné (à appeler après une action).
  Future<void> dwellReset({String? clientId}) async {
    try {
      await _apiClient.postDwellReset({
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      });
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<AdaptResponse> adaptForUserType(AiUserType userType) async {
    try {
      final response = await _apiClient.postAdapt(
        AdaptRequest(userType: userType).toJson(),
      );
      return AdaptResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  /// Demande au backend d'identifier l'intent qui correspond le mieux à un
  /// texte transcrit. Le client peut envoyer son propre catalogue de
  /// commandes (id + mots-clés) ou laisser le backend utiliser ses défauts.
  Future<VoiceIntentResponse> matchVoiceIntent(VoiceIntentRequest req) async {
    if (req.text.trim().isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Texte vide pour /intent.',
      );
    }
    try {
      final response = await _apiClient.postIntent(req.toJson());
      return VoiceIntentResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  /// Construit un résumé court d'un écran (titre + liste de boutons) prêt
  /// à être lu par TTS. Utile pour le mode vocal aveugle.
  Future<ScreenSummaryResponse> summarizeScreen(
    ScreenSummaryRequest req,
  ) async {
    try {
      final response = await _apiClient.postScreenSummary(req.toJson());
      return ScreenSummaryResponse.fromJson(_requireJson(response.data));
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> predict(
    String modelName,
    Map<String, dynamic> payload,
  ) async {
    _ensureModelName(modelName);
    try {
      final client = _selectClientForPredictModel(modelName);
      final response = await client.predictJson(modelName, payload);
      return _requireJson(response.data);
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> predictImageBase64(
    String modelName, {
    required String imageBase64,
    Map<String, dynamic> extraPayload = const {},
  }) async {
    if (imageBase64.trim().isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Image base64 vide.',
      );
    }
    return predict(modelName, <String, dynamic>{
      ...extraPayload,
      'image_base64': imageBase64.trim(),
    });
  }

  Future<Map<String, dynamic>> predictImageMultipart(
    String modelName, {
    required String filePath,
    String fieldName = 'image',
    Map<String, dynamic> extraFields = const {},
  }) async {
    _ensureModelName(modelName);
    if (filePath.trim().isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Chemin image vide.',
      );
    }
    try {
      final form = FormData.fromMap({
        ...extraFields,
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final client = _selectClientForPredictModel(modelName);
      final response = await client.predictMultipart(modelName, form);
      return _requireJson(response.data);
    } on DioException catch (e) {
      throw AiModuleException.fromDio(e);
    }
  }

  Future<ScannerProResponse> scannerProFromBase64(
    String imageBase64, {
    Map<String, dynamic> extraPayload = const {},
  }) async {
    final json = await predictImageBase64(
      'scanner_pro',
      imageBase64: imageBase64,
      extraPayload: extraPayload,
    );
    return ScannerProResponse.fromJson(json);
  }

  Future<RecognizeResponse> recognizeFromBase64(
    String imageBase64, {
    Map<String, dynamic> extraPayload = const {},
  }) async {
    final json = await predictImageBase64(
      'recognize',
      imageBase64: imageBase64,
      extraPayload: extraPayload,
    );
    return RecognizeResponse.fromJson(json);
  }

  Future<ScannerFerResponse> scannerFerFromBase64(
    String imageBase64, {
    bool useClaude = false,
  }) async {
    final json = await predictImageBase64(
      'scanner_fer',
      imageBase64: imageBase64,
      extraPayload: {'use_claude': useClaude},
    );
    return ScannerFerResponse.fromJson(json);
  }

  Future<SignExplainResponse> signExplainFromBase64(String imageBase64) async {
    final json = await predictImageBase64(
      'sign_explain',
      imageBase64: imageBase64,
    );
    return SignExplainResponse.fromJson(json);
  }

  Future<SignTextResponse> signText(String text) async {
    if (text.trim().isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Le texte du signe est vide.',
      );
    }
    final json = await predict('sign_text', {'text': text.trim()});
    return SignTextResponse.fromJson(json);
  }

  Future<AdaptiveDifficultyResponse> adaptiveDifficulty(
    AdaptiveDifficultyRequest request,
  ) async {
    final json = await predict('adaptive_difficulty', request.toJson());
    return AdaptiveDifficultyResponse.fromJson(json);
  }

  Map<String, dynamic> _requireJson(Map<String, dynamic>? data) {
    if (data == null) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Réponse vide du service AI.',
      );
    }
    return data;
  }

  void _ensureModelName(String modelName) {
    if (modelName.trim().isEmpty) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'Nom de modèle IA vide.',
      );
    }
  }

  AiModuleApiClient _selectClientForPredictModel(String modelName) {
    if (_secondaryApiClient != null &&
        _secondaryPredictModels.contains(modelName.trim().toLowerCase())) {
      return _secondaryApiClient;
    }
    return _apiClient;
  }
}
