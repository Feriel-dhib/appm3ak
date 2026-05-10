import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/detection_config.dart';
import 'detection_isolate.dart';
import 'yuv_converter.dart';
import 'yolo_tflite_runner.dart';

/// Service d'inférence YOLOv8 TFLite : isolate dédié, throttling, YUV/BGRA → RGB [DetectionConfig]².
class YoloTfliteService {
  YoloTfliteService();

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _receivePort;
  Completer<InferenceOutput>? _pendingCompleter;
  bool _disposed = false;

  /// Délai minimum entre deux inférences pour viser ~15–30 FPS.
  static const Duration throttleDuration = Duration(milliseconds: 50);

  DateTime? _lastInferenceTime;
  bool _isProcessing = false;

  bool get isInitialized => _isolateSendPort != null;
  bool get isProcessing => _isProcessing;

  /// Initialise le service : charge le modèle et lance l'isolate.
  Future<void> initialize() async {
    if (_isolateSendPort != null) return;

    final modelBytes = await rootBundle.load(DetectionConfig.modelAssetPath);
    final buffer = modelBytes.buffer.asUint8List(
      modelBytes.offsetInBytes,
      modelBytes.lengthInBytes,
    );

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      detectionIsolateEntry,
      receivePort.sendPort,
      errorsAreFatal: false,
    );

    final completer = Completer<SendPort>();
    final initAck = Completer<void>();
    receivePort.listen((dynamic message) {
      if (message is SendPort) {
        if (!completer.isCompleted) completer.complete(message);
        return;
      }
      if (message is InferenceOutput) {
        if (!initAck.isCompleted) {
          initAck.complete();
          return;
        }
        if (_pendingCompleter != null) {
          _pendingCompleter!.complete(message);
          _pendingCompleter = null;
          _isProcessing = false;
        }
      }
    });
    _receivePort = receivePort;

    final isolateSendPort = await completer.future;
    _isolateSendPort = isolateSendPort;
    isolateSendPort.send([_msgInit, buffer]);
    await initAck.future;
  }

  static const int _msgInit = 0;
  static const int _msgFrame = 1;

  /// Traite une image caméra (YUV420) : conversion en RGB 320x320 (dans compute) puis inférence dans l'isolate.
  /// Throttle : ignore les appels trop rapprochés pour garder ~15–30 FPS. La conversion YUV→RGB ne bloque pas l'UI.
  Future<InferenceOutput> processCameraImage(CameraImage image) async {
    if (_disposed || _isolateSendPort == null) {
      return const InferenceOutput(detections: [], error: 'Service non initialisé ou fermé');
    }
    if (_isProcessing) {
      return const InferenceOutput(detections: []);
    }
    final now = DateTime.now();
    if (_lastInferenceTime != null &&
        now.difference(_lastInferenceTime!) < throttleDuration) {
      return const InferenceOutput(detections: []);
    }

    Uint8List? rgb;
    if (image.planes.length == 1) {
      // iOS BGRA8888 (1 plan)
      final frameData = BgraFrameData(
        bytes: Uint8List.fromList(image.planes[0].bytes),
        bytesPerRow: image.planes[0].bytesPerRow,
        width: image.width,
        height: image.height,
      );
      rgb = await compute(bgraToRgb320x320TopLevel, frameData);
    } else if (image.planes.length >= 3) {
      // Android YUV420 (3 plans)
      final frameData = YuvFrameData(
        yPlane: Uint8List.fromList(image.planes[0].bytes),
        yRowStride: image.planes[0].bytesPerRow,
        uPlane: Uint8List.fromList(image.planes[1].bytes),
        uRowStride: image.planes[1].bytesPerRow,
        vPlane: Uint8List.fromList(image.planes[2].bytes),
        vRowStride: image.planes[2].bytesPerRow,
        width: image.width,
        height: image.height,
      );
      rgb = await compute(yuv420ToRgb320x320TopLevel, frameData);
    }
    if (rgb == null) return const InferenceOutput(detections: []);

    _isProcessing = true;
    _lastInferenceTime = now;
    _pendingCompleter = Completer<InferenceOutput>();
    _isolateSendPort!.send([_msgFrame, rgb]);

    return _pendingCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingCompleter = null;
        _isProcessing = false;
        return const InferenceOutput(detections: [], error: 'Timeout inférence');
      },
    );
  }

  void dispose() {
    _disposed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _receivePort?.close();
    _receivePort = null;
    _pendingCompleter?.complete(const InferenceOutput(detections: []));
    _pendingCompleter = null;
  }
}
