import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Service TTS dédié aux alertes de détection d'obstacles.
/// Gère la langue (FR/AR) et l'arrêt d'urgence (couper les alertes).
class TtsAlertService {
  TtsAlertService() {
    _tts = FlutterTts();
    _init();
  }

  late final FlutterTts _tts;
  final Completer<void> _ready = Completer<void>();
  bool _muted = false;
  bool _isArabic = false;
  String _currentLocale = 'fr-FR';

  bool get isMuted => _muted;
  bool get isArabic => _isArabic;

  Future<void> _init() async {
    try {
      // iOS: force la sortie audio même en mode silencieux.
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      // Plus lent pour prononcer les intitulés complets (personnes malvoyantes).
      await _tts.setSpeechRate(0.36);
      await _safeSetLanguage('fr-FR');
    } catch (_) {
      // Ne bloque pas le service si la voix locale échoue.
    } finally {
      if (!_ready.isCompleted) {
        _ready.complete();
      }
    }
  }

  Future<void> setLanguage(bool useArabic) async {
    await _ready.future;
    _isArabic = useArabic;
    await _safeSetLanguage(useArabic ? 'ar' : 'fr-FR');
  }

  /// Langue pour le guidage vocal (FR / AR / EN), sans casser les appels existants [setLanguage].
  Future<void> applyVoiceLocale({
    required bool useArabic,
    bool useEnglish = false,
  }) async {
    await _ready.future;
    if (useArabic) {
      _isArabic = true;
      await _safeSetLanguage('ar');
    } else if (useEnglish) {
      _isArabic = false;
      await _safeSetLanguage('en-US');
    } else {
      _isArabic = false;
      await _safeSetLanguage('fr-FR');
    }
  }

  Future<void> _safeSetLanguage(String locale) async {
    final candidates = <String>[
      locale,
      if (locale != 'fr-FR') 'fr-FR',
      if (locale != 'en-US') 'en-US',
      if (locale != 'ar') 'ar',
    ];
    for (final l in candidates) {
      try {
        final result = await _tts.setLanguage(l);
        if (result == 1 || result == true || '$result' == '1') {
          _currentLocale = l;
          return;
        }
      } catch (_) {
        // Essaie la locale suivante.
      }
    }
  }

  void setMuted(bool muted) {
    _muted = muted;
    if (muted) _tts.stop();
  }

  /// Annonce un message (respecte le mute).
  ///
  /// Si [interruptPrevious] est false, on ne coupe pas l’énoncé en cours : à utiliser
  /// quand les annonces sont déjà sérialisées (évite de tronquer le nom de l’objet).
  Future<void> speak(
    String message, {
    bool interruptPrevious = true,
  }) async {
    if (_muted || message.isEmpty) return;
    await _ready.future;
    try {
      if (interruptPrevious) {
        await _tts.stop();
      }
      await _tts.speak(message);
    } catch (_) {
      // Retry unique avec locale de secours.
      await _safeSetLanguage(_currentLocale);
      if (interruptPrevious) {
        await _tts.stop();
      }
      await _tts.speak(message);
    }
  }

  Future<void> stop() async => _tts.stop();
  Future<void> dispose() async => _tts.stop();
}
