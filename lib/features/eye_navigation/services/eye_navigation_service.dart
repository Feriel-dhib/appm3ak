import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/api_config.dart';
import '../../../core/config/app_config.dart';
import '../../../data/api/ai_module_api_key_interceptor.dart';
import '../models/eye_navigation_action.dart';
import 'eye_navigation_frame_codec.dart';

/// Navigation UI pilotée par le backend Flask (`POST /eye-navigation`).
///
/// - Caméra **frontale** en priorité.
/// - Envoi JPEG à cadence fixe ; **une seule requête HTTP** à la fois ; au plus **une** image en attente.
/// - Dernière action exposée via [lastAction] et [actions].
class EyeNavigationService extends ChangeNotifier {
  EyeNavigationService({
    Dio? dio,
    String? baseUrl,
    this.clientId,
    this.frameInterval = const Duration(milliseconds: 100),
    this.jpegQuality = 80,
    this.maxJpegWidth = 640,
    /// Aligné sur [AiModuleApiClient] : Render gratuit peut mettre >45 s à accepter
    /// la connexion après veille.
    this.connectTimeout = const Duration(seconds: 120),
    this.receiveTimeout = const Duration(seconds: 90),
    this.onAction,
  })  : _baseUrl = baseUrl ?? AppConfig.eyeNavigationBaseUrl,
        _dio = dio ?? _createDefaultDio(connectTimeout, receiveTimeout);

