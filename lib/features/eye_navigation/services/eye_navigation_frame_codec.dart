import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Image copiée depuis [CameraImage], sérialisable pour [compute] (isolate).
sealed class SerializableCameraFrame {
  const SerializableCameraFrame({
    required this.width,
    required this.height,
    required this.jpegQuality,
    required this.maxEncodeWidth,
  });

  final int width;
  final int height;
  final int jpegQuality;

  /// Largeur max du JPEG (hauteur proportionnelle) pour limiter bande passante.
  final int maxEncodeWidth;
}

final class BgraSerializableFrame extends SerializableCameraFrame {
  const BgraSerializableFrame({
    required super.width,
    required super.height,
    required super.jpegQuality,
    required super.maxEncodeWidth,
    required this.bytes,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int bytesPerRow;
}

final class Yuv420SerializableFrame extends SerializableCameraFrame {
  const Yuv420SerializableFrame({
    required super.width,
    required super.height,
    required super.jpegQuality,
    required super.maxEncodeWidth,
    required this.yPlane,
    required this.yRowStride,
    required this.uPlane,
    required this.uRowStride,
    required this.uPixelStride,
    required this.vPlane,
  });

  final Uint8List yPlane;
  final int yRowStride;
  final Uint8List uPlane;
  final int uRowStride;
  final int uPixelStride;
  final Uint8List vPlane;
}

/// Copie synchrone des tampons caméra (avant tout `await`).
SerializableCameraFrame? captureEyeNavigationFrame(
  CameraImage image, {
  required int jpegQuality,
  required int maxEncodeWidth,
}) {
  if (image.planes.length == 1) {
    final p = image.planes[0];
    return BgraSerializableFrame(
      width: image.width,
      height: image.height,
      jpegQuality: jpegQuality,
      maxEncodeWidth: maxEncodeWidth,
      bytes: Uint8List.fromList(p.bytes),
      bytesPerRow: p.bytesPerRow,
    );
  }
  if (image.planes.length >= 3) {
    final y = image.planes[0];
    final u = image.planes[1];
    final v = image.planes[2];
    return Yuv420SerializableFrame(
      width: image.width,
      height: image.height,
      jpegQuality: jpegQuality,
      maxEncodeWidth: maxEncodeWidth,
      yPlane: Uint8List.fromList(y.bytes),
      yRowStride: y.bytesPerRow,
      uPlane: Uint8List.fromList(u.bytes),
      uRowStride: u.bytesPerRow,
      uPixelStride: u.bytesPerPixel ?? 1,
      vPlane: Uint8List.fromList(v.bytes),
    );
  }
  return null;
}

/// À appeler via `compute(...)` pour ne pas bloquer l’isolate UI.
Uint8List? encodeEyeNavigationJpeg(SerializableCameraFrame frame) {
  try {
    final img.Image rgb = switch (frame) {
      BgraSerializableFrame b => _bgraToImage(b),
      Yuv420SerializableFrame y => _yuv420ToImage(y),
    };

    final resized = _resizeLongestSide(rgb, frame.maxEncodeWidth);
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: frame.jpegQuality),
    );
  } catch (_) {
    return null;
  }
}

img.Image _bgraToImage(BgraSerializableFrame b) {
  final width = b.width;
  final height = b.height;
  final bytes = b.bytes;
  final rowStride = b.bytesPerRow;
  final out = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    final rowStart = y * rowStride;
    for (var x = 0; x < width; x++) {
      final i = rowStart + x * 4;
      final blue = bytes[i];
      final green = bytes[i + 1];
      final red = bytes[i + 2];
      out.setPixelRgb(x, y, red, green, blue);
    }
  }
  return out;
}

img.Image _yuv420ToImage(Yuv420SerializableFrame f) {
  final width = f.width;
  final height = f.height;
  final out = img.Image(width: width, height: height);
  final yPlane = f.yPlane;
  final uPlane = f.uPlane;
  final vPlane = f.vPlane;
  final yRowStride = f.yRowStride;
  final uvRowStride = f.uRowStride;
  final uvPixelStride = f.uPixelStride;

  for (var y = 0; y < height; y++) {
    final yRow = y * yRowStride;
    final uvRow = (y >> 1) * uvRowStride;
    for (var x = 0; x < width; x++) {
      final uvIndex = uvRow + (x >> 1) * uvPixelStride;
      final yp = yPlane[yRow + x];
      final up = uPlane[uvIndex];
      final vp = vPlane[uvIndex];
      final r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
      final g =
          (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round().clamp(
                0,
                255,
              );
      final b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}

img.Image _resizeLongestSide(img.Image src, int maxSide) {
  final longest = src.width > src.height ? src.width : src.height;
  if (longest <= maxSide) return src;
  if (src.width >= src.height) {
    return img.copyResize(src, width: maxSide);
  }
  return img.copyResize(src, height: maxSide);
}
