import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../air_writing/hand_tracker.dart';
import '../../../data/models/ai/air_click_models.dart';
import '../../../data/repositories/ai_module_repository.dart';

/// Mode gestes pour utilisateurs avec un handicap moteur.
///
/// Reprend la même structure UI que [BlindVoiceModeScreen] et
/// [DeafTextModeScreen] :
///   * carte de statut en haut (action + confiance + progression dwell),
///   * liste de cards [FilledButton.tonalIcon] grandes et focalisables,
///   * barre du bas avec actions principales (balayage, sensibilité,
///     activation, SOS prioritaire).
///
/// Trois manières d'interagir, hiérarchisées du plus accessible :
///   1. **Tap large** sur une card (toujours actif).
///   2. **Switch-scanning + dwell** : le focus avance automatiquement, on
///      maintient un index focalisé suffisamment longtemps pour le valider
///      (sélection par maintien — standard handicaps moteurs).
///   3. **Live tracking caméra** (opt-in) : suivi de main + classification
///      `move/click/hold` côté backend `/air-click`, sensibilité réglable
///      selon mobilité de l'utilisateur (low / normal / high).
class MotorGestureModeScreen extends ConsumerStatefulWidget {
  const MotorGestureModeScreen({super.key, required this.repository});

  final AiModuleRepository repository;

  @override
  ConsumerState<MotorGestureModeScreen> createState() =>
      _MotorGestureModeScreenState();
}

