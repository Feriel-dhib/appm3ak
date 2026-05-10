import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/geolocation_utils.dart';
import '../../../core/widgets/address_search_field.dart';
import '../../accessibility/widgets/global_gaze_overlay.dart';
import '../../alerts/alert_engine.dart';
import '../../alerts/tts_alert_service.dart';
import '../../detection/models/detection_result.dart';
import '../../detection/services/camera_stream_service.dart';
import '../../detection/services/yolo_tflite_service.dart';
import '../../detection/widgets/detection_bbox_overlay.dart';
import '../../../data/models/map/geocode_result.dart';
import '../../../data/models/map/route_result.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../utils/route_guidance_utils.dart';
import '../utils/route_turn_steps.dart';
import '../widgets/guidance_arrow_overlay.dart';

/// Guidage (itinéraire API + GPS + flèche) + détection d’obstacles **YOLO TFLite** + voix (même TTS que l’écran détection).
class GuidedArNavigationScreen extends ConsumerStatefulWidget {
  const GuidedArNavigationScreen({super.key});

  @override
  ConsumerState<GuidedArNavigationScreen> createState() =>
      _GuidedArNavigationScreenState();
}

class _GuidedArNavigationScreenState extends ConsumerState<GuidedArNavigationScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final CameraStreamService _cameraService = CameraStreamService(
    preferredLens: CameraLensDirection.back,
  );

  GeocodeResult? _selectedDestination;
  RouteResult? _route;
  List<LatLng> _polyline = [];
  int _routeIndex = 0;

  bool _routeLoading = false;
  String? _setupError;

  YoloTfliteService? _yoloService;
  TtsAlertService? _ttsService;
  AlertEngine? _alertEngine;
  List<DetectionResult> _detections = [];
  bool _frameBusy = false;
  bool _navAssetsInitializing = false;
  bool _navAssetsReady = false;
  String? _cameraError;

  bool _useArabic = false;
  bool _voiceMuted = false;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  LatLng? _userLatLng;
  double _bearingToTarget = 0;
  double? _compassHeading;
  bool _arrivalSpoken = false;

  /// Étapes vocales « pas à pas » dérivées de la polyline.
  List<TurnStep> _turnSteps = [];
  int _stepCursor = 0;
  bool _stepApproachSpoken = false;
  bool _stepMainSpoken = false;
  bool _routeStraightHintSpoken = false;
  bool _guidanceTtsInProgress = false;

  Future<void> _syncTtsLocale() async {
    await _ttsService?.applyVoiceLocale(
      useArabic: _useArabic,
      useEnglish: !_useArabic && _voiceEnglish,
    );
  }

  bool _gazeWasRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Suspend l'eye-gaze global pour éviter le conflit caméra avant/arrière.
    final gaze = ref.read(globalGazeServiceProvider);
    _gazeWasRunning = gaze.isRunning;
    if (_gazeWasRunning) gaze.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_route == null || !_navAssetsReady) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _cameraService.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraService.isInitialized && !_cameraService.isStreaming) {
        _cameraService.startImageStream(_onCameraImage);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _stopGuidanceStreams();
    unawaited(_disposeNavResources());
    if (_gazeWasRunning) {
      ref.read(globalGazeServiceProvider).start();
    }
    super.dispose();
  }

  void _stopGuidanceStreams() {
    _positionSub?.cancel();
    _positionSub = null;
    _compassSub?.cancel();
    _compassSub = null;
  }

  Future<void> _disposeNavResources() async {
    try {
      await _cameraService.stopImageStream();
    } catch (_) {}
    _yoloService?.dispose();
    _yoloService = null;
    try {
      await _cameraService.dispose();
    } catch (_) {}
    try {
      await _ttsService?.dispose();
    } catch (_) {}
    _ttsService = null;
    _alertEngine = null;
  }

  AppStrings get _strings {
    final u = ref.read(authStateProvider).valueOrNull;
    return u != null
        ? AppStrings.fromPreferredLanguage(u.preferredLanguage?.name)
        : AppStrings.fr();
  }

  bool get _voiceEnglish {
    final lang = ref.read(authStateProvider).valueOrNull?.langue.toLowerCase();
    return lang == 'en';
  }

  /// Phrases TTS pour le guidage pas à pas (FR / AR / EN).
  String _directionPhrase(String key) {
    if (_useArabic) {
      switch (key) {
        case 'left':
          return 'انعطف يساراً.';
        case 'right':
          return 'انعطف يميناً.';
        case 'straight':
          return 'استمر مباشرة.';
        case 'uturn':
          return 'انعطف للخلف.';
        case 'destination':
          return 'وصلت إلى وجهتك.';
        case 'route_straight':
          return 'استمر مباشرة حتى الوصول.';
        case 'approach_left':
          return 'خلال بضعة أمتار، انعطف يساراً.';
        case 'approach_right':
          return 'خلال بضعة أمتار، انعطف يميناً.';
        case 'approach_uturn':
          return 'خلال بضعة أمتار، انعطف للخلف.';
        default:
          return 'استمر.';
      }
    }
    if (_voiceEnglish) {
      switch (key) {
        case 'left':
          return 'Turn left.';
        case 'right':
          return 'Turn right.';
        case 'straight':
          return 'Continue straight ahead.';
        case 'uturn':
          return 'Make a U-turn.';
        case 'destination':
          return 'You have arrived.';
        case 'route_straight':
          return 'Continue straight to your destination.';
        case 'approach_left':
          return 'In about fifty metres, turn left.';
        case 'approach_right':
          return 'In about fifty metres, turn right.';
        case 'approach_uturn':
          return 'In about fifty metres, make a U-turn.';
        default:
          return 'Continue.';
      }
    }
    switch (key) {
      case 'left':
        return 'Tournez à gauche.';
      case 'right':
        return 'Tournez à droite.';
      case 'straight':
        return 'Continuez tout droit.';
      case 'uturn':
        return 'Faites demi-tour.';
      case 'destination':
        return 'Vous êtes arrivé.';
      case 'route_straight':
        return 'Continuez tout droit jusqu’à la destination.';
      case 'approach_left':
        return 'Dans environ cinquante mètres, tournez à gauche.';
      case 'approach_right':
        return 'Dans environ cinquante mètres, tournez à droite.';
      case 'approach_uturn':
        return 'Dans environ cinquante mètres, faites demi-tour.';
      default:
        return 'Continuez.';
    }
  }

  Future<void> _startYoloCameraAndTts() async {
    setState(() {
      _navAssetsInitializing = true;
      _navAssetsReady = false;
      _cameraError = null;
      _detections = [];
    });

    _yoloService = YoloTfliteService();
    _ttsService = TtsAlertService();
    _alertEngine = AlertEngine(tts: _ttsService!);

    try {
      await Future.wait([
        _cameraService.initialize(),
        _yoloService!.initialize(),
      ]);
      if (!mounted) return;
      await _syncTtsLocale();
      _ttsService!.setMuted(_voiceMuted);
      setState(() {
        _navAssetsInitializing = false;
        _navAssetsReady = true;
      });
      _cameraService.startImageStream(_onCameraImage);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isMissingModel = msg.contains('Unable to load asset') ||
          msg.contains('m3ak_yolov8.tflite') ||
          msg.contains('does not exist or has empty data');
      setState(() {
        _navAssetsInitializing = false;
        _navAssetsReady = false;
        _cameraError = isMissingModel
            ? _strings.guidedArModelMissing
            : '${_strings.guidedArCameraError}: $e';
      });
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_route == null || !_navAssetsReady || _frameBusy) return;
    final yolo = _yoloService;
    if (yolo == null) return;
    _frameBusy = true;
    yolo.processCameraImage(image).then((output) {
      if (!mounted || _route == null) return;
      if (output.error != null && output.error!.isNotEmpty) {
        debugPrint('[GuidedAR/YOLO] ${output.error}');
      }
      final list = output.detections.map((s) => s.toDetectionResult()).toList();
      setState(() => _detections = list);
      final engine = _alertEngine;
      if (engine != null && !_voiceMuted && list.isNotEmpty) {
        engine.processDetections(list, useArabic: _useArabic);
      }
    }).whenComplete(() {
      if (mounted) _frameBusy = false;
    });
  }

  void _startLocationAndCompass() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 6,
      ),
    ).listen(_onPosition);

    if (!kIsWeb) {
      _compassSub?.cancel();
      _compassSub = FlutterCompass.events?.listen((event) {
        final h = event.heading;
        if (h == null || !mounted) return;
        setState(() => _compassHeading = h);
      });
    }
  }

  void _onPosition(Position pos) {
    if (_polyline.isEmpty || !mounted) return;
    final user = LatLng(pos.latitude, pos.longitude);
    final newIndex = RouteGuidanceUtils.advanceIndex(user, _polyline, _routeIndex);
    final target = RouteGuidanceUtils.targetWaypoint(_polyline, newIndex);
    if (target == null) return;

    final bearing = RouteGuidanceUtils.bearing(user, target);

    if (!mounted) return;
    setState(() {
      _userLatLng = user;
      _routeIndex = newIndex;
      _bearingToTarget = bearing;
    });

    final distEnd = RouteGuidanceUtils.distanceMeters(user, _polyline.last);
    if (distEnd < 28 && _ttsService != null && !_arrivalSpoken) {
      unawaited(_announceArrivalOnce());
      return;
    }

    unawaited(_processStepByStepVoice(user));
    if (pos.heading >= 0 && pos.heading <= 360) {
      _compassHeading ??= pos.heading;
    }
  }

  Future<void> _announceArrivalOnce() async {
    final tts = _ttsService;
    if (_arrivalSpoken || tts == null || _voiceMuted) return;
    _arrivalSpoken = true;
    await _syncTtsLocale();
    await tts.speak(_directionPhrase('destination'));
  }

  /// Guidage vocal **pas à pas** : annonce d’approche puis manœuvre au sommet de la polyline.
  Future<void> _processStepByStepVoice(LatLng user) async {
    final tts = _ttsService;
    if (tts == null || _voiceMuted || _polyline.length < 2 || !mounted) return;
    if (_arrivalSpoken) return;
    if (_guidanceTtsInProgress) return;

    final distEnd = RouteGuidanceUtils.distanceMeters(user, _polyline.last);
    if (distEnd < 28) return;

    if (_turnSteps.isEmpty) {
      if (!_routeStraightHintSpoken) {
        _routeStraightHintSpoken = true;
        _guidanceTtsInProgress = true;
        try {
          await _syncTtsLocale();
          await tts.speak(_directionPhrase('route_straight'));
        } finally {
          _guidanceTtsInProgress = false;
        }
      }
      return;
    }

    if (_stepCursor >= _turnSteps.length) return;

    final step = _turnSteps[_stepCursor];
    final pivot = _polyline[step.vertexIndex];
    final d = RouteGuidanceUtils.distanceMeters(user, pivot);
    final sharp = step.voiceKey == 'left' ||
        step.voiceKey == 'right' ||
        step.voiceKey == 'uturn';

    if (!_stepMainSpoken && d <= 30) {
      if (!mounted) return;
      setState(() => _stepMainSpoken = true);
      _guidanceTtsInProgress = true;
      try {
        await _syncTtsLocale();
        await tts.speak(_directionPhrase(step.voiceKey));
      } finally {
        _guidanceTtsInProgress = false;
      }
      return;
    }

    if (sharp && !_stepApproachSpoken && !_stepMainSpoken && d <= 72 && d > 30) {
      if (!mounted) return;
      setState(() => _stepApproachSpoken = true);
      _guidanceTtsInProgress = true;
      try {
        await _syncTtsLocale();
        final approachKey = switch (step.voiceKey) {
          'uturn' => 'approach_uturn',
          'left' => 'approach_left',
          'right' => 'approach_right',
          _ => 'approach_right',
        };
        await tts.speak(_directionPhrase(approachKey));
      } finally {
        _guidanceTtsInProgress = false;
      }
      return;
    }

    if (_stepMainSpoken &&
        (_routeIndex > step.vertexIndex || d < 12)) {
      if (!mounted) return;
      setState(() {
        _stepCursor++;
        _stepApproachSpoken = false;
        _stepMainSpoken = false;
      });
    }
  }

  Future<void> _onStartGuidedNavigation() async {
    final dest = _selectedDestination;
    if (dest == null) {
      setState(() => _setupError = _strings.guidedArSelectDestination);
      return;
    }
    setState(() {
      _setupError = null;
      _routeLoading = true;
    });
    try {
      double originLat;
      double originLon;
      try {
        final pos = await resolveUserPosition();
        originLat = pos.latitude;
        originLon = pos.longitude;
      } on GeolocationError {
        final u = ref.read(authStateProvider).valueOrNull;
        final fb = profileCoordinatesFallback(u?.latitude, u?.longitude);
        if (fb == null) {
          setState(() {
            _routeLoading = false;
            _setupError = _strings.guidedArGpsError;
          });
          return;
        }
        originLat = fb.lat;
        originLon = fb.lon;
      }

      final repo = ref.read(mapRepositoryProvider);
      final route = await repo.route(
        originLat: originLat,
        originLon: originLon,
        destinationLat: dest.lat,
        destinationLon: dest.lon,
      );
      final pts = route.geometry.toLatLngList();
      if (pts.length < 2) {
        setState(() {
          _routeLoading = false;
          _setupError = _strings.guidedArEmptyRoute;
        });
        return;
      }

      if (!mounted) return;
      final steps = computeTurnSteps(pts);
      setState(() {
        _route = route;
        _polyline = pts;
        _routeIndex = 0;
        _routeLoading = false;
        _userLatLng = LatLng(originLat, originLon);
        _turnSteps = steps;
        _stepCursor = 0;
        _stepApproachSpoken = false;
        _stepMainSpoken = false;
        _routeStraightHintSpoken = false;
      });
      _startLocationAndCompass();
      await _startYoloCameraAndTts();
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _setupError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _exitNavigation() async {
    _stopGuidanceStreams();
    await _disposeNavResources();
    if (!mounted) return;
    setState(() {
      _route = null;
      _polyline = [];
      _routeIndex = 0;
      _detections = [];
      _cameraError = null;
      _userLatLng = null;
      _arrivalSpoken = false;
      _turnSteps = [];
      _stepCursor = 0;
      _stepApproachSpoken = false;
      _stepMainSpoken = false;
      _routeStraightHintSpoken = false;
      _navAssetsReady = false;
      _navAssetsInitializing = false;
    });
  }

  void _toggleVoiceMute() {
    setState(() => _voiceMuted = !_voiceMuted);
    _ttsService?.setMuted(_voiceMuted);
    if (_voiceMuted) {
      _ttsService?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final theme = Theme.of(context);

    if (_route != null && _polyline.length >= 2) {
      return _buildNavigationPhase(context, theme, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.guidedArTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            strings.guidedArIntro,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          AddressSearchField(
            controller: _searchController,
            label: strings.guidedArDestinationLabel,
            hint: strings.guidedArDestinationHint,
            onSelected: (r) => setState(() {
              _selectedDestination = r;
              _setupError = null;
            }),
          ),
          if (_selectedDestination != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.place),
                title: Text(
                  _selectedDestination!.displayName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          if (_setupError != null) ...[
            const SizedBox(height: 12),
            Text(_setupError!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _routeLoading ? null : _onStartGuidedNavigation,
            icon: _routeLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _routeLoading ? strings.guidedArCalculatingRoute : strings.guidedArStartButton,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _routeLoading
                ? null
                : () => context.push('/transport/obstacle-detection'),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Démarrer la caméra (sans destination)'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPhase(
    BuildContext context,
    ThemeData theme,
    AppStrings strings,
  ) {
    if (_cameraError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.guidedArTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_cameraError!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: Text(strings.cancelLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ctrl = _cameraService.controller;
    final camReady = ctrl != null && ctrl.value.isInitialized && _navAssetsReady;

    if (_navAssetsInitializing || !camReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Center(child: CircularProgressIndicator()),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  await _exitNavigation();
                  if (context.mounted) context.pop();
                },
              ),
            ),
          ],
        ),
      );
    }

    final heading = _compassHeading;
    final dist = _userLatLng != null
        ? RouteGuidanceUtils.distanceMeters(_userLatLng!, _polyline.last)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(ctrl),
          DetectionBBoxOverlay(detections: _detections),
          GuidanceArrowOverlay(
            bearingDegrees: _bearingToTarget,
            deviceHeadingDegrees: heading,
          ),
          if (heading == null && !kIsWeb)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    strings.guidedArCompassHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedDestination?.displayName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dist != null)
                      Text(
                        strings.guidedArRemainingDistance(
                          dist >= 1000
                              ? '${(dist / 1000).toStringAsFixed(1)} km'
                              : '${dist.round()} m',
                        ),
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                      ),
                    if (_route != null)
                      Text(
                        '${_route!.distanceFormatted} · ${_route!.durationFormatted}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    await _exitNavigation();
                    if (context.mounted) context.pop();
                  },
                ),
                IconButton(
                  icon: Icon(
                    _voiceMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  tooltip: _voiceMuted ? 'Réactiver la voix' : 'Couper la voix',
                  onPressed: _toggleVoiceMute,
                ),
                const Spacer(),
                Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      setState(() => _useArabic = !_useArabic);
                      unawaited(_syncTtsLocale());
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        _useArabic ? 'عربي' : 'FR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