  static Dio _createDefaultDio(
    Duration connectTimeout,
    Duration receiveTimeout,
  ) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: receiveTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      AiModuleApiKeyInterceptor(apiKey: ApiConfig.aiModuleApiKey),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }
    return dio;
  }

  final Dio _dio;
  final String _baseUrl;

  bool _disposed = false;

  void _notifyListeners() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Identifiant stable pour le lissage serveur (optionnel).
  final String? clientId;

  /// ~10 FPS par défaut (100 ms). Entre 66 ms (~15 FPS) et 125 ms (~8 FPS) selon besoin.
  final Duration frameInterval;

  final int jpegQuality;
  final int maxJpegWidth;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Hook pour brancher focus précédent/suivant, validation, etc.
  void Function(EyeNavigationAction action)? onAction;

  CameraController? _controller;
  bool _running = false;

  /// Relance automatique après [pauseForAppLifecycle] si vrai.
  bool _resumeAfterForeground = false;

  bool _encodingFrame = false;
  bool _uploadInProgress = false;
  Uint8List? _queuedJpeg;

  DateTime? _lastFrameTick;

  /// Dernière action renvoyée par le serveur (ou [EyeNavigationAction.idle] si erreur parse).
  EyeNavigationAction lastAction = EyeNavigationAction.idle;

  final StreamController<EyeNavigationAction> _actionCtrl =
      StreamController<EyeNavigationAction>.broadcast();

  /// Flux des actions (équivalent réactif à [lastAction]).
  Stream<EyeNavigationAction> get actions => _actionCtrl.stream;

  String? lastError;

  bool get isRunning => _running;

  CameraController? get cameraController => _controller;

  /// Origine utilisée pour `POST …/eye-navigation` (debug / UI).
  String get configuredBaseUrl => _baseUrl;

  /// Démarre la caméra avant et l’envoi des frames.
  Future<void> start() async {
    if (_running) return;

    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      lastError = 'Permission caméra refusée.';
      _notifyListeners();
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      lastError = 'Aucune caméra disponible.';
      _notifyListeners();
      return;
    }

    final CameraDescription cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      cam,
      ResolutionPreset.medium,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
      enableAudio: false,
    );

    try {
      await controller.initialize();
    } catch (e) {
      lastError = 'Initialisation caméra : $e';
      await controller.dispose();
      _notifyListeners();
      return;
    }

    _controller = controller;
    _running = true;
    lastError = null;
    _notifyListeners();

    await controller.startImageStream(_onCameraImage);
  }

  /// Arrête flux + caméra. Idempotent.
  ///
  /// Si [preserveLifecycleResume] est vrai (pause système), ne réinitialise pas
  /// le drapeau permettant [resumeFromAppLifecycle] de relancer la session.
  Future<void> stop({bool preserveLifecycleResume = false}) async {
    if (!preserveLifecycleResume) {
      _resumeAfterForeground = false;
    }

    if (!_running && _controller == null) return;

    _running = false;
    final c = _controller;
    _controller = null;

    try {
      if (c != null) {
        if (c.value.isStreamingImages) {
          await c.stopImageStream();
        }
        await c.dispose();
      }
    } catch (_) {
      // ignore
    }

    _queuedJpeg = null;
    _encodingFrame = false;
    _uploadInProgress = false;
    _lastFrameTick = null;
    _notifyListeners();
  }

  /// Met en pause l’envoi (app en arrière-plan). La caméra est arrêtée pour économiser batterie / éviter crash iOS.
  Future<void> pauseForAppLifecycle() async {
    if (_running) {
      await stop(preserveLifecycleResume: true);
      _resumeAfterForeground = true;
    }
  }

  /// Relance après retour au premier plan si la session avait été pausée par le lifecycle.
  Future<void> resumeFromAppLifecycle({bool autoRestart = true}) async {
    if (!autoRestart || !_resumeAfterForeground) return;
    _resumeAfterForeground = false;
    await start();
  }

  void _onCameraImage(CameraImage image) {
    if (!_running || _controller == null) return;

    final now = DateTime.now();
    if (_lastFrameTick != null &&
        now.difference(_lastFrameTick!) < frameInterval) {
      return;
    }
    _lastFrameTick = now;

    if (_encodingFrame) {
      return;
    }

    _encodingFrame = true;
    unawaited(_processFrame(image));
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final captured = captureEyeNavigationFrame(
        image,
        jpegQuality: jpegQuality,
        maxEncodeWidth: maxJpegWidth,
      );
      if (captured == null) {
        return;
      }

      final jpeg = await compute(encodeEyeNavigationJpeg, captured);
      if (!_running || jpeg == null || jpeg.isEmpty) {
        return;
      }

      await _enqueueUpload(jpeg);
    } finally {
      _encodingFrame = false;
    }
  }

  Future<void> _enqueueUpload(Uint8List jpeg) async {
    if (_uploadInProgress) {
      _queuedJpeg = jpeg;
      return;
    }
    await _runUploadChain(jpeg);
  }

  Future<void> _runUploadChain(Uint8List first) async {
    _uploadInProgress = true;
    var current = first;
    try {
      while (true) {
        await _uploadOnce(current);
        if (_queuedJpeg == null) break;
        current = _queuedJpeg!;
        _queuedJpeg = null;
      }
    } finally {
      _uploadInProgress = false;
    }
  }

  Future<void> _uploadOnce(Uint8List jpeg) async {
    final uri = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final form = FormData.fromMap({
        'frame': MultipartFile.fromBytes(jpeg, filename: 'frame.jpg'),
        if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
      });

      final response = await _dio.post<dynamic>(
        '$uri/eye-navigation',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      final code = response.statusCode ?? 0;
      if (code >= 400) {
        lastError = 'HTTP $code';
        _publishAction(EyeNavigationAction.idle);
        return;
      }

      final raw = response.data;
      if (raw is Map && raw['action'] is String) {
        final action = (raw['action'] as String).toEyeNavigationAction();
        _publishAction(action);
        lastError = null;
      } else {
        lastError = 'Réponse invalide (pas de champ action).';
        _publishAction(EyeNavigationAction.idle);
      }
    } on DioException catch (e) {
      lastError = _formatDioError(e);
      _publishAction(EyeNavigationAction.idle);
    } catch (e) {
      lastError = 'Erreur : $e';
      _publishAction(EyeNavigationAction.idle);
    }
  }

  String _formatDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Délai réseau dépassé.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion au serveur ($_baseUrl).';
    }
    final code = e.response?.statusCode;
    if (code != null) {
      return 'HTTP $code';
    }
    return e.message ?? 'Erreur réseau';
  }

  void _publishAction(EyeNavigationAction action) {
    lastAction = action;
    if (!_actionCtrl.isClosed) {
      _actionCtrl.add(action);
    }
    onAction?.call(action);
    _notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    unawaited(_actionCtrl.close());
    super.dispose();
  }
}
