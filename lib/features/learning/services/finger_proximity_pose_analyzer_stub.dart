/// Version Web / sans ML Kit : pas d’analyse (aucun plugin natif).
class FingerProximityPoseAnalyzer {
  Future<void> close() async {}

  Future<double?> proximityScoreFromJpegPath(
    String jpegPath, {
    required int imageWidth,
    required int imageHeight,
  }) async =>
      null;
}
