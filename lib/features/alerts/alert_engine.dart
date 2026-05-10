import '../detection/config/detection_config.dart';
import '../detection/models/detection_result.dart';
import 'tts_alert_service.dart';

/// Moteur d'alertes : priorisation (critique > warning > safe), cooldown global et par zone.
class AlertEngine {
  AlertEngine({required TtsAlertService tts}) : _tts = tts;

  final TtsAlertService _tts;

  /// Fin du dernier cycle « phrase + pause » ; le prochain slot ne s’ouvre qu’après ce moment.
  DateTime? _lastCycleEndTime;
  final Map<HorizontalZone, DateTime> _lastAlertByZone = {};

  Duration get _cooldownGlobal => Duration(
        milliseconds:
            (DetectionConfig.cooldownGlobalSeconds * 1000).round(),
      );
  Duration get _cooldownZone => Duration(
        milliseconds: (DetectionConfig.cooldownZoneSeconds * 1000).round(),
      );
  Duration get _postSpeakPause => Duration(
        milliseconds:
            (DetectionConfig.postSpeakPauseSeconds * 1000).round(),
      );

  /// Une seule chaîne d’annonces à la fois : évite les appels concurrents qui
  /// [stop]ent la voix au milieu d’un mot et enchaînent les objets trop vite.
  Future<void> _speakQueue = Future<void>.value();

  /// Traite les détections : choisit la plus prioritaire, respecte les cooldowns, annonce via TTS.
  void processDetections(
    List<DetectionResult> detections, {
    required bool useArabic,
  }) {
    if (detections.isEmpty) return;
    _speakQueue = _speakQueue.then((_) async {
      try {
        await _processDetectionsOnce(detections, useArabic: useArabic);
      } catch (_) {
        // Ne pas bloquer la file sur une erreur TTS / plateforme.
      }
    });
  }

  Future<void> _processDetectionsOnce(
    List<DetectionResult> detections, {
    required bool useArabic,
  }) async {
    await _tts.setLanguage(useArabic);

    final toAnnounce = _selectDetectionToAnnounce(detections);
    if (toAnnounce == null) return;

    final now = DateTime.now();
    if (_lastCycleEndTime != null &&
        now.difference(_lastCycleEndTime!) < _cooldownGlobal) {
      return;
    }
    final zone = toAnnounce.zone;
    final lastZone = _lastAlertByZone[zone];
    if (lastZone != null && now.difference(lastZone) < _cooldownZone) {
      return;
    }

    final message = useArabic
        ? DetectionConfig.getAlertMessageAr(toAnnounce.label, toAnnounce.riskLevel)
        : DetectionConfig.getAlertMessageFr(toAnnounce.label, toAnnounce.riskLevel);

    // Ne pas couper la phrase en cours : la file garantit l’ordre.
    await _tts.speak(message, interruptPrevious: false);
    if (_postSpeakPause > Duration.zero) {
      await Future<void>.delayed(_postSpeakPause);
    }

    final end = DateTime.now();
    _lastCycleEndTime = end;
    _lastAlertByZone[zone] = end;
  }

  /// Priorité : critique > warning > safe ; puis plus proche (distance min).
  DetectionResult? _selectDetectionToAnnounce(List<DetectionResult> list) {
    final critical = list.where((d) => d.riskLevel == RiskLevel.critical).toList();
    final warning = list.where((d) => d.riskLevel == RiskLevel.warning).toList();
    final safe = list.where((d) => d.riskLevel == RiskLevel.safe).toList();

    final candidates = critical.isNotEmpty
        ? critical
        : warning.isNotEmpty
            ? warning
            : safe;
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return candidates.first;
  }
}
