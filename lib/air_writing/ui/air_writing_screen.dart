import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/api_config.dart';
import '../hand_tracker.dart';
import '../models/prediction_result.dart';
import '../renderer.dart';
import '../services/air_writing_remote_service.dart';
import '../services/air_writing_service.dart';
import '../services/gesture_service.dart';
import '../services/tflite_service.dart';

class AirWritingScreen extends StatefulWidget {
  const AirWritingScreen({super.key});

  @override
  State<AirWritingScreen> createState() => _AirWritingScreenState();
}

class _AirWritingScreenState extends State<AirWritingScreen> {
  final _handTracker = HandTracker();
  final _tfliteService = TfliteService();
  late final AirWritingRemoteService _remoteService;
  late final AirWritingService _airWritingService;

  CameraController? _cameraController;
  bool _initializing = true;
  bool _permissionGranted = false;
  String? _error;
  String _text = '';
  StreamSubscription<PredictionResult>? _predictionSub;

  double _minConfidence = 0.55;
  int _pauseMs = 1500;
  int _minPoints = 25;
  int _smoothingWindow = 7;
  bool _debugLogs = false;
  AirWritingPredictionMode _predictionMode = AirWritingPredictionMode.local;

  @override
  void initState() {
    super.initState();
    _remoteService = AirWritingRemoteService(
      baseUrl: ApiConfig.airWritingApiBaseUrl,
    );
    _airWritingService = AirWritingService(
      handTracker: _handTracker,
      gestureService: const GestureService(),
      tfliteService: _tfliteService,
      renderer: const AirWritingRenderer(),
      remoteService: _remoteService,
    );
    _predictionSub = _airWritingService.predictions.listen(_onPrediction);
    unawaited(_initialize());
    unawaited(_remoteService.warmUp());
  }

