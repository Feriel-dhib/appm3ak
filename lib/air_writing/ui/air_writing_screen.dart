import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../hand_tracker.dart';
import '../models/prediction_result.dart';
import '../renderer.dart';
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

  @override
  void initState() {
    super.initState();
    _airWritingService = AirWritingService(
      handTracker: _handTracker,
      gestureService: const GestureService(),
      tfliteService: _tfliteService,
      renderer: const AirWritingRenderer(),
    );
    _predictionSub = _airWritingService.predictions.listen(_onPrediction);
    unawaited(_initialize());
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
      throw CameraException('no_camera', 'Aucune caméra trouvée');
    }
    final selected = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      selected,
      // Résolution plus élevée = contours doigt plus nets pour Vision / MediaPipe.
      ResolutionPreset.high,
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
        '[AirWriting] prédiction top1=${prediction.top1.label} '
        'conf=${prediction.top1.confidence.toStringAsFixed(3)} '
        'acceptée=${prediction.accepted}',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Air Writing')),
        body: Center(
          child: ElevatedButton(
            onPressed: openAppSettings,
            child: const Text('Autoriser caméra'),
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
                    (_error!.contains('interpréteur') ||
                        _error!.contains('interpreter') ||
                        _error!.contains('TFLite'))) ...[
                  Text(
                    'Souvent corrigé par : flutter clean → flutter pub get → '
                    'cd ios && pod install → relancer l’app sur l’appareil.',
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
                  label: Text(_initializing ? 'Patientez…' : 'Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Air Writing'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Debug', style: theme.textTheme.labelLarge),
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
          return Column(
            children: [
              Expanded(
                flex: 5,
                child: _portraitCameraStack(context, controller, state),
              ),
              _textPanel(context, state),
              Expanded(
                flex: 2,
                child: _settingsPanel(context),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Prévisualisation remplissant la zone en **portrait** (BoxFit.cover), avec trajectoire
  /// dans le même repère que la vidéo pour garder l’alignement doigt / trace.
  Widget _portraitCameraStack(
    BuildContext context,
    CameraController controller,
    AirWritingUiState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!controller.value.isInitialized) {
          return const ColoredBox(color: Colors.black);
        }
        final ar = controller.value.aspectRatio;
        if (ar <= 0) {
          return const ColoredBox(color: Colors.black);
        }
        final boxW = constraints.maxWidth;
        final boxH = constraints.maxHeight;
        // Repère interne : hauteur = zone utile, largeur = capteur « paysage » × hauteur (ratio Flutter).
        final innerW = ar * boxH;
        final innerH = boxH;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: boxW,
              height: boxH,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                child: SizedBox(
                  width: innerW,
                  height: innerH,
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
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 8,
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: state.pauseProgress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _infoRow(state),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(AirWritingUiState state) {
    final topK = state.lastPrediction?.topK
            .map((e) => '${e.label}:${(e.confidence * 100).toStringAsFixed(0)}%')
            .join('  ') ??
        '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.black54,
      child: Text(
        'État: ${state.status} | FPS: ${state.fps.toStringAsFixed(1)} | '
        'pts: ${state.points.length} | top-k: $topK',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _textPanel(BuildContext context, AirWritingUiState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confidence = state.lastPrediction?.top1.confidence ?? 0.0;
    return Material(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Texte',
              style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _text.isEmpty ? '—' : _text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confiance : ${(confidence * 100).toStringAsFixed(1)} %',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final useGrid = w < 360;
                final gap = 8.0;
                Widget action({
                  required IconData icon,
                  required String label,
                  required VoidCallback onPressed,
                }) {
                  return FilledButton.tonal(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (useGrid) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: action(
                              icon: Icons.restart_alt,
                              label: 'Réinitialiser',
                              onPressed: _airWritingService.resetTrajectory,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: action(
                              icon: Icons.backspace_outlined,
                              label: 'Supprimer',
                              onPressed: () => setState(() {
                                if (_text.isNotEmpty) {
                                  _text = _text.substring(0, _text.length - 1);
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      Row(
                        children: [
                          Expanded(
                            child: action(
                              icon: Icons.delete_outline,
                              label: 'Tout effacer',
                              onPressed: () => setState(() => _text = ''),
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: action(
                              icon: Icons.space_bar,
                              label: 'Espace',
                              onPressed: () => setState(() => _text += ' '),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: action(
                        icon: Icons.restart_alt,
                        label: 'Réinit.',
                        onPressed: _airWritingService.resetTrajectory,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: action(
                        icon: Icons.backspace_outlined,
                        label: 'Suppr.',
                        onPressed: () => setState(() {
                          if (_text.isNotEmpty) {
                            _text = _text.substring(0, _text.length - 1);
                          }
                        }),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: action(
                        icon: Icons.delete_outline,
                        label: 'Effacer',
                        onPressed: () => setState(() => _text = ''),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: action(
                        icon: Icons.space_bar,
                        label: 'Espace',
                        onPressed: () => setState(() => _text += ' '),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                'Paramètres avancés',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Seuil, pause, points minimum, lissage',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              children: [
                ListTile(
                  dense: true,
                  title: Text('Confiance min. : ${_minConfidence.toStringAsFixed(2)}'),
                  subtitle: Slider(
                    value: _minConfidence,
                    min: 0.1,
                    max: 0.99,
                    divisions: 89,
                    onChanged: (v) => setState(() => _minConfidence = v),
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text('Pause après écriture : ${(_pauseMs / 1000).toStringAsFixed(1)} s'),
                  subtitle: Slider(
                    value: _pauseMs.toDouble(),
                    min: 400,
                    max: 2200,
                    divisions: 18,
                    onChanged: (v) => setState(() => _pauseMs = v.round()),
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
                    onChanged: (v) => setState(() => _minPoints = v.round()),
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text('Lissage (fenêtre) : $_smoothingWindow'),
                  subtitle: Slider(
                    value: _smoothingWindow.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    onChanged: (v) => setState(() => _smoothingWindow = v.round()),
                    onChangeEnd: (_) => _applySettings(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
