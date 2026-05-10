import 'package:flutter/material.dart';

import '../config/detection_config.dart';
import '../models/detection_result.dart';

/// Cadres colorés selon le niveau de risque (YOLO / TFLite).
class DetectionBBoxOverlay extends StatelessWidget {
  const DetectionBBoxOverlay({super.key, required this.detections});

  final List<DetectionResult> detections;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _DetectionPainter(detections: detections),
          );
        },
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter({required this.detections});

  final List<DetectionResult> detections;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final r = Rect.fromLTWH(
        d.boundingBox.left * size.width,
        d.boundingBox.top * size.height,
        (d.boundingBox.right - d.boundingBox.left) * size.width,
        (d.boundingBox.bottom - d.boundingBox.top) * size.height,
      );
      Color color = Colors.green;
      if (d.riskLevel == RiskLevel.critical) {
        color = Colors.red;
      } else if (d.riskLevel == RiskLevel.warning) {
        color = Colors.orange;
      }
      canvas.drawRect(
        r,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter old) =>
      old.detections != detections;
}
