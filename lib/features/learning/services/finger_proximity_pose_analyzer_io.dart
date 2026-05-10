import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class _ArmSide {
  const _ArmSide({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
    required this.index,
    required this.pinky,
    required this.thumb,
  });

  final PoseLandmarkType shoulder;
  final PoseLandmarkType elbow;
  final PoseLandmarkType wrist;
  final PoseLandmarkType index;
  final PoseLandmarkType pinky;
  final PoseLandmarkType thumb;

  static const _l = _ArmSide(
    shoulder: PoseLandmarkType.leftShoulder,
    elbow: PoseLandmarkType.leftElbow,
    wrist: PoseLandmarkType.leftWrist,
    index: PoseLandmarkType.leftIndex,
    pinky: PoseLandmarkType.leftPinky,
    thumb: PoseLandmarkType.leftThumb,
  );

  static const _r = _ArmSide(
    shoulder: PoseLandmarkType.rightShoulder,
    elbow: PoseLandmarkType.rightElbow,
    wrist: PoseLandmarkType.rightWrist,
    index: PoseLandmarkType.rightIndex,
    pinky: PoseLandmarkType.rightPinky,
    thumb: PoseLandmarkType.rightThumb,
  );
}

/// Estime la proximité main / doigt : plusieurs segments 2D + Δz (pointage vers la caméra inclus).
class FingerProximityPoseAnalyzer {
  FingerProximityPoseAnalyzer()
      : _detector = PoseDetector(
          options: PoseDetectorOptions(
            model: PoseDetectionModel.accurate,
            mode: PoseDetectionMode.single,
          ),
        );

  final PoseDetector _detector;

  Future<void> close() => _detector.close();

  Future<double?> proximityScoreFromJpegPath(
    String jpegPath, {
    required int imageWidth,
    required int imageHeight,
  }) async {
    final input = InputImage.fromFilePath(jpegPath);
    final poses = await _detector.processImage(input);
    if (poses.isEmpty) return null;

    final lm = poses.first.landmarks;
    final diag = math.max(
      1.0,
      math.sqrt(
        imageWidth * imageWidth + imageHeight * imageHeight,
      ),
    );

    var best = 0.0;
    const minL = 0.25;

    void consider2D(PoseLandmarkType a, PoseLandmarkType b) {
      final pa = lm[a];
      final pb = lm[b];
      if (pa == null || pb == null) return;
      if (pa.likelihood < minL || pb.likelihood < minL) return;
      final d = math.sqrt(
        math.pow(pb.x - pa.x, 2) + math.pow(pb.y - pa.y, 2),
      );
      final n = d / diag;
      if (n > best) best = n;
    }

    void considerZ(PoseLandmarkType a, PoseLandmarkType b) {
      final pa = lm[a];
      final pb = lm[b];
      if (pa == null || pb == null) return;
      if (pa.likelihood < minL || pb.likelihood < minL) return;
      // z ≈ même échelle que x/y (MediaPipe) ; doigt vers la caméra → |Δz| souvent notable.
      final dz = (pb.z - pa.z).abs();
      final n = dz / diag;
      if (n > best) best = n;
    }

    for (final side in [_ArmSide._l, _ArmSide._r]) {
      consider2D(side.shoulder, side.index);
      consider2D(side.elbow, side.index);
      consider2D(side.wrist, side.index);
      consider2D(side.elbow, side.wrist);
      consider2D(side.index, side.pinky);
      consider2D(side.index, side.thumb);
      considerZ(side.wrist, side.index);
    }

    // Vue selfie : nez + index souvent visibles alors que le poignet est hors cadre.
    consider2D(PoseLandmarkType.nose, PoseLandmarkType.leftIndex);
    consider2D(PoseLandmarkType.nose, PoseLandmarkType.rightIndex);

    return best > 0.0005 ? best : null;
  }
}
