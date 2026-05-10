/// Point d’extension pour **IA vocale** (stress / panique) — phase 2.
///
/// Cible technique : enregistrement audio court → features (MFCC, énergie, jitter)
/// → **TensorFlow Lite** sur Android, ou **Core ML** / service cloud.
///
/// Pour l’instant aucun modèle n’est embarqué : retourner `null` pour ne pas
/// influencer la fusion, ou brancher ici votre pipeline quand prêt.
class VoiceStressAnalyzerStub {
  const VoiceStressAnalyzerStub();

  /// 0–100 si analyse disponible, sinon `null`.
  Future<int?> analyzeShortRecordingPlaceholder() async {
    return null;
  }

  String get roadmapFr =>
      'Bouton « Analyser ma voix » : WAV vers stress_ia_server (port 8000, /docs). '
      'Émulateur : 10.0.2.2:8000 — pas localhost sur le téléphone.';
}
