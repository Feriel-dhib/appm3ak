import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/errors/ai_module_exception.dart';
import '../../../data/models/ai/voice_intent_models.dart';
import '../../../data/repositories/ai_module_repository.dart';
import '../../../providers/voice_mode_providers.dart';

/// Mode vocal pour utilisateurs malvoyants / aveugles.
///
/// L'écran reprend la structure visuelle des autres modes adaptés
/// (`DeafTextModeScreen`, `MotorGestureModeScreen`) :
///   * une carte de statut en haut (texte courant énoncé par TTS),
///   * une liste de cards d'action (`FilledButton.tonalIcon`) qui constitue
///     l'inventaire complet des destinations disponibles ; ces cards sont
///     **à la fois cliquables** (tactile guidé / accompagnant) **et lues**
///     par TTS quand on demande "lire l'écran",
///   * une barre du bas avec le micro et l'écoute continue.
///
/// Pour la détection d'intention, on consulte d'abord le backend
/// `/intent` (multi-langue FR/EN/AR) ; si le backend ne répond pas, on
/// retombe sur la détection locale par mots-clés.
class BlindVoiceModeScreen extends ConsumerStatefulWidget {
  const BlindVoiceModeScreen({super.key, required this.repository});

  final AiModuleRepository repository;

  @override
  ConsumerState<BlindVoiceModeScreen> createState() =>
      _BlindVoiceModeScreenState();
}

class _BlindVoiceModeScreenState extends ConsumerState<BlindVoiceModeScreen> {
  static const Duration _continuousPreActionDelay = Duration(seconds: 30);
  static const Duration _continuousBetweenCyclesDelay = Duration(seconds: 30);

  /// Délai avant d'écouter l'utilisateur après la lecture automatique.
  static const Duration _postReadAnswerDelay = Duration(seconds: 10);

  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  final Completer<void> _ttsReady = Completer<void>();
  Timer? _autoListenTimer;
  bool _autoReadStarted = false;
  bool _disposed = false;

  bool _busy = false;
  bool _continuousMode = false;
  bool _continuousLoopRunning = false;
  bool _voiceBackendDegraded = false;
  DateTime? _lastUnsupportedLangNoticeAt;
  /// Référence conservée pour [dispose] : [WidgetRef] n’est plus utilisable après démontage.
  VoiceModeNotifier? _voiceModeNotifier;
  /// Pour activer le mode vocal sans [ref] dans un post-frame (widget peut être déjà jeté).
  ProviderContainer? _providerContainer;
  String _recognizedText = '';
  String _spokenFeedback = 'Bienvenue dans Ma3ak, mode vocal. '
      'Touchez le bouton micro pour parler, ou un bouton pour ouvrir une rubrique. '
      'Dites « lire l\'écran » pour entendre toutes les commandes.';

