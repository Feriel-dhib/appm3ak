import 'package:flutter/material.dart';

import '../models/detected_obstacle.dart';

/// Cadres autour des obstacles détectés (ML Kit).
class ArObstacleOverlay extends StatelessWidget {
  const ArObstacleOverlay({super.key, required this.obstacles});

  final List<DetectedObstacle> obstacles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ObstaclePainter(obstacles: obstacles),
        );
      },
    );
  }
}

class _ObstaclePainter extends CustomPainter {
  _ObstaclePainter({required this.obstacles});

  final List<DetectedObstacle> obstacles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final o in obstacles) {
      final r = Rect.fromLTWH(
        o.boundingBox.left * size.width,
        o.boundingBox.top * size.height,
        (o.boundingBox.right - o.boundingBox.left) * size.width,
        (o.boundingBox.bottom - o.boundingBox.top) * size.height,
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ObstaclePainter old) => old.obstacles != obstacles;
}
