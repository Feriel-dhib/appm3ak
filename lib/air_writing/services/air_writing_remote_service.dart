import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/prediction_result.dart';

/// Client pour l'API Air Writing déployée sur Render (FastAPI).
///
/// Le serveur Render free tier dort après ~15 min d'inactivité.
/// [warmUp] envoie un `GET /health` pour le réveiller ; le retry
/// automatique dans [predict] gère le cold start (~30–60 s).
class AirWritingRemoteService {
  AirWritingRemoteService({
    required String baseUrl,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 90),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }
  }

  final Dio _dio;

  final ValueNotifier<bool> serverAwakeNotifier = ValueNotifier<bool>(false);
  bool _warmingUp = false;

  bool get isServerAwake => serverAwakeNotifier.value;
  bool get isWarmingUp => _warmingUp;

  /// Réveille le serveur Render en pingant `/health`.
  /// N'échoue jamais : les erreurs sont absorbées (le prochain [predict]
  /// déclenchera de toute façon un retry).
  Future<void> warmUp() async {
    if (isServerAwake || _warmingUp) return;
    _warmingUp = true;
    try {
      await checkHealth();
    } catch (_) {
      // Cold start : on ne bloque pas l'UI.
    } finally {
      _warmingUp = false;
    }
  }

  /// Vérifie la disponibilité du serveur. Met à jour [isServerAwake].
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final awake = response.statusCode == 200;
      serverAwakeNotifier.value = awake;
      return awake;
    } catch (_) {
      serverAwakeNotifier.value = false;
      return false;
    }
  }

  /// Envoie un JPEG au endpoint `POST /predict` et retourne le résultat.
  ///
  /// [jpegBytes] : image JPEG encodée en bytes.
  /// [alreadyRendered] : `true` si c'est une image 28×28 niveaux de gris
  /// prête pour le CNN (pas de préprocessing serveur).
  /// [minConfidence] : seuil de confiance pour considérer la prédiction valide.
  ///
  /// Retry automatique (3 tentatives) pour gérer le cold start Render.
  Future<PredictionResult?> predict(
    Uint8List jpegBytes, {
    bool alreadyRendered = false,
    double minConfidence = 0.5,
  }) async {
    final b64 = base64Encode(jpegBytes);

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/predict',
          data: <String, dynamic>{
            'image_b64': b64,
            'already_rendered': alreadyRendered,
          },
        );
        serverAwakeNotifier.value = true;
        final data = response.data;
        if (data == null) return null;
        return _parseResponse(data, minConfidence: minConfidence);
      } on DioException catch (e) {
        if (attempt < 2 && _isRetryable(e)) {
          debugPrint(
            '[AirWritingRemote] tentative ${attempt + 1}/3 échouée '
            '(${e.type}), retry dans ${2 * (attempt + 1)}s…',
          );
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        debugPrint('[AirWritingRemote] échec final : $e');
        rethrow;
      }
    }
    return null;
  }

  /// Convertit un tenseur Float32List [0,1] de 784 valeurs (28×28) en JPEG
  /// noir (fond) / blanc (tracé) prêt pour `already_rendered: true`.
  static Uint8List float32ToJpeg(Float32List input784) {
    final image = img.Image(width: 28, height: 28);
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        final v = (input784[y * 28 + x] * 255).round().clamp(0, 255);
        image.setPixelRgb(x, y, v, v, v);
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  PredictionResult _parseResponse(
    Map<String, dynamic> data, {
    required double minConfidence,
  }) {
    final charValue = data['char'] as String;
    final confidence = (data['confidence'] as num).toDouble();
    final top3Raw = data['top3'] as List<dynamic>;

    final topK = top3Raw.asMap().entries.map((entry) {
      final map = entry.value as Map<String, dynamic>;
      return RankedPrediction(
        label: map['char'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        index: entry.key,
      );
    }).toList(growable: false);

    final top1 = RankedPrediction(
      label: charValue,
      confidence: confidence,
      index: 0,
    );

    return PredictionResult(
      top1: top1,
      topK: topK,
      accepted: confidence >= minConfidence,
    );
  }

  bool _isRetryable(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  void dispose() {
    serverAwakeNotifier.dispose();
    _dio.close();
  }
}
