import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// Transforme une trajectoire en image 28x28 normalisee type MNIST/EMNIST.
class AirWritingRenderer {
  const AirWritingRenderer({
    this.targetSize = 28,
    this.innerBox = 20,
    this.highResSize = 280,
    this.strokeWidth = 18,
  });

  final int targetSize;
  final int innerBox;
  final int highResSize;
  final int strokeWidth;

  /// Retourne un tenseur lineaire float32 [1, 28, 28, 1] encode en bytes.
  Uint8List? renderToFloatTensor(List<Offset> points) {
    final Float32List? values = renderToFloatList(points);
    if (values == null) return null;
    return values.buffer.asUint8List();
  }

  /// Retourne la liste float [0,1] de taille 784, ou `null` si trajectoire trop courte
  /// (aligné sur `TrajectoryRenderer.render` Python).
  Float32List? renderToFloatList(List<Offset> points) {
    final img.Image highRes = img.Image(width: highResSize, height: highResSize, numChannels: 1);
    img.fill(highRes, color: img.ColorUint8.rgb(0, 0, 0));

    if (points.length < 2) {
      return null;
    }

    final Rect bounds = _computeBounds(points);
    final double bboxW0 = max(bounds.width, 1.0);
    final double bboxH0 = max(bounds.height, 1.0);
    if (bboxW0 < 5 && bboxH0 < 5) {
      return null;
    }

    final double scale = (innerBox - 1) / max(bboxW0, bboxH0);
    final double bboxW = bounds.width * scale;
    final double bboxH = bounds.height * scale;
    final double offsetX = ((innerBox - bboxW) / 2.0) + ((targetSize - innerBox) / 2.0);
    final double offsetY = ((innerBox - bboxH) / 2.0) + ((targetSize - innerBox) / 2.0);
    final double hiScale = highResSize / targetSize;

    final List<Offset> normalized = points.map((Offset p) {
      final double nx = (((p.dx - bounds.left) * scale) + offsetX) * hiScale;
      final double ny = (((p.dy - bounds.top) * scale) + offsetY) * hiScale;
      return Offset(nx, ny);
    }).toList(growable: false);

    for (int i = 1; i < normalized.length; i++) {
      final Offset a = normalized[i - 1];
      final Offset b = normalized[i];
      img.drawLine(
        highRes,
        x1: a.dx.round(),
        y1: a.dy.round(),
        x2: b.dx.round(),
        y2: b.dy.round(),
        color: img.ColorUint8.rgb(255, 255, 255),
        thickness: strokeWidth,
      );
    }

    // Python: cv2.GaussianBlur(..., (9, 9), 0) — rayon ~4 sur le canvas haute rés.
    final img.Image blurred = img.gaussianBlur(highRes, radius: 4);
    final img.Image resized = img.copyResize(
      blurred,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.average,
    );

    final Float32List output = Float32List(targetSize * targetSize);
    int idx = 0;
    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final img.Pixel px = resized.getPixel(x, y);
        output[idx++] = px.r / 255.0;
      }
    }
    return _recenterByMass(output);
  }

  Float32List _recenterByMass(Float32List input) {
    double sum = 0;
    double weightedX = 0;
    double weightedY = 0;
    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final v = input[(y * targetSize) + x];
        sum += v;
        weightedX += x * v;
        weightedY += y * v;
      }
    }
    if (sum < 1e-6) return input;
    final cx = weightedX / sum;
    final cy = weightedY / sum;
    final targetCenter = (targetSize - 1) / 2.0;
    final dx = (targetCenter - cx).round();
    final dy = (targetCenter - cy).round();
    final shifted = Float32List(targetSize * targetSize);
    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final sx = x - dx;
        final sy = y - dy;
        if (sx >= 0 && sx < targetSize && sy >= 0 && sy < targetSize) {
          shifted[(y * targetSize) + x] = input[(sy * targetSize) + sx];
        }
      }
    }
    return shifted;
  }

  Rect _computeBounds(List<Offset> points) {
    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;
    for (final Offset point in points) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
