import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../hand_tracker.dart';
import '../models/prediction_result.dart';
import '../renderer.dart';
import '../trajectory_buffer.dart';
import 'gesture_service.dart';
import 'tflite_service.dart';

class AirWritingConfig {
  const AirWritingConfig({
    this.minConfidence = 0.55,
    this.pauseMs = 1500,
    this.minPoints = 25,
    this.smoothingWindow = 7,
    this.debugLogs = false,
  });

  final double minConfidence;
  final int pauseMs;
  final int minPoints;
  final int smoothingWindow;
  final bool debugLogs;

  AirWritingConfig copyWith({
    double? minConfidence,
    int? pauseMs,
    int? minPoints,
    int? smoothingWindow,
    bool? debugLogs,
  }) {
    return AirWritingConfig(
      minConfidence: minConfidence ?? this.minConfidence,
      pauseMs: pauseMs ?? this.pauseMs,
      minPoints: minPoints ?? this.minPoints,
      smoothingWindow: smoothingWindow ?? this.smoothingWindow,
      debugLogs: debugLogs ?? this.debugLogs,
    );
  }
}

class AirWritingUiState {
  const AirWritingUiState({
    required this.writingActive,
    required this.points,
    required this.indexPoint,
    required this.previewSize,
    required this.pauseProgress,
    required this.fps,
    required this.status,
    this.lastPrediction,
  });

  final bool writingActive;
  final List<Offset> points;
  final Offset? indexPoint;
  final Size? previewSize;
  final double pauseProgress;
  final double fps;
  final String status;
  final PredictionResult? lastPrediction;

  factory AirWritingUiState.initial() {
    return const AirWritingUiState(
      writingActive: false,
      points: <Offset>[],
      indexPoint: null,
      previewSize: null,
      pauseProgress: 0,
      fps: 0,
      status: 'Attente',
      lastPrediction: null,
    );
  }

  AirWritingUiState copyWith({
    bool? writingActive,
    List<Offset>? points,
    Offset? indexPoint,
    bool clearIndexPoint = false,
    Size? previewSize,
    double? pauseProgress,
    double? fps,
    String? status,
    PredictionResult? lastPrediction,
    bool clearPrediction = false,
  }) {
    return AirWritingUiState(
      writingActive: writingActive ?? this.writingActive,
      points: points ?? this.points,
      indexPoint: clearIndexPoint ? null : (indexPoint ?? this.indexPoint),
      previewSize: previewSize ?? this.previewSize,
      pauseProgress: pauseProgress ?? this.pauseProgress,
      fps: fps ?? this.fps,
      status: status ?? this.status,
      lastPrediction: clearPrediction
          ? null
          : (lastPrediction ?? this.lastPrediction),
    );
  }
}

class AirWritingService {
  AirWritingService({
    required HandTracker handTracker,
    required GestureService gestureService,
    required TfliteService tfliteService,
    required AirWritingRenderer renderer,
  }) : _handTracker = handTracker,
       _gestureService = gestureService,
       _tfliteService = tfliteService,
       _renderer = renderer {
    _trajectoryBuffer = _makeBuffer();
  }

  TrajectoryBuffer _makeBuffer() {
    return TrajectoryBuffer(
      pauseThreshold: Duration(milliseconds: _config.pauseMs),
      minPointsForInference: _config.minPoints,
      smoothingWindow: _config.smoothingWindow,
    );
  }

  final HandTracker _handTracker;
  final GestureService _gestureService;
  final TfliteService _tfliteService;
  final AirWritingRenderer _renderer;

  final ValueNotifier<AirWritingUiState> state = ValueNotifier<AirWritingUiState>(
    AirWritingUiState.initial(),
  );
  final StreamController<PredictionResult> _predictionController =
      StreamController<PredictionResult>.broadcast();

  late TrajectoryBuffer _trajectoryBuffer;
  AirWritingConfig _config = const AirWritingConfig();
  bool _processingFrame = false;
  int _frameCounter = 0;
  /// 1 = traiter chaque frame (meilleur suivi doigt ; natif reste le goulot).
  static const int _frameSkip = 1;
  DateTime? _fpsWindowStart;
  int _fpsFrames = 0;

  AirWritingConfig get config => _config;
  Stream<PredictionResult> get predictions => _predictionController.stream;

  void updateConfig(AirWritingConfig config) {
    final rebuildBuffer = config.pauseMs != _config.pauseMs ||
        config.minPoints != _config.minPoints ||
        config.smoothingWindow != _config.smoothingWindow;
    _config = config;
    if (rebuildBuffer) {
      _trajectoryBuffer = _makeBuffer();
      state.value = state.value.copyWith(
        status: 'Paramètres mis à jour',
        points: const <Offset>[],
        clearIndexPoint: true,
        pauseProgress: 0,
      );
    }
  }

  void resetTrajectory() {
    _trajectoryBuffer.reset();
    state.value = state.value.copyWith(
      points: const <Offset>[],
      clearIndexPoint: true,
      pauseProgress: 0,
      status: 'Trajectoire réinitialisée',
    );
  }

