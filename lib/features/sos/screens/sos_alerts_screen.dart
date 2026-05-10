import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local_trusted_contacts_store.dart';
import '../../../data/models/emergency_contact_model.dart';
import '../../../data/models/sos_alert_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/local_trusted_contacts_provider.dart';
import '../models/safety_risk_models.dart';
import '../models/voice_stress_api_result.dart';
import '../services/safety_ai_responder.dart';
import '../services/safety_motion_analyzer.dart';
import '../services/safety_risk_fusion_service.dart';
import '../services/sos_smart_matching_service.dart';
import '../services/voice_stress_recorder_service.dart';

/// Alertes SOS + **Smart Matching** + fusion signaux (texte, mouvement, lieu).
/// Voix TFLite & vision : stubs documentés — branchables en phase 2.
class SosAlertsScreen extends ConsumerStatefulWidget {
  const SosAlertsScreen({super.key});

  @override
  ConsumerState<SosAlertsScreen> createState() => _SosAlertsScreenState();
}

class _SosAlertsScreenState extends ConsumerState<SosAlertsScreen> {
  final _textNote = TextEditingController();
  final _fusion = const SafetyRiskFusionService();
  final _matching = const SosSmartMatchingService();
  final _motionAnalyzer = SafetyMotionAnalyzer();
  late final VoiceStressRecorderService _voiceStress;
  final _aiResponder = const SafetyAiResponder();

  int? _voiceScore;
  String? _voiceLabel;
  String? _voiceLabelFr;
  String _voiceSummaryFr = '';
  bool _voiceBusy = false;

  List<SosAlertModel> _alerts = [];
  List<EmergencyContactModel> _contacts = [];
  bool _loading = true;
  bool _sending = false;
  bool _motionWatch = false;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  int _motionRisk = 0;
  Timer? _decayTimer;
  Position? _position;
  FusionResult? _lastFusion;
  String _aiReply = '';
  bool _autoVoiceSosEnabled = true;
  DateTime? _lastAutoVoiceSosAt;

  static const _autoVoiceCooldown = Duration(seconds: 90);

  /// État GPS système (paramètres Android / iOS).
  bool _locationServicesEnabled = true;

  /// Dernière permission Geolocator connue (mise à jour dans [_refreshLocation]).
  LocationPermission _locationPermission = LocationPermission.denied;

  @override
  void initState() {
    super.initState();
    _voiceStress = VoiceStressRecorderService();
    _load();
    _loadAutoVoicePref();
    _refreshLocation();
    _textNote.addListener(_recomputeFusion);
  }