  Future<void> _initialize() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() {
          _permissionGranted = false;
          _initializing = false;
        });
        return;
      }
      _permissionGranted = true;
      await _tfliteService.load();
      await _handTracker.initialize(taskAssetPath: 'assets/models/hand_landmarker.task');
      await _setupCamera();
      _applySettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('no_camera', 'Aucune cam\u00e9ra trouv\u00e9e');
    }
    final selected = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    if (controller.value.focusPointSupported) {
      await controller.setFocusPoint(const Offset(0.5, 0.5));
    }
    if (controller.value.exposurePointSupported) {
      await controller.setExposurePoint(const Offset(0.5, 0.5));
    }
    await controller.startImageStream((image) {
      unawaited(_airWritingService.onCameraImage(image, controller));
    });
    _cameraController = controller;
  }

  void _onPrediction(PredictionResult prediction) {
    if (_debugLogs) {
      debugPrint(
        '[AirWriting] pr\u00e9diction top1=${prediction.top1.label} '
        'conf=${prediction.top1.confidence.toStringAsFixed(3)} '
        'accept\u00e9e=${prediction.accepted}',
      );
    }
    if (!prediction.accepted) return;
    if (!mounted) return;
    setState(() {
      _text += prediction.top1.label;
    });
  }

  void _applySettings() {
    _airWritingService.updateConfig(
      AirWritingConfig(
        minConfidence: _minConfidence,
        pauseMs: _pauseMs,
        minPoints: _minPoints,
        smoothingWindow: _smoothingWindow,
        debugLogs: _debugLogs,
        predictionMode: _predictionMode,
      ),
    );
  }

  @override
  void dispose() {
    _predictionSub?.cancel();
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    _tfliteService.dispose();
    _handTracker.dispose();
    _airWritingService.dispose();
    _remoteService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Air Writing')),
        body: Center(
          child: ElevatedButton(
            onPressed: openAppSettings,
            child: const Text('Autoriser cam\u00e9ra'),
          ),
        ),
      );
    }
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Air Writing')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ListView(
              shrinkWrap: true,
              children: [
                SelectableText(
                  _error ?? 'Initialisation impossible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (_error != null &&
                    (_error!.contains('interpr\u00e9teur') ||
                        _error!.contains('interpreter') ||
                        _error!.contains('TFLite'))) ...[
                  Text(
                    'Souvent corrig\u00e9 par : flutter clean \u2192 flutter pub get \u2192 '
                    'cd ios && pod install \u2192 relancer l\u2019app sur l\u2019appareil.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                ],
                FilledButton.icon(
                  onPressed: _initializing ? null : () => unawaited(_initialize()),
                  icon: _initializing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_initializing ? 'Patientez\u2026' : 'R\u00e9essayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Air Writing', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _remoteService.serverAwakeNotifier,
            builder: (context, awake, _) {
              if (_predictionMode == AirWritingPredictionMode.local) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: awake ? 'Serveur pr\u00eat' : 'Serveur en veille\u2026',
                  child: Icon(
                    Icons.cloud,
                    size: 20,
                    color: awake ? Colors.greenAccent : Colors.white38,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Debug', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Switch(
                  value: _debugLogs,
                  onChanged: (v) {
                    setState(() => _debugLogs = v);
                    _applySettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<AirWritingUiState>(
        valueListenable: _airWritingService.state,
        builder: (context, state, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _fullScreenCamera(controller, state),
              _bottomOverlay(context, state),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cam\u00e9ra plein \u00e9cran
  // ---------------------------------------------------------------------------

  Widget _fullScreenCamera(CameraController controller, AirWritingUiState state) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const ColoredBox(color: Colors.black);
    }

    // previewSize est en orientation capteur (paysage : width > height).
    // En portrait, CameraPreview pivote l'image : les dimensions affichées
    // sont inversées.
    final displayW = previewSize.height;
    final displayH = previewSize.width;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        child: SizedBox(
          width: displayW,
          height: displayH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
                child: CameraPreview(controller),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _TrajectoryPainter(
                    points: state.points,
                    indexPoint: state.indexPoint,
                    writingActive: state.writingActive,
                    sourceSize: state.previewSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Overlay bas (texte + boutons) par-dessus la cam\u00e9ra
  // ---------------------------------------------------------------------------

  Widget _bottomOverlay(BuildContext context, AirWritingUiState state) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
            stops: [0.0, 0.4],
          ),
        ),
        padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPad + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(state),
            const SizedBox(height: 12),
            _textChip(state),
            const SizedBox(height: 12),
            _actionButtons(),
            const SizedBox(height: 8),
            _settingsButton(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Info row (statut, FPS, top-k)
  // ---------------------------------------------------------------------------

  Widget _infoRow(AirWritingUiState state) {
    final topK = state.lastPrediction?.topK
            .map((e) => '${e.label}:${(e.confidence * 100).toStringAsFixed(0)}%')
            .join('  ') ??
        '-';
    final modeLabel = _predictionMode == AirWritingPredictionMode.remote
        ? 'API'
        : 'Local';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.pauseProgress,
            minHeight: 3,
            backgroundColor: Colors.white12,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${state.status} \u2022 ${state.fps.toStringAsFixed(0)} fps \u2022 '
                '${state.points.length} pts \u2022 [$modeLabel]',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(topK, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        if (_predictionMode == AirWritingPredictionMode.remote &&
            !_remoteService.isServerAwake)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'R\u00e9veil du serveur\u2026',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Chip texte reconnu + confiance
  // ---------------------------------------------------------------------------

  Widget _textChip(AirWritingUiState state) {
    final confidence = state.lastPrediction?.top1.confidence ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _text.isEmpty ? '\u2014' : _text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(confidence * 100).toStringAsFixed(0)} %',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Boutons d'action (r\u00e9init, suppr, effacer, espace)
  // ---------------------------------------------------------------------------

  Widget _actionButtons() {
    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          icon: Icons.restart_alt,
          label: 'R\u00e9init.',
          onPressed: _airWritingService.resetTrajectory,
        ),
        const SizedBox(width: 8),
        chip(
          icon: Icons.backspace_outlined,
          label: 'Suppr.',
          onPressed: () => setState(() {
            if (_text.isNotEmpty) {
              _text = _text.substring(0, _text.length - 1);
            }
          }),
        ),
        const SizedBox(width: 8),
        chip(
          icon: Icons.delete_outline,
          label: 'Effacer',
          onPressed: () => setState(() => _text = ''),
        ),
        const SizedBox(width: 8),
        chip(
          icon: Icons.space_bar,
          label: 'Espace',
          onPressed: () => setState(() => _text += ' '),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bouton param\u00e8tres \u2192 bottom sheet
  // ---------------------------------------------------------------------------

  Widget _settingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSettingsSheet(context),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 16, color: Colors.white38),
            SizedBox(width: 6),
            Text('Param\u00e8tres', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  dense: true,
                  title: const Text('Pr\u00e9diction serveur (API)'),
                  subtitle: Text(
                    _predictionMode == AirWritingPredictionMode.remote
                        ? 'Envoi au serveur Render'
                        : 'Inf\u00e9rence TFLite locale',
                  ),
                  secondary: Icon(
                    _predictionMode == AirWritingPredictionMode.remote
                        ? Icons.cloud
                        : Icons.phone_android,
                  ),
                  value: _predictionMode == AirWritingPredictionMode.remote,
                  onChanged: (v) {
                    setState(() {
                      _predictionMode = v
                          ? AirWritingPredictionMode.remote
                          : AirWritingPredictionMode.local;
                    });
                    setSheetState(() {});
                    _applySettings();
                    if (v && !_remoteService.isServerAwake) {
                      unawaited(_remoteService.warmUp());
                    }
                  },
                ),
                ListTile(
                  dense: true,
                  title: Text('Confiance min. : ${_minConfidence.toStringAsFixed(2)}'),
                  subtitle: Slider(
                    value: _minConfidence,
                    min: 0.1,
                    max: 0.99,
                    divisions: 89,
                    onChanged: (v) {
                      setState(() => _minConfidence = v);
                      setSheetState(() {});
                    },
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text('Pause : ${(_pauseMs / 1000).toStringAsFixed(1)} s'),
                  subtitle: Slider(
                    value: _pauseMs.toDouble(),
                    min: 400,
                    max: 2200,
                    divisions: 18,
                    onChanged: (v) {
                      setState(() => _pauseMs = v.round());
                      setSheetState(() {});
                    },
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text('Points minimum : $_minPoints'),
                  subtitle: Slider(
                    value: _minPoints.toDouble(),
                    min: 5,
                    max: 40,
                    divisions: 35,
                    onChanged: (v) {
                      setState(() => _minPoints = v.round());
                      setSheetState(() {});
                    },
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text('Lissage : $_smoothingWindow'),
                  subtitle: Slider(
                    value: _smoothingWindow.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    onChanged: (v) {
                      setState(() => _smoothingWindow = v.round());
                      setSheetState(() {});
                    },
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Painter trajectoire
// -----------------------------------------------------------------------------

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({
    required this.points,
    required this.indexPoint,
    required this.writingActive,
    required this.sourceSize,
  });

  final List<Offset> points;
  final Offset? indexPoint;
  final bool writingActive;
  final Size? sourceSize;

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final sx = sourceSize == null ? 1.0 : size.width / sourceSize!.width;
    final sy = sourceSize == null ? 1.0 : size.height / sourceSize!.height;
    Offset scale(Offset p) => Offset(p.dx * sx, p.dy * sy);
    if (points.length > 1) {
      final path = Path()..moveTo(scale(points.first).dx, scale(points.first).dy);
      for (int i = 1; i < points.length; i++) {
        final pt = scale(points[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, pathPaint);
    }
    if (indexPoint != null) {
      canvas.drawCircle(
        scale(indexPoint!),
        10,
        Paint()
          ..color = writingActive ? Colors.greenAccent : Colors.redAccent
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.indexPoint != indexPoint ||
        oldDelegate.writingActive != writingActive ||
        oldDelegate.sourceSize != sourceSize;
  }
}
