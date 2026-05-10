import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service global de **navigation par regard** pour toute l'app Ma3ak.
///
/// Quand il est démarré (mode `EYES` appliqué), il :
///  - ouvre la **caméra avant** de l'iPhone en arrière-plan ;
///  - utilise `FaceDetector` (ML Kit) pour estimer l'orientation de la tête
///    (`headEulerAngleY` / `headEulerAngleX`) et l'état des yeux ;
///  - publie une position `cursor` en pixels écran logiques, qu'un overlay
///    global (`GlobalGazeOverlay`) consomme pour afficher le curseur ;
///  - déclenche un **clic synthétique** (`PointerDown`/`PointerUp` injectés
///    dans `GestureBinding`) en cas de dwell (regard maintenu) ou de
///    clignement simultané des deux yeux.
class GlobalGazeService extends ChangeNotifier {
  GlobalGazeService();

  // ── État public ────────────────────────────────────────────────────────────
  bool _running = false;
  bool get isRunning => _running;

  /// Position du curseur, en pixels logiques. `null` si pas démarré ou pas
  /// encore de visage détecté.
  Offset? _cursor;
  Offset? get cursor => _cursor;

  /// Vrai pendant qu'un clignement (yeux fermés) est en cours.
  bool _blinking = false;
  bool get blinking => _blinking;

  /// Progression 0..1 du dwell-click sur la position courante.
  double _dwellProgress = 0;
  double get dwellProgress => _dwellProgress;

  /// Erreur de démarrage (permission, caméra, ML Kit). `null` si OK.
  String? _error;
  String? get error => _error;

  // ── Internes ───────────────────────────────────────────────────────────────
  CameraController? _controller;
  FaceDetector? _detector;
  bool _processing = false;
  bool _streamStarted = false;

  Size _screenSize = Size.zero;
  EdgeInsets _safe = EdgeInsets.zero;

  // Lissage du curseur (filtre passe-bas).
  double _gazeX = 0;
  double _gazeY = 0;

  // Sondes de yeux pour clignement.
  double _leftEyeOpen = 1;
  double _rightEyeOpen = 1;

  // Détection blink / dwell.
  DateTime? _blinkStart;
  Offset? _hoverPosition;
  DateTime? _hoverStart;

  /// Délai de clignement (ms) au-dessus duquel on considère un "clic".
  static const _blinkMs = 350;

  /// Délai de dwell (ms) sur une zone stable → "clic" automatique.
  static const _dwellMs = 1300;

  /// Rayon (px logiques) en deçà duquel on considère que le curseur est
  /// resté sur la même cible.
  static const _hoverRadius = 32.0;

  /// Anti-spam : délai mini entre deux clics synthétiques.
  static const _clickCooldownMs = 600;
  DateTime _lastClickAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Mise à jour des dimensions/padding écran depuis l'overlay (chaque rebuild).
  void updateLayout(Size size, EdgeInsets safe) {
    _screenSize = size;
    _safe = safe;
  }