  /// Catalogue unique : sert à la fois pour l'UI (cards), pour la détection
  /// d'intent côté backend (mots-clés), et pour la lecture de l'écran.
  late final List<_VoiceCommand> _commands = _buildCommands();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer ??= ProviderScope.containerOf(context);
  }

  @override
  void initState() {
    super.initState();
    // Réduit les timeouts au premier STT /intent sur Render (cold start).
    unawaited(widget.repository.prewarmRemoteInstance());
    unawaited(_configureTts());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final container = _providerContainer;
      if (container == null) return;
      // Pas de ref.read ici : si l’écran est fermé avant la 1ʳᵉ frame, ref peut être invalide.
      final voiceMode = container.read(voiceModeProvider.notifier);
      _voiceModeNotifier = voiceMode;
      voiceMode.activateVoiceMode('/adaptive/blind-voice-mode');
      unawaited(_runStartupSequence());
    });
  }

  /// Initialise FlutterTts en gérant explicitement la session audio iOS pour
  /// que la voix soit audible **même en mode silencieux**, puis force la
  /// langue / le débit / le volume avant la première lecture.
  Future<void> _configureTts() async {
    try {
      if (Platform.isIOS) {
        // Important : sans ces appels, sur iOS la voix peut rester muette
        // quand le commutateur silencieux est activé → "rien n'a été lu".
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
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setLanguage('fr-FR');
    } catch (_) {
      // Ne bloque pas l'écran : on tentera quand même de parler.
    } finally {
      if (!_ttsReady.isCompleted) _ttsReady.complete();
    }
  }

  Future<void> _speakLocal(String text) async {
    try {
      await _ttsReady.future;
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Séquence de bienvenue lue automatiquement après le login :
  /// 1. attente fin d'init TTS,
  /// 2. lecture complète de l'écran,
  /// 3. délai de [_postReadAnswerDelay] secondes (le temps que l'utilisateur
  ///    réagisse / parle),
  /// 4. ouverture automatique de l'enregistrement micro pour récupérer la
  ///    réponse (sauf si l'utilisateur a déjà appuyé sur un bouton ou activé
  ///    le mode continu pendant ce délai).
  Future<void> _runStartupSequence() async {
    if (_autoReadStarted) return;
    _autoReadStarted = true;
    await _ttsReady.future;
    if (_disposed || !mounted) return;

    await _readEntireScreen(skipHaptic: true);
    if (_disposed || !mounted) return;

    _safeSetState(() {
      _spokenFeedback =
          'Lecture terminée. À vous, parlez après le bip dans 10 secondes…';
    });

    _autoListenTimer?.cancel();
    _autoListenTimer = Timer(_postReadAnswerDelay, () {
      if (_disposed || !mounted) return;
      if (_busy || _continuousMode) return;
      unawaited(_listenAndProcess());
    });
  }

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // Tap sur une card → identique à un intent reconnu vocalement.
  // ---------------------------------------------------------------------------

  Future<void> _handleCommandTap(_VoiceCommand command) async {
    HapticFeedback.lightImpact();
    _autoListenTimer?.cancel();
    final reply = command.replyMessage;
    _safeSetState(() => _spokenFeedback = reply);
    await _speakLocal(reply);
    _navigateForCommand(command);
  }

  void _navigateForCommand(_VoiceCommand command) {
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      context.go(command.route);
    });
  }

  // ---------------------------------------------------------------------------
  // Lecture complète de l'écran (TTS) — toutes les commandes une à une.
  // ---------------------------------------------------------------------------

  Future<void> _readEntireScreen({bool skipHaptic = false}) async {
    if (!skipHaptic) HapticFeedback.selectionClick();
    _autoListenTimer?.cancel();
    final summary = _localScreenSummary();
    _safeSetState(() => _spokenFeedback = 'Lecture de l\'écran en cours...');

    // Best effort : si le backend renvoie un résumé propre, on le préfère.
    String spoken = summary;
    try {
      final response = await widget.repository.summarizeScreen(
        ScreenSummaryRequest(
          title: 'Mode vocal Ma3ak',
          items: _commands
              .map(
                (c) => ScreenSummaryItem(label: c.title, hint: c.description),
              )
              .toList(growable: false),
        ),
      );
      if (response.summary.trim().isNotEmpty) {
        spoken = response.summary;
      }
    } catch (_) {
      // backend muet → on garde la version locale.
    }

    if (_disposed || !mounted) return;

    _safeSetState(() => _spokenFeedback = spoken);
    await _speakLocal(spoken);
  }

  String _localScreenSummary() {
    final lines = <String>[
      'Mode vocal Ma3ak. Boutons disponibles.',
    ];
    for (final c in _commands) {
      lines.add('${c.title}. ${c.description}');
    }
    lines.add(
      'Pour activer une rubrique, dites son nom ou touchez son bouton.',
    );
    return lines.join(' ');
  }

  /// STT robuste : en cas d'échec serveur/timeout ponctuel, on retente une fois.
  Future<String> _transcribeWithRetry(
    String filePath, {
    Future<void> Function(int attempt, AiModuleException error)? onRetry,
  }) async {
    AiModuleException? lastAiError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final stt = await widget.repository.transcribeAudioFile(filePath);
        return stt.text.trim();
      } on AiModuleException catch (e) {
        lastAiError = e;
        final retriable =
            e.type == AiModuleErrorType.timeout ||
            e.type == AiModuleErrorType.offline ||
            e.type == AiModuleErrorType.server;
        if (!retriable || attempt == 1) rethrow;
        if (onRetry != null) {
          await onRetry(attempt + 1, e);
        }
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }
    if (lastAiError != null) throw lastAiError;
    return '';
  }

  String _messageForAiError(AiModuleException e) {
    if (e.statusCode == 400) {
      return 'Langue non supportée ou audio non exploitable. Parlez en français, anglais ou arabe.';
    }
    return switch (e.type) {
      AiModuleErrorType.timeout => 'Le service vocal est lent. Réessayez dans un instant.',
      AiModuleErrorType.offline => 'Le service vocal est indisponible pour le moment.',
      AiModuleErrorType.server => 'Le service vocal a rencontré une erreur interne.',
      _ => 'Je n\'ai pas pu traiter la commande vocale. Réessayez.',
    };
  }

  // ---------------------------------------------------------------------------
  // STT → intent → action.
  // ---------------------------------------------------------------------------

  Future<void> _listenAndProcess() async {
    if (_busy || !mounted) return;
    _autoListenTimer?.cancel();
    _safeSetState(() => _busy = true);
    String? path;
    try {
      final allowed = await _ensureMicPermission();
      if (!allowed) {
        _safeSetState(() {
          _spokenFeedback =
              'Microphone refusé. Activez la permission pour continuer.';
        });
        await _speakLocal(_spokenFeedback);
        return;
      }
      final tempDir = await getTemporaryDirectory();
      path =
          '${tempDir.path}/ma3ak_cmd_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      await Future<void>.delayed(const Duration(seconds: 4));
      final filePath = await _recorder.stop() ?? path;
      final recognized = await _transcribeWithRetry(
        filePath,
        onRetry: (attempt, _) async {
          _safeSetState(() {
            _spokenFeedback =
                'Problème temporaire du service vocal, nouvelle tentative $attempt...';
          });
        },
      );
      if (recognized.isEmpty) {
        _safeSetState(() {
          _recognizedText = '(aucun texte reconnu)';
          _spokenFeedback =
              'Je n\'ai pas entendu de commande. Parlez plus près du micro puis réessayez.';
        });
        await _speakLocal(_spokenFeedback);
        return;
      }

      if (!_isSupportedLanguage(recognized)) {
        _safeSetState(() {
          _recognizedText = recognized.isEmpty
              ? '(aucun texte reconnu)'
              : recognized;
          _spokenFeedback =
              'Je réagis uniquement en français, anglais ou arabe.';
        });
        final now = DateTime.now();
        final shouldSpeakNotice = _lastUnsupportedLangNoticeAt == null ||
            now.difference(_lastUnsupportedLangNoticeAt!) >
                const Duration(seconds: 6);
        if (shouldSpeakNotice) {
          _lastUnsupportedLangNoticeAt = now;
          await _speakLocal(_spokenFeedback);
        }
        return;
      }

      final normalized = recognized.toLowerCase();
      if (normalized.contains('stop écoute') ||
          normalized.contains('stop ecoute') ||
          normalized.contains('arrête écoute') ||
          normalized.contains('arrete ecoute')) {
        _safeSetState(() {
          _recognizedText = recognized;
          _continuousMode = false;
          _spokenFeedback = 'Écoute continue arrêtée.';
        });
        await _speakLocal(_spokenFeedback);
        return;
      }

      if (_isReadScreenPhrase(normalized)) {
        _safeSetState(() {
          _recognizedText = recognized;
        });
        await _readEntireScreen();
        return;
      }

      final command = await _resolveCommand(recognized);
      final reply = command?.replyMessage ??
          'Je n\'ai pas reconnu cette commande. '
              'Dites « lire l\'écran » pour entendre les choix.';
      _safeSetState(() {
        _recognizedText = recognized.isEmpty
            ? '(aucun texte reconnu)'
            : recognized;
        _spokenFeedback = reply;
      });

      if (_continuousMode && command == null) {
        return;
      }

      // TTS backend (best effort) + TTS local pour feedback immédiat sur mobile.
      try {
        await widget.repository.speakText(reply);
        _safeSetState(() => _voiceBackendDegraded = false);
      } catch (_) {
        _safeSetState(() => _voiceBackendDegraded = true);
      }
      await _speakLocal(reply);

      if (command != null) {
        if (_continuousMode) {
          await _waitInContinuousMode(_continuousPreActionDelay);
        }
        _navigateForCommand(command);
      }
    } on AiModuleException catch (e) {
      _safeSetState(() {
        _voiceBackendDegraded = true;
        _spokenFeedback = _messageForAiError(e);
      });
      await _speakLocal(_spokenFeedback);
    } catch (_) {
      _safeSetState(() {
        _spokenFeedback =
            'Je n\'ai pas pu traiter la commande vocale. Réessayez.';
      });
      await _speakLocal(_spokenFeedback);
    } finally {
      try {
        await _recorder.stop();
      } catch (_) {}
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) {
          await f.delete();
        }
      }
      _safeSetState(() => _busy = false);
    }
  }

  /// Combine la détection backend `/intent` (préférée) et la détection locale
  /// par mots-clés (fallback robuste hors connexion).
  Future<_VoiceCommand?> _resolveCommand(String spoken) async {
    if (spoken.trim().isEmpty) return null;

    // 1. Tentative backend.
    try {
      final response = await widget.repository.matchVoiceIntent(
        VoiceIntentRequest(
          text: spoken,
          commands: _commands
              .map(
                (c) =>
                    VoiceCommandDescriptor(id: c.id, keywords: c.keywords),
              )
              .toList(growable: false),
          minScore: 0.4,
        ),
      );
      if (response.hasMatch) {
        for (final c in _commands) {
          if (c.id == response.match) return c;
        }
      }
    } catch (_) {
      // ignore: on retombera sur le fallback local.
    }

    // 2. Fallback local.
    return _localFallbackMatch(spoken);
  }

  _VoiceCommand? _localFallbackMatch(String spoken) {
    final normalized = _normalize(spoken);
    if (normalized.isEmpty) return null;
    _VoiceCommand? best;
    var bestScore = 0;
    for (final command in _commands) {
      for (final keyword in command.keywords) {
        final nk = _normalize(keyword);
        if (nk.isEmpty) continue;
        if (normalized.contains(nk) && nk.length > bestScore) {
          bestScore = nk.length;
          best = command;
        }
      }
    }
    return best;
  }

  bool _isReadScreenPhrase(String normalizedSpoken) {
    const triggers = [
      'lire écran',
      'lire ecran',
      "lire l'écran",
      "lire l'ecran",
      'lire les boutons',
      'lire boutons',
      'aide',
      'commandes',
      'aide complète',
      'aide complete',
      'read screen',
      'help',
    ];
    for (final t in triggers) {
      if (normalizedSpoken.contains(t)) return true;
    }
    return false;
  }

  /// Normalisation FR/EN/AR très simple (sans dépendance) : casse + diacritiques
  /// latins courants pour le fallback local.
  String _normalize(String text) {
    final lower = text.toLowerCase().trim();
    const map = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ÿ': 'y',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ---------------------------------------------------------------------------
  // Écoute continue (boucle).
  // ---------------------------------------------------------------------------

  Future<void> _toggleContinuousMode() async {
    if (_continuousMode) {
      _safeSetState(() => _continuousMode = false);
      await _speakLocal('Mode écoute continue désactivé.');
      return;
    }
    _safeSetState(() => _continuousMode = true);
    await _speakLocal(
      'Mode écoute continue activé. Dites une commande. Dites stop écoute pour arrêter.',
    );
    _startContinuousLoop();
  }

  Future<void> _startContinuousLoop() async {
    if (_continuousLoopRunning) return;
    _continuousLoopRunning = true;
    try {
      while (mounted && _continuousMode) {
        await _listenAndProcess();
        if (!mounted || !_continuousMode) break;
        await _waitInContinuousMode(_continuousBetweenCyclesDelay);
      }
    } finally {
      _continuousLoopRunning = false;
    }
  }

  Future<void> _waitInContinuousMode(Duration duration) async {
    const step = Duration(milliseconds: 250);
    var remainingMs = duration.inMilliseconds;
    while (mounted && _continuousMode && remainingMs > 0) {
      final currentStepMs = remainingMs < step.inMilliseconds
          ? remainingMs
          : step.inMilliseconds;
      await Future<void>.delayed(Duration(milliseconds: currentStepMs));
      remainingMs -= currentStepMs;
    }
  }

  // ---------------------------------------------------------------------------
  // Catalogue des commandes (UI + intent + lecture écran).
  // ---------------------------------------------------------------------------

  List<_VoiceCommand> _buildCommands() {
    return const [
      _VoiceCommand(
        id: 'home',
        title: 'Accueil',
        description: 'Page principale avec services et raccourcis.',
        icon: Icons.home_outlined,
        route: '/home?tab=0',
        keywords: ['accueil', 'home', 'الرئيسية'],
        replyMessage: 'Navigation vers Accueil.',
      ),
      _VoiceCommand(
        id: 'health',
        title: 'Santé',
        description: 'Onglet Santé : services médicaux et chat IA.',
        icon: Icons.medical_services_outlined,
        route: '/home?tab=1',
        keywords: ['sante', 'santé', 'health', 'medecin', 'الصحة', 'صحة'],
        replyMessage: 'Navigation vers Santé.',
      ),
      _VoiceCommand(
        id: 'health_chat',
        title: 'Chat santé',
        description: 'Posez une question médicale au chat IA.',
        icon: Icons.chat_bubble_outline,
        route: '/health-chat',
        keywords: ['chat sante', 'chat santé', 'ia sante', 'health chat'],
        replyMessage: 'Ouverture du chat santé.',
      ),
      _VoiceCommand(
        id: 'transport',
        title: 'Transport',
        description: 'Onglet Transport : tous les déplacements adaptés.',
        icon: Icons.directions_bus_outlined,
        route: '/home?tab=2',
        keywords: ['transport', 'bus', 'taxi', 'trajet', 'voiture', 'النقل'],
        replyMessage: 'Navigation vers Transport.',
      ),
      _VoiceCommand(
        id: 'transport_request',
        title: 'Nouvelle demande transport',
        description: 'Créer une demande de course adaptée.',
        icon: Icons.edit_road_outlined,
        route: '/transport/request',
        keywords: [
          'nouvelle demande transport',
          'demande transport',
          'reserver transport',
        ],
        replyMessage: 'Ouverture nouvelle demande transport.',
      ),
      _VoiceCommand(
        id: 'obstacle_detection',
        title: 'Détection obstacles',
        description: 'Caméra qui annonce les obstacles à voix haute.',
        icon: Icons.visibility_off_outlined,
        route: '/transport/obstacle-detection',
        keywords: ['obstacle', 'détection obstacle', 'detection obstacle'],
        replyMessage: 'Ouverture détection obstacles.',
      ),
      _VoiceCommand(
        id: 'accessible_places',
        title: 'Lieux accessibles',
        description: 'Trouver des lieux adaptés autour de vous.',
        icon: Icons.location_on_outlined,
        route: '/accessible-places',
        keywords: ['lieux', 'lieu', 'place', 'accessible', 'مكان'],
        replyMessage: 'Navigation vers les lieux accessibles.',
      ),
      _VoiceCommand(
        id: 'community',
        title: 'Communauté',
        description: 'Discussions et entraide entre utilisateurs.',
        icon: Icons.forum_outlined,
        route: '/home?tab=4&communityTab=0',
        keywords: ['communaute', 'communauté', 'milieux', 'community'],
        replyMessage: 'Navigation vers Communauté.',
      ),
      _VoiceCommand(
        id: 'notifications',
        title: 'Notifications',
        description: 'Liste des dernières alertes et messages.',
        icon: Icons.notifications_active_outlined,
        route: '/notifications',
        keywords: ['notification', 'notifications', 'alerte', 'إشعار'],
        replyMessage: 'Ouverture des notifications.',
      ),
      _VoiceCommand(
        id: 'profile',
        title: 'Mon profil',
        description: 'Compte personnel et paramètres.',
        icon: Icons.person_outline,
        route: '/profile',
        keywords: ['profil', 'profile', 'compte', 'الملف الشخصي'],
        replyMessage: 'Ouverture de Mon profil.',
      ),
      _VoiceCommand(
        id: 'sos_alerts',
        title: 'SOS alertes',
        description: 'Alertes d\'urgence envoyées à mes contacts.',
        icon: Icons.warning_amber_outlined,
        route: '/sos-alerts',
        keywords: ['sos', 'urgence', 'alerte sos', 'emergency', 'نجدة'],
        replyMessage: 'Ouverture des alertes SOS.',
      ),
      _VoiceCommand(
        id: 'sos_medical',
        title: 'SOS médical',
        description: 'Appel d\'urgence avec dossier médical.',
        icon: Icons.medical_information_outlined,
        route: '/sos-medical',
        keywords: ['sos medical', 'sos médical', 'urgence medicale'],
        replyMessage: 'Ouverture SOS médical.',
      ),
      _VoiceCommand(
        id: 'face_companion',
        title: 'M3AK Visage',
        description:
            'La caméra annonce qui est devant vous et son humeur.',
        icon: Icons.face_outlined,
        route: '/learning/ia1-companion',
        keywords: [
          'm3ak visage',
          'reconnaissance faciale',
          'qui est devant',
          'devant moi',
          'qui est la',
        ],
        replyMessage: 'Ouverture de M3AK Visage.',
      ),
      _VoiceCommand(
        id: 'captions',
        title: 'Sous-titres conversation',
        description: 'Transcription en direct pour conversations.',
        icon: Icons.closed_caption_outlined,
        route: '/accessibility/conversation-captions',
        keywords: ['sous titre', 'sous-titre', 'caption', 'conversation'],
        replyMessage: 'Ouverture des sous-titres de conversation.',
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Lifecycle helpers.
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    _continuousMode = false;
    _autoListenTimer?.cancel();
    _recorder.dispose();
    _tts.stop();
    // Différé via Future(...) : Riverpod interdit la mutation d'un provider
    // pendant la finalisation du widget tree (sinon "Tried to modify a provider
    // while the widget tree was building").
    final notifier = _voiceModeNotifier;
    if (notifier != null) {
      Future<void>(() => notifier.deactivateVoiceMode());
    }
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    // [_disposed] est levé en tout début de dispose ; évite setState alors que mounted est encore true.
    if (_disposed || !mounted) return;
    setState(fn);
  }

  bool _isSupportedLanguage(String text) {
    if (text.trim().isEmpty) return true;
    var hasLetter = false;
    for (final rune in text.runes) {
      final isArabic = rune >= 0x0600 && rune <= 0x06FF;
      final isLatinBasic =
          (rune >= 0x0041 && rune <= 0x005A) ||
              (rune >= 0x0061 && rune <= 0x007A);
      final isLatinExtended =
          (rune >= 0x00C0 && rune <= 0x024F) ||
              (rune >= 0x1E00 && rune <= 0x1EFF);
      final isDigit = rune >= 0x0030 && rune <= 0x0039;
      final isWhitespaceOrPunct = rune == 0x20 ||
          rune == 0x09 ||
          rune == 0x0A ||
          rune == 0x0D ||
          (rune >= 0x21 && rune <= 0x2F) ||
          (rune >= 0x3A && rune <= 0x40) ||
          (rune >= 0x5B && rune <= 0x60) ||
          (rune >= 0x7B && rune <= 0x7E);

      if (isArabic || isLatinBasic || isLatinExtended) {
        hasLetter = true;
        continue;
      }
      if (isDigit || isWhitespaceOrPunct) continue;
      return false;
    }
    return hasLetter;
  }

  // ---------------------------------------------------------------------------
  // UI.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode vocal'),
        actions: [
          IconButton(
            tooltip: 'Lire toutes les commandes',
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: _busy ? null : _readEntireScreen,
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
                  _buildRecognizedCard(theme),
                  if (_voiceBackendDegraded) ...[
                    const SizedBox(height: 8),
                    _buildDegradedNotice(theme),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Boutons disponibles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._commands.map(
                    (c) => _CommandCard(
                      command: c,
                      onTap: _busy ? null : () => _handleCommandTap(c),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildReadAllCard(theme),
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
      label: 'Message du mode vocal',
      child: Card(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.campaign_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _spokenFeedback,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecognizedCard(ThemeData theme) {
    final hasText = _recognizedText.trim().isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.mic_none_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Texte reconnu',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasText
                        ? _recognizedText
                        : 'Le texte reconnu apparaîtra ici.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasText ? null : theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegradedNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Synthèse vocale serveur indisponible. La lecture locale du téléphone reste active.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadAllCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 92,
        child: FilledButton.tonalIcon(
          onPressed: _busy ? null : _readEntireScreen,
          icon: const Icon(Icons.record_voice_over_outlined, size: 28),
          label: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lire l\'écran',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'Annonce tous les boutons disponibles',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
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
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _toggleContinuousMode,
                  icon: Icon(
                    _continuousMode ? Icons.hearing_disabled : Icons.hearing,
                  ),
                  label: Text(
                    _continuousMode
                        ? 'Désactiver écoute continue'
                        : 'Activer écoute continue',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _listenAndProcess,
                  icon: Icon(_busy ? Icons.hourglass_top : Icons.mic),
                  label: Text(
                    _busy ? 'Écoute en cours...' : 'Parler (4 sec)',
                    style: const TextStyle(
                      fontSize: 20,
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
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.command, required this.onTap});

  final _VoiceCommand command;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: command.title,
        hint: command.description,
        child: SizedBox(
          height: 88,
          child: FilledButton.tonalIcon(
            onPressed: onTap,
            icon: Icon(command.icon, size: 28),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  command.description,
                  style: const TextStyle(fontSize: 13, height: 1.25),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Définition unifiée d'une commande vocale (UI + intent + lecture écran).
class _VoiceCommand {
  const _VoiceCommand({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.keywords,
    required this.replyMessage,
  });

  /// Id stable envoyé/reconnu par le backend `/intent`.
  final String id;

  /// Libellé court annoncé par TTS et affiché sur la card.
  final String title;

  /// Phrase courte qui décrit l'action (lue après le titre).
  final String description;

  final IconData icon;

  /// Route GoRouter à atteindre quand l'utilisateur valide cette commande.
  final String route;

  /// Mots-clés multi-langues envoyés au backend pour matching.
  final List<String> keywords;

  /// Message court vocalisé après reconnaissance/tap.
  final String replyMessage;
}