  Future<void> onCameraImage(
    CameraImage image,
    CameraController controller,
  ) async {
    if (_processingFrame) return;
    _frameCounter++;
    if (_frameCounter % _frameSkip != 0) return;

    _processingFrame = true;
    try {
      final hand = await _handTracker.detectFromCameraImage(
        image,
        sensorRotation: controller.description.sensorOrientation,
        deviceOrientationName: controller.value.deviceOrientation.name,
        lensDirectionName: controller.description.lensDirection.name,
      );

      _updateFps();
      if (hand == null) {
        state.value = state.value.copyWith(
          writingActive: false,
          clearIndexPoint: true,
          status: 'Aucune main détectée',
          pauseProgress: _trajectoryBuffer.pauseProgress(),
          fps: _currentFps(),
        );
        await _tryInferOnPause();
        return;
      }

      final preview = Size(image.width.toDouble(), image.height.toDouble());
      final isWriting = _gestureService.isWritingGesture(
        hand,
        imageHeight: image.height.toDouble(),
      );
      if (!isWriting) {
        state.value = state.value.copyWith(
          writingActive: false,
          status: 'Main détectée (attente geste)',
          previewSize: preview,
          pauseProgress: _trajectoryBuffer.pauseProgress(),
          fps: _currentFps(),
        );
        await _tryInferOnPause();
        return;
      }

      final tip = hand.indexTip;
      final clamped = Offset(
        tip.dx.clamp(0.0, preview.width),
        tip.dy.clamp(0.0, preview.height),
      );
      final mirrored = Offset(preview.width - clamped.dx, clamped.dy);
      _trajectoryBuffer.add(mirrored);
      if (_config.debugLogs) {
        final n = _trajectoryBuffer.length;
        if (n > 0 && n % 20 == 0) {
          debugPrint('[AirWriting] points accumulés: $n');
        }
      }
      state.value = state.value.copyWith(
        writingActive: true,
        previewSize: preview,
        indexPoint: mirrored,
        points: _trajectoryBuffer.points,
        status: 'Écriture',
        pauseProgress: _trajectoryBuffer.pauseProgress(),
        fps: _currentFps(),
      );
      await _tryInferOnPause();
    } catch (e) {
      state.value = state.value.copyWith(status: 'Erreur pipeline');
      if (_config.debugLogs) {
        debugPrint('[AirWriting] Erreur pipeline: $e');
      }
    } finally {
      _processingFrame = false;
    }
  }

  Future<void> _tryInferOnPause() async {
    if (!_trajectoryBuffer.detectPause()) {
      return;
    }
    if (!_trajectoryBuffer.hasEnoughPoints) {
      if (_config.debugLogs) {
        debugPrint(
          '[AirWriting] Pause sans assez de points (${_trajectoryBuffer.length} < ${_config.minPoints}), reset',
        );
      }
      _trajectoryBuffer.reset();
      state.value = state.value.copyWith(
        points: const <Offset>[],
        clearIndexPoint: true,
        pauseProgress: 0,
        writingActive: false,
        fps: _currentFps(),
      );
      return;
    }
    final count = _trajectoryBuffer.length;
    if (_config.debugLogs) {
      debugPrint('[AirWriting] Pause détectée, points=$count');
    }

    final input = _renderer.renderToFloatList(_trajectoryBuffer.points);
    if (input == null) {
      if (_config.debugLogs) {
        debugPrint('[AirWriting] Rendu 28×28 ignoré (trajectoire trop courte)');
      }
      _trajectoryBuffer.reset();
      state.value = state.value.copyWith(
        points: const <Offset>[],
        clearIndexPoint: true,
        pauseProgress: 0,
        writingActive: false,
        fps: _currentFps(),
      );
      return;
    }
    final prediction = _tfliteService.predict(
      input,
      minConfidence: _config.minConfidence,
      topK: 3,
    );
    if (prediction != null) {
      if (_config.debugLogs) {
        debugPrint(
          '[AirWriting] Prédit=${prediction.top1.label} '
          'conf=${prediction.top1.confidence.toStringAsFixed(3)} '
          'accepted=${prediction.accepted}',
        );
      }
      _predictionController.add(prediction);
      state.value = state.value.copyWith(
        lastPrediction: prediction,
        status: prediction.accepted ? 'Caractère validé' : 'Confiance faible',
      );
    }
    _trajectoryBuffer.reset();
    state.value = state.value.copyWith(
      points: const <Offset>[],
      clearIndexPoint: true,
      pauseProgress: 0,
      writingActive: false,
      fps: _currentFps(),
    );
  }

  void _updateFps() {
    final now = DateTime.now();
    _fpsWindowStart ??= now;
    _fpsFrames++;
    final elapsedMs = now.difference(_fpsWindowStart!).inMilliseconds;
    if (elapsedMs >= 500) {
      final fps = (_fpsFrames * 1000) / elapsedMs;
      state.value = state.value.copyWith(fps: fps);
      _fpsFrames = 0;
      _fpsWindowStart = now;
    }
  }

  double _currentFps() => state.value.fps;

  Future<void> dispose() async {
    await _predictionController.close();
    state.dispose();
  }
}