  Future<void> _loadAutoVoicePref() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoVoiceSosEnabled = p.getBool('sos_auto_voice_sos') ?? true;
    });
  }

  Future<void> _setAutoVoicePref(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('sos_auto_voice_sos', v);
    if (mounted) setState(() => _autoVoiceSosEnabled = v);
  }

  @override
  void dispose() {
    _textNote.removeListener(_recomputeFusion);
    _textNote.dispose();
    _stopMotionWatch();
    _decayTimer?.cancel();
    unawaited(_voiceStress.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sosRepo = ref.read(sosRepositoryProvider);
      final ecRepo = ref.read(emergencyContactsRepositoryProvider);
      final list = await sosRepo.getMyAlerts();
      final contacts = await ecRepo.getMyContacts();
      if (mounted) {
        setState(() {
          _alerts = list;
          _contacts = contacts;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    _recomputeFusion();
  }

  Future<void> _refreshLocation() async {
    if (kIsWeb) {
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever ||
            perm == LocationPermission.denied) {
          _recomputeFusion();
          return;
        }
        final p = await Geolocator.getCurrentPosition();
        if (mounted) setState(() => _position = p);
      } catch (_) {}
      _recomputeFusion();
      return;
    }

    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      var perm = await Geolocator.checkPermission();

      if (mounted) {
        setState(() {
          _locationServicesEnabled = servicesOn;
          _locationPermission = perm;
        });
      }

      if (!servicesOn) {
        _recomputeFusion();
        return;
      }

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (mounted) setState(() => _locationPermission = perm);
      }

      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _recomputeFusion();
        return;
      }

      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _position = p);
    } catch (_) {
      if (mounted) setState(() {});
    }
    _recomputeFusion();
  }

  /// Bouton unique : active le GPS système, demande la permission, puis actualise.
  Future<void> _onActivateLocationTap() async {
    if (kIsWeb) return;
    var on = await Geolocator.isLocationServiceEnabled();
    if (!on) {
      await Geolocator.openLocationSettings();
      if (mounted) await _refreshLocation();
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() => _locationPermission = perm);

    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sans localisation, les SMS et Maps ne pourront pas envoyer votre position exacte.',
            ),
          ),
        );
      }
      return;
    }

    await _refreshLocation();
    if (mounted && _position != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation activée — position mise à jour.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildLocationStatusCard(ThemeData theme) {
    if (kIsWeb) return const SizedBox.shrink();

    final permOk = _locationPermission == LocationPermission.whileInUse ||
        _locationPermission == LocationPermission.always;
    final hasFix = _position != null;

    if (_locationServicesEnabled && permOk && hasFix) {
      return Card(
        color: Colors.green.shade50,
        child: ListTile(
          leading: Icon(Icons.gps_fixed, color: Colors.green.shade800),
          title: const Text('Localisation active'),
          subtitle: Text(
            'Lat ${_position!.latitude.toStringAsFixed(5)}, '
            'lng ${_position!.longitude.toStringAsFixed(5)} — utilisée pour SOS et Maps.',
          ),
          trailing: IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(_refreshLocation()),
          ),
        ),
      );
    }

    String title;
    String subtitle;
    if (!_locationServicesEnabled) {
      title = 'GPS du téléphone désactivé';
      subtitle =
          'Activez « Position » dans les paramètres du téléphone (Android : Paramètres → Localisation).';
    } else if (_locationPermission == LocationPermission.deniedForever) {
      title = 'Localisation bloquée pour Ma3ak';
      subtitle =
          'Paramètres → Applications → Ma3ak → Autorisations → activez « Position ».';
    } else if (_locationPermission == LocationPermission.denied) {
      title = 'Autoriser la localisation';
      subtitle =
          'Indispensable pour envoyer votre position aux proches et ouvrir Google Maps en urgence.';
    } else if (!hasFix) {
      title = 'Position pas encore obtenue';
      subtitle =
          'Les autorisations sont OK — obtenez un point GPS (intérieur = parfois plus lent).';
    } else if (_locationPermission == LocationPermission.unableToDetermine) {
      title = 'Localisation non disponible';
      subtitle =
          'Ce mode ne permet pas la position — utilisez un appareil avec GPS.';
    } else {
      title = 'Localisation';
      subtitle = 'Touchez « Activer la localisation » ci-dessous.';
    }

    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.location_off, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _onActivateLocationTap,
              icon: const Icon(Icons.my_location),
              label: const Text('Activer la localisation'),
            ),
            if (_locationPermission == LocationPermission.deniedForever)
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Ouvrir les paramètres de l’app'),
              ),
          ],
        ),
      ),
    );
  }

  void _recomputeFusion() {
    if (!mounted) return;
    final r = _fusion.fuse(
      userText: _textNote.text,
      motionScore: _motionRisk,
      now: DateTime.now(),
      position: _position,
      voiceScore: _voiceScore,
    );
    final reply = _aiResponder.buildReply(
      userMessage: _textNote.text,
      fusion: r,
    );
    setState(() {
      _lastFusion = r;
      _aiReply = reply;
    });
  }

  void _startMotionWatch() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Capteurs mouvement : limités sur le web — utilisez l’app Android/iOS.',
          ),
        ),
      );
      return;
    }
    _motionAnalyzer.reset();
    _accelSub = accelerometerEventStream().listen((e) {
      final s = _motionAnalyzer.onAccelerometer(e.x, e.y, e.z);
      if (s > _motionRisk && mounted) {
        setState(() => _motionRisk = s);
        _recomputeFusion();
      }
    });
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (_motionRisk > 0) {
        setState(() => _motionRisk = (_motionRisk - 8).clamp(0, 100));
        _recomputeFusion();
      }
    });
    setState(() => _motionWatch = true);
  }

  void _stopMotionWatch() {
    _accelSub?.cancel();
    _accelSub = null;
    _decayTimer?.cancel();
    _decayTimer = null;
    if (mounted) setState(() => _motionWatch = false);
  }

  Future<void> _sendSos({
    required bool useSmartMatching,
    bool fromAutoVoice = false,
  }) async {
    setState(() => _sending = true);
    try {
      await _refreshLocation();
      final lat = _position?.latitude ?? 36.8065;
      final lng = _position?.longitude ?? 10.1815;
      final user = ref.read(authStateProvider).valueOrNull;

      final localTrusted = ref.read(localTrustedContactsProvider);
      final merged = LocalTrustedContactsStore.mergeWithApi(
        localTrusted,
        _contacts,
      );

      final repo = ref.read(sosRepositoryProvider);
      try {
        final userTypeHandicap = user?.typeHandicap;
        final userBesoinSpecifique = user?.besoinSpecifique;
        await repo.create(
          latitude: lat,
          longitude: lng,
          voiceScore: _voiceScore?.toDouble(),
          voiceLabel: _voiceLabel,
          voiceLabelFr: _voiceLabelFr,
          alertSource: fromAutoVoice ? 'VOICE_AUTO' : 'MANUAL',
          beneficiaryTypeHandicap: userTypeHandicap,
          beneficiaryBesoinSpecifique: userBesoinSpecifique,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Serveur SOS indisponible — poursuite des appels / SMS vers vos proches.',
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }

      final fusion = _lastFusion ??
          _fusion.fuse(
            userText: _textNote.text,
            motionScore: _motionRisk,
            now: DateTime.now(),
            position: _position,
            voiceScore: _voiceScore,
          );

      if (merged.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun numéro enregistré. Ajoutez un proche (téléphone) dans Contacts d’urgence.',
              ),
              backgroundColor: Colors.black87,
            ),
          );
        }
        await _load();
        if (mounted) setState(() => _sending = false);
        return;
      }

      if (useSmartMatching && user != null) {
        final suggestions = _matching.buildSuggestions(
          tier: fusion.tier,
          contacts: merged,
          beneficiary: user,
        );
        var didManualCall = false;
        for (final s in suggestions) {
          if (s.isEmergencyServices) continue;
          final c = s.contact;
          if (c == null) continue;
          if (s.channel == MatchChannel.sms ||
              s.channel == MatchChannel.smsAndCall) {
            unawaited(_smsContact(
              c,
              lat,
              lng,
              user.displayName,
              voiceScore: _voiceScore,
              autoVoiceTrigger: fromAutoVoice,
            ));
          }
          if (s.channel == MatchChannel.call ||
              s.channel == MatchChannel.smsAndCall) {
            didManualCall = true;
            unawaited(_callContact(c));
          }
        }

        // iOS/Android peuvent parfois ne pas déclencher l'appel selon le canal choisi.
        // En VOICE_AUTO, on force au moins un appel vers le premier contact disponible.
        if (fromAutoVoice && !didManualCall) {
          for (final c in merged) {
            final tel = c.accompagnant?.telephone;
            if (tel != null && tel.trim().isNotEmpty) {
              unawaited(_callContact(c));
              break;
            }
          }
        }
      } else {
        unawaited(
          _smsContact(
            merged.first,
            lat,
            lng,
            user?.displayName ?? 'Utilisateur',
            voiceScore: _voiceScore,
            autoVoiceTrigger: fromAutoVoice,
          ),
        );
        unawaited(_callContact(merged.first));
      }

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fromAutoVoice
                  ? 'Alerte automatique envoyée — SMS (lien Maps) et appels lancés selon vos contacts.'
                  : useSmartMatching
                      ? 'SOS envoyé — matching intelligent appliqué (SMS/appels).'
                      : 'Alerte SOS envoyée.',
            ),
            backgroundColor: Colors.green.shade700,
            duration: Duration(seconds: fromAutoVoice ? 6 : 4),
          ),
        );
      }

      // Urgence grave / alerte vocale auto : ouvrir Google Maps avec la position (après SMS/appel).
      if (fromAutoVoice || fusion.tier == SafetyRiskTier.critical) {
        Future<void>.delayed(const Duration(milliseconds: 900), () async {
          if (!mounted) return;
          await _openCurrentLocationInMaps(quiet: true);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _smsContact(
    EmergencyContactModel c,
    double lat,
    double lng,
    String name, {
    int? voiceScore,
    bool autoVoiceTrigger = false,
  }) async {
    final tel = c.accompagnant?.telephone;
    if (tel == null || tel.isEmpty) return;
    final voiceBit = voiceScore != null
        ? (autoVoiceTrigger
            ? 'Alerte AUTO (stress vocal ~$voiceScore %). '
            : 'Indice vocal ~$voiceScore %. ')
        : '';
    final msg =
        '$name — $voiceBit'
        'Alerte Ma3ak (SOS). Position Google Maps : '
        'https://www.google.com/maps?q=$lat,$lng';
    final uri = Uri.parse(
      'sms:${tel.replaceAll(RegExp(r'\s'), '')}?body=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callContact(EmergencyContactModel c) async {
    final tel = c.accompagnant?.telephone;
    if (tel == null || tel.isEmpty) return;
    final uri = Uri.parse('tel:${tel.replaceAll(RegExp(r'\s'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callSamu() async {
    final uri = Uri.parse('tel:190');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  /// Ouvre le navigateur ou l’app Google Maps avec la **position actuelle** (GPS réel).
  /// [quiet] : moins de SnackBars (ex. ouverture auto après SOS).
  Future<void> _openCurrentLocationInMaps({bool quiet = false}) async {
    try {
      await _refreshLocation();
      double? lat = _position?.latitude;
      double? lng = _position?.longitude;

      if ((lat == null || lng == null) && !kIsWeb) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = p.latitude;
          lng = p.longitude;
          if (mounted) setState(() => _position = p);
        }
      }

      if (lat == null || lng == null) {
        if (mounted && !quiet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Position GPS indisponible. Autorisez la localisation pour ouvrir Maps.',
              ),
            ),
          );
        }
        return;
      }

      final latStr = lat.toString();
      final lngStr = lng.toString();
      final candidates = <Uri>[
        Uri.parse('https://www.google.com/maps?q=$latStr,$lngStr'),
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latStr,$lngStr',
        ),
        Uri.parse('geo:$latStr,$lngStr?q=$latStr,$lngStr'),
        Uri.parse('https://maps.google.com/?q=$latStr,$lngStr'),
      ];

      Future<bool> tryLaunch(Uri uri) async {
        try {
          var ok = await canLaunchUrl(uri);
          if (ok) {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          try {
            return await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (_) {
            return false;
          }
        }
      }

      for (final uri in candidates) {
        if (await tryLaunch(uri)) {
          return;
        }
      }

      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d’ouvrir Maps. Vérifiez un navigateur ou l’app Google Maps, '
              'et réinstallez l’app après la mise à jour (Android 11+ : permissions déclarées).',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l’ouverture de Maps.'),
          ),
        );
      }
    }
  }

  /// Stress vocal suffisant pour enclencher SOS sans toucher au bouton rouge.
  bool _shouldTriggerAutoVoiceSos(VoiceStressApiResult r) {
    if (r.score >= 48) return true;
    const labels = {'panic', 'high_stress', 'stress'};
    return labels.contains(r.label);
  }

  Future<void> _runVoiceStress() async {
    if (kIsWeb) return;
    setState(() => _voiceBusy = true);
    try {
      final r = await _voiceStress.recordAndAnalyze();
      if (!mounted) return;
      setState(() {
        _voiceScore = r.score;
        _voiceLabel = r.label;
        _voiceLabelFr = r.labelFr;
        _voiceSummaryFr =
            '${r.labelFr} — score vocal ${r.score} %.\n${r.detailFr}';
      });
      _recomputeFusion();

      var didAutoSos = false;
      if (_autoVoiceSosEnabled && _shouldTriggerAutoVoiceSos(r)) {
        final now = DateTime.now();
        final last = _lastAutoVoiceSosAt;
        if (last == null || now.difference(last) >= _autoVoiceCooldown) {
          _lastAutoVoiceSosAt = now;
          await HapticFeedback.heavyImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stress vocal ${r.score} % (${r.labelFr}) — '
                  'alerte automatique : position GPS, SMS avec Google Maps et appels aux contacts…',
                ),
                backgroundColor: Colors.deepOrange.shade900,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          await _sendSos(useSmartMatching: true, fromAutoVoice: true);
          didAutoSos = true;
        } else if (mounted) {
          final elapsed = now.difference(last);
          final wait = _autoVoiceCooldown - elapsed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Stress vocal élevé, mais une alerte auto a déjà été envoyée il y a '
                '${elapsed.inSeconds} s. Réessayez dans '
                '${wait.inSeconds.clamp(0, 9999)} s ou appuyez sur SOS.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted && !didAutoSos) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              r.fromOfflineFallback
                  ? 'Voix (hors ligne) : ${r.labelFr} (${r.score} %) — lancez Python sur :8000 pour MFCC'
                  : 'Voix : ${r.labelFr} (${r.score} %)',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: r.fromOfflineFallback ? 5 : 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('permission_microphone_denied')) {
        final st = await Permission.microphone.status;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Micro refusé : autorisez l’enregistrement audio pour Ma3ak.',
            ),
            action: st.isPermanentlyDenied
                ? SnackBarAction(
                    label: 'Paramètres',
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analyse vocale : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  Color _tierColor(SafetyRiskTier t) {
    switch (t) {
      case SafetyRiskTier.calm:
        return Colors.green;
      case SafetyRiskTier.lightStress:
        return Colors.amber.shade800;
      case SafetyRiskTier.mediumDanger:
        return Colors.deepOrange;
      case SafetyRiskTier.critical:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final localTrusted = ref.watch(localTrustedContactsProvider);
    final mergedContacts = LocalTrustedContactsStore.mergeWithApi(
      localTrusted,
      _contacts,
    );
    final fusion = _lastFusion;
    final suggestions = fusion != null && user != null
        ? _matching.buildSuggestions(
            tier: fusion.tier,
            contacts: mergedContacts,
            beneficiary: user,
          )
        : <MatchingSuggestion>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS & sécurité intelligente'),
        actions: [
          TextButton(
            onPressed: () => context.push('/accompagnants'),
            child: const Text('Contacts'),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(
              onRefresh: () async {
                await _load();
                await _refreshLocation();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _buildLocationStatusCard(theme),
                  const SizedBox(height: 16),
                  Text(
                    'Smart Matching',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fusion : texte (NLP léger) + mouvement + lieu/nuit + voix (MFCC / Python). '
                    'Vision caméra : optionnelle plus tard.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Votre message / état',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textNote,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Ex. j\'ai peur, aidez-moi, je suis fatigué…',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _recomputeFusion(),
                          ),
                          const SizedBox(height: 12),
                          if (!kIsWeb)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Surveillance mouvement (choc / secousse)'),
                              subtitle: const Text(
                                'Accéléromètre — indice de chute ou mouvement brutal',
                              ),
                              value: _motionWatch,
                              onChanged: (v) {
                                if (v) {
                                  _startMotionWatch();
                                } else {
                                  _stopMotionWatch();
                                  setState(() => _motionRisk = 0);
                                  _recomputeFusion();
                                }
                              },
                            )
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.sensors_off_outlined,
                                  color: theme.colorScheme.outline),
                              title: const Text('Mouvement'),
                              subtitle: const Text(
                                'Non disponible sur navigateur — installez l’app mobile.',
                              ),
                            ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.graphic_eq,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Stress vocal (IA)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _voiceStress.helperFr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Alerte automatique si stress vocal',
                              ),
                              subtitle: const Text(
                                'Après l’analyse voix : envoi position, SMS (lien Maps) et appels si le score est élevé — sans appuyer sur SOS.',
                              ),
                              value: _autoVoiceSosEnabled,
                              onChanged: (v) => _setAutoVoicePref(v),
                            ),
                            if (_voiceSummaryFr.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Material(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _voiceSummaryFr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed:
                                  _voiceBusy || _sending ? null : _runVoiceStress,
                              icon: _voiceBusy
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : const Icon(Icons.mic_rounded),
                              label: Text(
                                _voiceBusy
                                    ? 'Enregistrement + analyse…'
                                    : 'Analyser ma voix (~5 s)',
                              ),
                            ),
                          ] else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.mic_off_outlined,
                                  color: theme.colorScheme.outline),
                              title: const Text('Stress vocal (IA)'),
                              subtitle: const Text(
                                'Enregistrement audio : utilisez l’application Android ou iOS.',
                              ),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${localTrusted.length} proche(s) sur l’appareil · '
                              '${mergedContacts.length} contact(s) au total pour le SOS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_alt,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Réponse assistant (analyse automatique)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            _aiReply.isEmpty
                                ? 'Saisissez du texte ou attendez le calcul du score…'
                                : _aiReply,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (fusion != null) ...[
                    Card(
                      color: _tierColor(fusion.tier).withOpacity(0.12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Score global : ${fusion.globalScore} %',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text(fusion.tier.labelFr),
                                  backgroundColor:
                                      _tierColor(fusion.tier).withOpacity(0.25),
                                ),
                              ],
                            ),
                            Text(fusion.tier.hintFr),
                            const Divider(height: 20),
                            Text(
                              'Signaux',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'Texte ${fusion.signals.text}% · '
                              'Mouvement ${fusion.signals.motion}% · '
                              'Lieu ${fusion.signals.location}%'
                              '${fusion.signals.voiceStress != null ? ' · Voix ${fusion.signals.voiceStress}%' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            ...fusion.breakdownFr.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $line',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Qui contacter (matching)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map((s) {
                      final hasContact =
                          s.contact != null && !s.isEmergencyServices;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            s.isEmergencyServices
                                ? Icons.local_hospital
                                : Icons.person_pin_circle_outlined,
                            color: s.isEmergencyServices
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          title: Text(s.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.reasonFr),
                              if (hasContact) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Toucher pour ouvrir votre position actuelle sur Google Maps (navigateur)',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: hasContact,
                          onTap: hasContact
                              ? () => unawaited(_openCurrentLocationInMaps())
                              : null,
                          trailing: s.isEmergencyServices
                              ? SizedBox(
                                  width: 64,
                                  child: TextButton(
                                    onPressed: _callSamu,
                                    child: const Text('190'),
                                  ),
                                )
                              : s.contact != null
                                  ? SizedBox(
                                      width: 76,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            s.channel == MatchChannel.smsAndCall
                                                ? 'SMS+Appel'
                                                : s.channel == MatchChannel.call
                                                    ? 'Appel'
                                                    : 'SMS',
                                            maxLines: 1,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/accompagnants'),
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text(
                        'Gérer les proches (téléphone) et contacts serveur',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _sending
                        ? null
                        : () => _sendSos(useSmartMatching: true),
                    icon: const Icon(Icons.emergency_share),
                    label: const Text('SOS intelligent (appel + SMS + position)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _sending ? null : () => _sendSos(useSmartMatching: false),
                    icon: const Icon(Icons.emergency_outlined),
                    label: const Text('SOS simple (alerte + 1er contact)'),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Historique',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aucune alerte envoyée',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._alerts.map(
                      (a) => Card(
                        child: ListTile(
                          leading:
                              const Icon(Icons.emergency, color: Colors.red),
                          title: Text(
                            '${a.latitude.toStringAsFixed(4)}, ${a.longitude.toStringAsFixed(4)}',
                          ),
                          subtitle: a.createdAt != null
                              ? Text(a.createdAt!.toIso8601String())
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_sending)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
