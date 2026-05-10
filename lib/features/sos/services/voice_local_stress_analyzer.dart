import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../models/voice_stress_api_result.dart';

/// Heuristique locale (sans Python) : RMS + taux de passages par zéro sur PCM16 bits.
/// Moins précis que MFCC / librosa, mais permet d’utiliser l’écran SOS sans serveur.
class VoiceLocalStressAnalyzer {
  VoiceLocalStressAnalyzer._();

  static VoiceStressApiResult analyzeWavFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const VoiceStressApiResult(
        score: 0,
        label: 'calm',
        labelFr: 'Audio introuvable',
        detailFr: 'Fichier WAV manquant.',
        fromOfflineFallback: true,
      );
    }

    final bytes = file.readAsBytesSync();
    final pcm = _extractPcmData(bytes);
    if (pcm == null || pcm.length < 200) {
      return const VoiceStressApiResult(
        score: 0,
        label: 'calm',
        labelFr: 'Échantillon trop court',
        detailFr: 'Enregistrez au moins ~0,25 s.',
        fromOfflineFallback: true,
      );
    }

    final n = pcm.length ~/ 2;
    if (n < 100) {
      return const VoiceStressApiResult(
        score: 0,
        label: 'calm',
        labelFr: 'Échantillon trop court',
        detailFr: 'Pas assez d’échantillons audio.',
        fromOfflineFallback: true,
      );
    }

    var sumSq = 0.0;
    var zcr = 0;
    int? prevSign;
    final bd = ByteData.sublistView(pcm);

    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little).toDouble();
      sumSq += s * s;
      final sign = s >= 0 ? 1 : -1;
      if (prevSign != null && sign != prevSign) zcr++;
      prevSign = sign;
    }

    final rms = sqrt(sumSq / n);
    final zcrRate = zcr / n;

    // Calibration indicative (parole 16 kHz mono).
    final nRms = (rms / 5500).clamp(0.0, 1.0);
    final nZcr = (zcrRate / 0.11).clamp(0.0, 1.0);
    final raw = 0.52 * nRms + 0.48 * nZcr;
    final score = (raw * 100).round().clamp(0, 100);

    final tier = _tier(score);
    final detail =
        'Analyse locale (sans serveur Python) — RMS=${rms.toStringAsFixed(0)}, '
        'ZCR=${zcrRate.toStringAsFixed(3)}. Pour une analyse MFCC, lancez le service sur le port 8000.';

    return VoiceStressApiResult(
      score: score,
      label: tier.label,
      labelFr: tier.labelFr,
      detailFr: detail,
      fromOfflineFallback: true,
    );
  }

  static Uint8List? _extractPcmData(Uint8List all) {
    if (all.length < 44) return null;
    var i = 12;
    while (i + 8 <= all.length) {
      final id = String.fromCharCodes(all.sublist(i, i + 4));
      final size = ByteData.sublistView(all, i + 4, i + 8).getUint32(0, Endian.little);
      final next = i + 8 + size;
      if (id == 'data') {
        if (next > all.length) return null;
        return all.sublist(i + 8, next);
      }
      i = next;
      if (size % 2 != 0) i++;
    }
    return null;
  }

  static _Tier _tier(int score) {
    if (score < 22) {
      return const _Tier('calm', 'Calme');
    }
    if (score < 38) {
      return const _Tier('light_stress', 'Stress léger');
    }
    if (score < 58) {
      return const _Tier('stress', 'Stress marqué');
    }
    if (score < 78) {
      return const _Tier('high_stress', 'Fort stress / danger modéré');
    }
    return const _Tier('panic', 'Panique / urgence probable');
  }
}

class _Tier {
  const _Tier(this.label, this.labelFr);
  final String label;
  final String labelFr;
}
