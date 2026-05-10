import 'package:flutter_tts/flutter_tts.dart';

/// Langue pour les instructions vocales.
enum VoiceLanguage { french, arabic }

/// Service d'instructions vocales bilingues (FR / AR) pour la navigation.
class VoiceGuidanceService {
  VoiceGuidanceService() {
    _tts = FlutterTts();
    _init();
  }

  late final FlutterTts _tts;
  VoiceLanguage _lang = VoiceLanguage.french;
  bool _initialized = false;

  VoiceLanguage get language => _lang;
  set language(VoiceLanguage value) {
    _lang = value;
    _applyLang();
  }

  Future<void> _init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _applyLang();
    _initialized = true;
  }

  Future<void> _applyLang() async {
    switch (_lang) {
      case VoiceLanguage.french:
        await _tts.setLanguage('fr-FR');
        break;
      case VoiceLanguage.arabic:
        await _tts.setLanguage('ar');
        break;
    }
  }

  /// Annonce un obstacle (bilingue).
  Future<void> speakObstacle(String obstacleLabel) async {
    final text = _getObstaclePhrase(obstacleLabel);
    await _speak(text);
  }

  String _getObstaclePhrase(String label) {
    switch (_lang) {
      case VoiceLanguage.french:
        return _obstacleFr(label);
      case VoiceLanguage.arabic:
        return _obstacleAr(label);
    }
  }

  String _obstacleFr(String label) {
    switch (label.toLowerCase()) {
      case 'person':
        return 'Attention, personne devant.';
      case 'car':
        return 'Attention, véhicule devant.';
      case 'bicycle':
        return 'Attention, vélo devant.';
      default:
        return 'Attention, obstacle devant.';
    }
  }

  String _obstacleAr(String label) {
    switch (label.toLowerCase()) {
      case 'person':
        return 'انتباه، شخص أمامك.';
      case 'car':
        return 'انتباه، مركبة أمامك.';
      case 'bicycle':
        return 'انتباه، دراجة أمامك.';
      default:
        return 'انتباه، عائق أمامك.';
    }
  }

  /// Annonce une direction (ex: tournez à gauche).
  Future<void> speakDirection(String directionKey) async {
    final text = _getDirectionPhrase(directionKey);
    await _speak(text);
  }

  String _getDirectionPhrase(String key) {
    switch (_lang) {
      case VoiceLanguage.french:
        return _directionFr(key);
      case VoiceLanguage.arabic:
        return _directionAr(key);
    }
  }

  String _directionFr(String key) {
    switch (key) {
      case 'left':
        return 'Tournez à gauche.';
      case 'right':
        return 'Tournez à droite.';
      case 'straight':
        return 'Continuez tout droit.';
      case 'destination':
        return 'Vous êtes arrivé.';
      default:
        return 'Continuez.';
    }
  }

  String _directionAr(String key) {
    switch (key) {
      case 'left':
        return 'انعطف يساراً.';
      case 'right':
        return 'انعطف يميناً.';
      case 'straight':
        return 'استمر مباشرة.';
      case 'destination':
        return 'وصلت إلى وجهتك.';
      default:
        return 'استمر.';
    }
  }

  Future<void> _speak(String text) async {
    if (!_initialized || text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();
  Future<void> dispose() async => _tts.stop();
}