class _MotorGestureModeScreenState
    extends ConsumerState<MotorGestureModeScreen> with WidgetsBindingObserver {
  // Préférences persistées (sensibilité, dwell, balayage, TTS).
  static const String _kPrefSensitivity = 'motor.sensitivity';
  static const String _kPrefDwellMs = 'motor.dwell_ms';
  static const String _kPrefScanIntervalMs = 'motor.scan_interval_ms';
  static const String _kPrefSpeakFocus = 'motor.speak_focus';

  // Caméra optionnelle (live tracking).
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;
  bool _liveTracking = false;
  bool _liveBusy = false;
  bool _liveInitialized = false;
  int _liveFrameCounter = 0;
  int _liveAirClickThrottle = 0;
  bool _streamingImages = false;
  bool _airClickInFlight = false;
  final HandTracker _handTracker = HandTracker();
  static const int _liveFrameSkip = 3;
  static const int _liveAiSkip = 4;
  static const double _minClickConfidenceLive = 0.35;

  // TTS local (annonces de focus).
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _speakFocus = true;

  // Balayage / focus.
  Timer? _scanTimer;
  Timer? _dwellPollTimer;
  /// Une seule requête dwell HTTP à la fois (évite de saturer Render avec des centaines de connexions parallèles).
  bool _dwellPollInFlight = false;
  bool _dwellResetInFlight = false;
  bool _scanning = false;
  Duration _scanInterval = const Duration(milliseconds: 1800);
  int _focusIndex = 0;
  double _dwellProgress = 0.0;
  int _dwellMs = 1500;
  bool _dwellEnabled = true;

  // Cooldowns / anti-rebond.
  static const Duration _clickHoldCooldown = Duration(milliseconds: 700);
  static const Duration _moveFocusCooldown = Duration(milliseconds: 1500);
  DateTime _lastCommitAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFocusChangeAt = DateTime.fromMillisecondsSinceEpoch(0);

  // État de classification / UI.
  AirClickAction _lastAction = AirClickAction.idle;
  double _lastConfidence = 0.0;
  String _statusText = 'Préparation du mode gestes…';
  bool _initializing = true;
  MotorSensitivity _sensitivity = MotorSensitivity.normal;

  // Stable client id pour conserver l'état dwell / air-click côté backend.
  late final String _clientId =
      'motor-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  /// Catalogue d'actions affichées comme cards focalisables.
  /// Ordre pensé pour utilisateurs moteur : SOS très accessible (en haut),
  /// puis services courants, puis confort.
  static const List<_GestureAction> _actions = [
    _GestureAction(
      id: 'sos',
      label: 'SOS – urgence',
      description: 'Envoyer une alerte à mes contacts.',
      icon: Icons.emergency_outlined,
      route: '/sos-alerts',
      critical: true,
    ),
    _GestureAction(
      id: 'home',
      label: 'Accueil',
      description: 'Page principale.',
      icon: Icons.home_outlined,
      route: '/home?tab=0',
    ),
    _GestureAction(
      id: 'transport_request',
      label: 'Demander un transport',
      description: 'Créer une course adaptée.',
      icon: Icons.edit_road_outlined,
      route: '/transport/request',
    ),
    _GestureAction(
      id: 'transport',
      label: 'Mes trajets',
      description: 'Suivi des courses en cours.',
      icon: Icons.directions_bus_outlined,
      route: '/home?tab=2',
    ),
    _GestureAction(
      id: 'health',
      label: 'Santé',
      description: 'Onglet santé et chat IA médical.',
      icon: Icons.medical_services_outlined,
      route: '/home?tab=1',
    ),
    _GestureAction(
      id: 'community',
      label: 'Communauté',
      description: 'Discussions et entraide.',
      icon: Icons.forum_outlined,
      route: '/home?tab=4&communityTab=0',
    ),
    _GestureAction(
      id: 'places',
      label: 'Lieux accessibles',
      description: 'Trouver un endroit adapté à proximité.',
      icon: Icons.location_on_outlined,
      route: '/accessible-places',
    ),
    _GestureAction(
      id: 'notifications',
      label: 'Notifications',
      description: 'Mes alertes et messages.',
      icon: Icons.notifications_active_outlined,
      route: '/notifications',
    ),
    _GestureAction(
      id: 'profile',
      label: 'Mon profil',
      description: 'Compte et paramètres.',
      icon: Icons.person_outline,
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    // Réveille l’instance Render avant dwell / air-click (première requête réseau).
    unawaited(widget.repository.prewarmRemoteInstance());
    await _loadPrefs();
    await _configureTts();
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _statusText = _buildIdleStatus();
    });
    // On démarre le balayage automatique : c'est l'interaction de base
    // pour un utilisateur moteur (un seul tap pour valider).
    _startScan();
    if (_dwellEnabled) {
      _startDwellPolling();
    }
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sens = prefs.getString(_kPrefSensitivity);
      _sensitivity = switch (sens) {
        'low' => MotorSensitivity.low,
        'high' => MotorSensitivity.high,
        _ => MotorSensitivity.normal,
      };
      _dwellMs = prefs.getInt(_kPrefDwellMs) ?? 1500;
      final scanMs = prefs.getInt(_kPrefScanIntervalMs) ?? 1800;
      _scanInterval = Duration(milliseconds: scanMs);
      _speakFocus = prefs.getBool(_kPrefSpeakFocus) ?? true;
    } catch (_) {
      // Best effort : on garde les valeurs par défaut.
    }
  }

  Future<void> _savePref<T>(String key, T value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (_) {}
  }

  Future<void> _configureTts() async {
    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          <IosTextToSpeechAudioCategoryOptions>[
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setLanguage('fr-FR');
      _ttsReady = true;
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (!_speakFocus || !_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  String _buildIdleStatus() {
    return 'Le focus avance tout seul. Touchez la zone verte ou maintenez-le pour valider.';
  }

  // ---------------------------------------------------------------------------
  // Balayage automatique : avance le focus à intervalle régulier.
  // ---------------------------------------------------------------------------

  void _startScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanInterval, (_) {
      if (!mounted) return;
      _advanceFocus();
    });
    if (mounted) {
      setState(() {
        _scanning = true;
      });
    }
    _announceFocusChanged();
  }

  void _stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (!mounted) return;
    setState(() {
      _scanning = false;
    });
  }

  void _advanceFocus() {
    setState(() {
      _focusIndex = (_focusIndex + 1) % _actions.length;
      _dwellProgress = 0.0;
      _statusText =
          'Focus : ${_actions[_focusIndex].label}. ${_actions[_focusIndex].description}';
    });
    HapticFeedback.selectionClick();
    _announceFocusChanged();
    _resetDwellRemote();
  }

  void _announceFocusChanged() {
    if (!mounted) return;
    final action = _actions[_focusIndex];
    _speak(action.label);
  }

  // ---------------------------------------------------------------------------
  // Dwell selection : on envoie périodiquement l'index focalisé au backend.
  // ---------------------------------------------------------------------------

  void _startDwellPolling() {
    _dwellPollTimer?.cancel();
    // Intervalle plus large qu’un cycle réseau typique : avec sérialisation ci‑dessous,
    // évite d’empiler des dizaines de POST si le backend est lent ou en cold start.
    _dwellPollTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => unawaited(_pollDwell()),
    );
  }

  void _stopDwellPolling() {
    _dwellPollTimer?.cancel();
    _dwellPollTimer = null;
    if (mounted) {
      setState(() => _dwellProgress = 0.0);
    }
  }

  Future<void> _pollDwell() async {
    if (!_dwellEnabled || !mounted || _dwellPollInFlight) return;
    _dwellPollInFlight = true;
    try {
      final response = await widget.repository.dwellSelect(
        DwellSelectRequest(
          focusIndex: _focusIndex,
          clientId: _clientId,
          dwellMs: _dwellMs,
        ),
      );
      if (!mounted) return;
      setState(() => _dwellProgress = response.progress);
      if (response.selected && response.selectedIndex != null) {
        _commitFocusedAction(viaDwell: true);
      }
    } catch (_) {
      // Backend indispo : pas grave, le balayage + tap reste possible.
    } finally {
      _dwellPollInFlight = false;
    }
  }

  Future<void> _resetDwellRemote() async {
    if (_dwellResetInFlight) return;
    _dwellResetInFlight = true;
    try {
      await widget.repository.dwellReset(clientId: _clientId);
    } catch (_) {} finally {
      _dwellResetInFlight = false;
    }
  }

  void _commitFocusedAction({bool viaDwell = false}) {
    final now = DateTime.now();
    if (now.difference(_lastCommitAt) < _clickHoldCooldown) return;
    _lastCommitAt = now;

    final action = _actions[_focusIndex];
    HapticFeedback.heavyImpact();
    setState(() {
      _statusText = viaDwell
          ? 'Maintien validé : ouverture de ${action.label}.'
          : 'Activation : ${action.label}.';
    });
    _speak('Ouverture de ${action.label}');
    _stopScan();
    _resetDwellRemote();

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      context.go(action.route);
    });
  }

  void _setFocus(int index, {bool fromTap = false}) {
    if (index < 0 || index >= _actions.length) return;
    setState(() {
      _focusIndex = index;
      _dwellProgress = 0.0;
      _statusText =
          'Focus : ${_actions[index].label}. ${_actions[index].description}';
    });
    HapticFeedback.selectionClick();
    _announceFocusChanged();
    _resetDwellRemote();
    if (fromTap) {
      // Sur tap, on déclenche immédiatement (un tap = une activation).
      _commitFocusedAction();
    }
  }

  // ---------------------------------------------------------------------------
  // Caméra + live tracking (opt-in).
  // ---------------------------------------------------------------------------

  Future<void> _enableCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _cameraError = 'Permission caméra refusée.');
        }
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'Aucune caméra détectée.');
        }
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      _cameraController = controller;
      if (mounted) {
        setState(() {
          _cameraReady = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _cameraError = 'Caméra indisponible (${_humanize(e)}).',
        );
      }
    }
  }

  String _humanize(Object e) {
    final raw = e.toString();
    if (raw.contains('CameraException')) return 'autre app utilise la caméra';
    return 'erreur';
  }

  Future<void> _disableCamera() async {
    if (_liveTracking) {
      await _stopLiveTracking();
    }
    final c = _cameraController;
    _cameraController = null;
    if (c != null) {
      try {
        await c.dispose();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _cameraReady = false;
      });
    }
  }

  Future<void> _toggleLiveTracking() async {
    if (_liveTracking) {
      await _stopLiveTracking();
    } else {
      await _startLiveTracking();
    }
  }

  Future<void> _startLiveTracking() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showSnack('Activez d’abord la caméra.');
      return;
    }
    try {
      if (!_liveInitialized) {
        await _handTracker.initialize(
          taskAssetPath: 'assets/models/hand_landmarker.task',
        );
        _liveInitialized = true;
      }
    } on MissingPluginException {
      _showSnack('Suivi de main natif indisponible sur cette plateforme.');
      return;
    } catch (e) {
      _showSnack('Initialisation suivi main impossible : $e');
      return;
    }

    if (!_streamingImages) {
      try {
        await controller.startImageStream(_onCameraImage);
        _streamingImages = true;
      } catch (e) {
        _showSnack('Impossible d’ouvrir le flux caméra : $e');
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _liveTracking = true;
      _statusText =
          'Suivi de main actif : bougez la main, joignez pouce + index pour valider.';
    });
  }

  Future<void> _stopLiveTracking() async {
    final controller = _cameraController;
    if (controller != null && _streamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
      _streamingImages = false;
    }
    if (!mounted) return;
    setState(() {
      _liveTracking = false;
    });
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (!_liveTracking || _liveBusy) return;
    _liveFrameCounter++;
    if (_liveFrameCounter % _liveFrameSkip != 0) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    _liveBusy = true;
    try {
      final hand = await _handTracker.detectFromCameraImage(
        image,
        sensorRotation: controller.description.sensorOrientation,
        deviceOrientationName: controller.value.deviceOrientation.name,
        lensDirectionName: controller.description.lensDirection.name,
      );
      if (hand == null || hand.landmarks.isEmpty) return;
      _liveAirClickThrottle++;
      if (_liveAirClickThrottle % _liveAiSkip != 0) return;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      unawaited(_syncAirClickFromHand(hand, size));
    } catch (e) {
      debugPrint('Tracking live: $e');
    } finally {
      _liveBusy = false;
    }
  }

  Future<void> _syncAirClickFromHand(
    HandDetectionResult hand,
    Size imageSize,
  ) async {
    if (_airClickInFlight) return;
    _airClickInFlight = true;
    try {
      final landmarks = <String, dynamic>{};
      for (int i = 0; i < hand.landmarks.length; i++) {
        final lm = hand.landmarks[i];
        landmarks['$i'] = <String, double>{
          'x': imageSize.width == 0 ? 0 : lm.x / imageSize.width,
          'y': imageSize.height == 0 ? 0 : lm.y / imageSize.height,
          'z': lm.z,
        };
      }
      final response = await widget.repository.detectAirClick(
        landmarks,
        clientId: _clientId,
        sensitivity: _sensitivity,
      );
      _applyAction(response.action, confidence: response.confidence);
    } catch (_) {
      // backend indispo : on ignore.
    } finally {
      _airClickInFlight = false;
    }
  }

  /// Applique une action venue du live tracking : `move` avance le focus,
  /// `click` valide l'élément focalisé, `hold` retourne en arrière.
  void _applyAction(AirClickAction action, {double confidence = 0.0}) {
    if (!mounted) return;
    setState(() {
      _lastAction = action;
      _lastConfidence = confidence;
    });

    if (action == AirClickAction.idle) return;

    if (action == AirClickAction.move) {
      final now = DateTime.now();
      if (now.difference(_lastFocusChangeAt) < _moveFocusCooldown) return;
      _lastFocusChangeAt = now;
      _advanceFocus();
      return;
    }

    if (action == AirClickAction.click) {
      if (confidence < _minClickConfidenceLive) return;
      _commitFocusedAction();
      return;
    }

    if (action == AirClickAction.hold) {
      _onHoldRetour();
      return;
    }
  }

  void _onHoldRetour() {
    HapticFeedback.heavyImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home?tab=0');
    }
  }

  // ---------------------------------------------------------------------------
  // Réglages : sensibilité, vitesse de balayage, durée dwell.
  // ---------------------------------------------------------------------------

  Future<void> _showSettingsSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              final theme = Theme.of(ctx);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réglages mode geste',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sensibilité',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final s in MotorSensitivity.values)
                      _SensitivityTile(
                        sensitivity: s,
                        selected: _sensitivity == s,
                        onTap: () {
                          setSheetState(() {});
                          setState(() => _sensitivity = s);
                          _savePref(_kPrefSensitivity, s.toApiValue());
                        },
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Vitesse du balayage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: _scanInterval.inMilliseconds.toDouble(),
                      min: 800,
                      max: 4000,
                      divisions: 8,
                      label:
                          '${(_scanInterval.inMilliseconds / 1000).toStringAsFixed(1)} s par item',
                      onChanged: (v) {
                        setSheetState(() {});
                        setState(() {
                          _scanInterval = Duration(milliseconds: v.round());
                        });
                        _savePref(_kPrefScanIntervalMs, v.round());
                        if (_scanning) _startScan();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Durée de maintien (dwell)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: _dwellMs.toDouble(),
                      min: 600,
                      max: 5000,
                      divisions: 11,
                      label: '${(_dwellMs / 1000).toStringAsFixed(1)} s',
                      onChanged: (v) {
                        setSheetState(() {});
                        setState(() => _dwellMs = v.round());
                        _savePref(_kPrefDwellMs, v.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _dwellEnabled,
                      title: const Text('Sélection par maintien (dwell)'),
                      subtitle: const Text(
                        'Valide automatiquement quand le focus reste assez longtemps sur un item.',
                      ),
                      onChanged: (v) {
                        setSheetState(() {});
                        setState(() => _dwellEnabled = v);
                        if (v) {
                          _startDwellPolling();
                        } else {
                          _stopDwellPolling();
                        }
                      },
                    ),
                    SwitchListTile(
                      value: _speakFocus,
                      title: const Text('Annoncer le focus à voix haute'),
                      subtitle: const Text(
                        'Lit le nom de l’item focalisé (utile sans regarder l’écran).',
                      ),
                      onChanged: (v) {
                        setSheetState(() {});
                        setState(() => _speakFocus = v);
                        _savePref(_kPrefSpeakFocus, v);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle.
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _stopScan();
      _stopDwellPolling();
      if (_liveTracking) {
        unawaited(_stopLiveTracking());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_dwellEnabled) _startDwellPolling();
      _startScan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _dwellPollTimer?.cancel();
    final c = _cameraController;
    if (c != null) {
      if (_streamingImages && c.value.isStreamingImages) {
        try {
          c.stopImageStream();
        } catch (_) {}
      }
      c.dispose();
    }
    if (_liveInitialized) {
      try {
        _handTracker.dispose();
      } catch (_) {}
    }
    _tts.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode gestes'),
        actions: [
          IconButton(
            tooltip: _scanning
                ? 'Mettre en pause le balayage'
                : 'Démarrer le balayage',
            icon: Icon(
              _scanning ? Icons.pause_circle_outline : Icons.play_circle_outline,
            ),
            onPressed: () => _scanning ? _stopScan() : _startScan(),
          ),
          IconButton(
            tooltip: 'Réglages',
            icon: const Icon(Icons.tune),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildStatusCard(theme),
                  const SizedBox(height: 12),
                  _buildSensitivityChips(theme),
                  if (_cameraReady) ...[
                    const SizedBox(height: 12),
                    _buildCameraPreview(theme),
                  ],
                  if (_cameraError != null) ...[
                    const SizedBox(height: 12),
                    _buildCameraNotice(theme),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Boutons disponibles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _actions.length; i++)
                    _ActionCardTile(
                      action: _actions[i],
                      focused: i == _focusIndex,
                      dwellProgress: i == _focusIndex ? _dwellProgress : 0.0,
                      onTap: () => _setFocus(i, fromTap: true),
                    ),
                ],
              ),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Semantics(
      liveRegion: true,
      label: 'Statut du mode gestes',
      child: Card(
        color: theme.colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  _iconForAction(_lastAction),
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_lastConfidence > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Confiance backend : ${(_lastConfidence * 100).toStringAsFixed(0)} %',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensitivityChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _SensitivityChip(
          label: 'Sensibilité : ${_sensitivity.localizedLabel()}',
          icon: Icons.tune,
          onTap: _showSettingsSheet,
        ),
        _SensitivityChip(
          label:
              'Maintien : ${(_dwellMs / 1000).toStringAsFixed(1)} s',
          icon: Icons.timer_outlined,
          onTap: _showSettingsSheet,
        ),
        _SensitivityChip(
          label:
              'Balayage : ${(_scanInterval.inMilliseconds / 1000).toStringAsFixed(1)} s',
          icon: Icons.swap_horizontal_circle_outlined,
          onTap: _showSettingsSheet,
        ),
      ],
    );
  }

  Widget _buildCameraPreview(ThemeData theme) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final preview = controller.value.previewSize;
    final ratio = preview == null
        ? controller.value.aspectRatio
        : preview.width / preview.height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ratio,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FilledButton.tonalIcon(
                  onPressed: _toggleLiveTracking,
                  icon: Icon(
                    _liveTracking
                        ? Icons.center_focus_strong
                        : Icons.center_focus_weak,
                  ),
                  label: Text(_liveTracking ? 'Suivi actif' : 'Activer suivi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cameraError ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _cameraReady
                            ? _disableCamera
                            : _enableCamera,
                        icon: Icon(
                          _cameraReady
                              ? Icons.videocam_off_outlined
                              : Icons.videocam_outlined,
                        ),
                        label: Text(
                          _cameraReady
                              ? 'Désactiver caméra'
                              : 'Activer caméra',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _onHoldRetour,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Retour'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _commitFocusedAction,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Activer ${_actions[_focusIndex].label}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForAction(AirClickAction action) {
    switch (action) {
      case AirClickAction.click:
        return Icons.touch_app;
      case AirClickAction.hold:
        return Icons.back_hand_outlined;
      case AirClickAction.move:
        return Icons.swipe;
      case AirClickAction.idle:
        return Icons.pan_tool_outlined;
    }
  }
}

class _GestureAction {
  const _GestureAction({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.route,
    this.critical = false,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final String route;

  /// Action critique (SOS) : affichée avec un style rouge/urgence.
  final bool critical;
}

class _ActionCardTile extends StatelessWidget {
  const _ActionCardTile({
    required this.action,
    required this.focused,
    required this.dwellProgress,
    required this.onTap,
  });

  final _GestureAction action;
  final bool focused;
  final double dwellProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final critical = action.critical;
    final baseColor = critical
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fgColor = critical
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;
    final borderColor = focused
        ? (critical ? theme.colorScheme.error : theme.colorScheme.primary)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: action.label,
        hint: action.description,
        selected: focused,
        child: SizedBox(
          height: 92,
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: baseColor,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: borderColor, width: focused ? 3 : 0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: focused ? 4 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(action.icon, size: 30, color: fgColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.label,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: fgColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  action.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.25,
                                    color: fgColor.withValues(alpha: 0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          if (focused)
                            Icon(
                              Icons.check_circle,
                              color: critical
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (focused && dwellProgress > 0)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: dwellProgress,
                      minHeight: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        critical
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensitivityChip extends StatelessWidget {
  const _SensitivityChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _SensitivityTile extends StatelessWidget {
  const _SensitivityTile({
    required this.sensitivity,
    required this.selected,
    required this.onTap,
  });

  final MotorSensitivity sensitivity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensitivity.localizedLabel(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sensitivity.localizedHint(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