  Future<void> start() async {
    if (_running) return;
    _error = null;
    _running = true;
    notifyListeners();

    try {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        _error = 'Permission caméra refusée.';
        _running = false;
        notifyListeners();
        return;
      }
      final cams = await availableCameras();
      if (cams.isEmpty) {
        _error = 'Aucune caméra disponible.';
        _running = false;
        notifyListeners();
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.low,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
        enableAudio: false,
      );
      await controller.initialize();
      if (!_running) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: true,
          minFaceSize: 0.2,
        ),
      );
      controller.startImageStream(_onFrame);
      _streamStarted = true;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur init caméra : $e';
      _running = false;
      notifyListeners();
      await stop();
    }
  }

  Future<void> stop() async {
    _running = false;
    try {
      if (_streamStarted) {
        await _controller?.stopImageStream();
      }
    } catch (_) {}
    _streamStarted = false;
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    try {
      await _detector?.close();
    } catch (_) {}
    _detector = null;
    _cursor = null;
    _blinking = false;
    _dwellProgress = 0;
    _hoverPosition = null;
    _hoverStart = null;
    _blinkStart = null;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stop();
    super.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || !_running) return;
    final detector = _detector;
    final ctrl = _controller;
    if (detector == null || ctrl == null) return;
    _processing = true;
    try {
      final input = _toInputImage(image, ctrl.description);
      if (input == null) return;
      final faces = await detector.processImage(input);
      if (!_running || _screenSize == Size.zero) return;
      if (faces.isEmpty) return;

      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final f = faces.first;

      // Yaw : caméra avant miroir → on inverse pour que tourner la tête à
      // droite déplace le curseur à droite à l'écran.
      final yawRaw = -((f.headEulerAngleY ?? 0).clamp(-30.0, 30.0)) / 30.0;
      final pitchRaw = -((f.headEulerAngleX ?? 0).clamp(-22.0, 22.0)) / 22.0;

      _gazeX = _gazeX * 0.55 + yawRaw * 0.45;
      _gazeY = _gazeY * 0.55 + pitchRaw * 0.45;
      _leftEyeOpen = f.leftEyeOpenProbability ?? 1.0;
      _rightEyeOpen = f.rightEyeOpenProbability ?? 1.0;

      _cursor = _mapToScreen(_gazeX, _gazeY);
      _blinking = _leftEyeOpen < 0.3 && _rightEyeOpen < 0.3;

      _processBlink();
      _processDwell();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('GlobalGazeService: $e');
    } finally {
      _processing = false;
    }
  }

  Offset _mapToScreen(double nx, double ny) {
    final w = _screenSize.width;
    final h = _screenSize.height;
    final marginX = 24 + _safe.left;
    final marginY = 24 + _safe.top;
    final innerW = (w - marginX - 24 - _safe.right).clamp(1.0, w);
    final innerH = (h - marginY - 24 - _safe.bottom).clamp(1.0, h);
    final cx = marginX + innerW / 2 + nx * (innerW / 2 - 12);
    final cy = marginY + innerH / 2 + ny * (innerH / 2 - 12);
    return Offset(cx.clamp(0.0, w), cy.clamp(0.0, h));
  }

  void _processBlink() {
    final now = DateTime.now();
    if (_blinking) {
      _blinkStart ??= now;
      if (now.difference(_blinkStart!).inMilliseconds >= _blinkMs) {
        _emitClickIfAllowed();
        _blinkStart = null;
      }
    } else {
      _blinkStart = null;
    }
  }

  void _processDwell() {
    final now = DateTime.now();
    final pos = _cursor;
    if (pos == null) {
      _hoverPosition = null;
      _hoverStart = null;
      _dwellProgress = 0;
      return;
    }
    if (_hoverPosition == null ||
        (pos - _hoverPosition!).distance > _hoverRadius) {
      _hoverPosition = pos;
      _hoverStart = now;
      _dwellProgress = 0;
      return;
    }
    final dt = now.difference(_hoverStart!).inMilliseconds;
    _dwellProgress = (dt / _dwellMs).clamp(0.0, 1.0);
    if (dt >= _dwellMs) {
      _emitClickIfAllowed();
      _hoverPosition = null;
      _hoverStart = null;
      _dwellProgress = 0;
    }
  }

  void _emitClickIfAllowed() {
    final now = DateTime.now();
    if (now.difference(_lastClickAt).inMilliseconds < _clickCooldownMs) return;
    _lastClickAt = now;
    final pos = _cursor;
    if (pos == null) return;
    HapticFeedback.mediumImpact();
    _dispatchSyntheticTap(pos);
  }

  /// Injecte un `PointerDown` puis `PointerUp` à `pos` via `GestureBinding`,
  /// ce qui équivaut à un tap réel sur le widget situé sous le curseur.
  void _dispatchSyntheticTap(Offset pos) {
    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      if (dispatcher.views.isEmpty) return;
      final viewId = dispatcher.views.first.viewId;
      final hitTest = HitTestResult();
      GestureBinding.instance.hitTestInView(hitTest, pos, viewId);
      final pointer = DateTime.now().microsecondsSinceEpoch;
      final ts = Duration(microseconds: pointer);
      GestureBinding.instance.dispatchEvent(
        PointerDownEvent(
          position: pos,
          pointer: pointer,
          timeStamp: ts,
          kind: PointerDeviceKind.touch,
        ),
        hitTest,
      );
      GestureBinding.instance.dispatchEvent(
        PointerUpEvent(
          position: pos,
          pointer: pointer,
          timeStamp: ts,
          kind: PointerDeviceKind.touch,
        ),
        hitTest,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('GazeTap error: $e');
    }
  }

  // ── Conversion CameraImage → InputImage ───────────────────────────────────
  InputImage? _toInputImage(CameraImage image, CameraDescription desc) {
    final rotation =
        InputImageRotationValue.fromRawValue(desc.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (format != InputImageFormat.bgra8888) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    if (format != InputImageFormat.nv21) return null;
    final allBytes = WriteBuffer();
    for (final p in image.planes) {
      allBytes.putUint8List(p.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    return InputImage.fromBytes(
      bytes: Uint8List.fromList(bytes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
