import 'dart:typed_data';

import '../config/detection_config.dart';

/// Données BGRA (1 plan, iOS) envoyables à [compute].
class BgraFrameData {
  const BgraFrameData({
    required this.bytes,
    required this.bytesPerRow,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int width;
  final int height;
}

/// Conversion BGRA8888 → RGB 320×320 (iOS).
Uint8List? bgraToRgb320x320TopLevel(BgraFrameData data) {
  final w = data.width;
  final h = data.height;
  final bgra = data.bytes;
  final rowStride = data.bytesPerRow;

  final rgbFull = Uint8List(w * h * 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final srcIdx = y * rowStride + x * 4;
      final b = bgra[srcIdx];
      final g = bgra[srcIdx + 1];
      final r = bgra[srcIdx + 2];
      final dstIdx = (y * w + x) * 3;
      rgbFull[dstIdx] = r;
      rgbFull[dstIdx + 1] = g;
      rgbFull[dstIdx + 2] = b;
    }
  }
  return _resizeRgb(
    rgbFull,
    w,
    h,
    DetectionConfig.inputWidth,
    DetectionConfig.inputHeight,
  );
}

/// Données YUV420 envoyables à un isolate (pour [compute]).
class YuvFrameData {
  const YuvFrameData({
    required this.yPlane,
    required this.yRowStride,
    required this.uPlane,
    required this.uRowStride,
    required this.vPlane,
    required this.vRowStride,
    required this.width,
    required this.height,
  });

  final Uint8List yPlane;
  final int yRowStride;
  final Uint8List uPlane;
  final int uRowStride;
  final Uint8List vPlane;
  final int vRowStride;
  final int width;
  final int height;
}

/// Conversion YUV420 → RGB (top-level pour [compute], évite de bloquer l'UI).
/// Taille de sortie : DetectionConfig.inputWidth × inputHeight.
Uint8List? yuv420ToRgb320x320TopLevel(YuvFrameData data) {
  final w = data.width;
  final h = data.height;
  final yPlane = data.yPlane;
  final uPlane = data.uPlane;
  final vPlane = data.vPlane;
  final yRowStride = data.yRowStride;
  final uRowStride = data.uRowStride;
  final vRowStride = data.vRowStride;

  final rgbFull = Uint8List(w * h * 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final yIdx = y * yRowStride + x;
      final uvX = x >> 1;
      final uvY = y >> 1;
      final uIdx = uvY * uRowStride + uvX;
      final vIdx = uvY * vRowStride + uvX;
      final yy = yPlane[yIdx];
      final uu = uPlane[uIdx] - 128;
      final vv = vPlane[vIdx] - 128;
      var r = (yy + (1.402 * vv)).round();
      var g = (yy - (0.344 * uu + 0.714 * vv)).round();
      var b = (yy + (1.772 * uu)).round();
      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);
      final outIdx = (y * w + x) * 3;
      rgbFull[outIdx] = r;
      rgbFull[outIdx + 1] = g;
      rgbFull[outIdx + 2] = b;
    }
  }
  return _resizeRgb(
    rgbFull,
    w,
    h,
    DetectionConfig.inputWidth,
    DetectionConfig.inputHeight,
  );
}

Uint8List _resizeRgb(Uint8List rgb, int srcW, int srcH, int dstW, int dstH) {
  final out = Uint8List(dstW * dstH * 3);
  for (var dy = 0; dy < dstH; dy++) {
    for (var dx = 0; dx < dstW; dx++) {
      final sx = (dx * srcW / dstW).floor().clamp(0, srcW - 1);
      final sy = (dy * srcH / dstH).floor().clamp(0, srcH - 1);
      final srcIdx = (sy * srcW + sx) * 3;
      final dstIdx = (dy * dstW + dx) * 3;
      out[dstIdx] = rgb[srcIdx];
      out[dstIdx + 1] = rgb[srcIdx + 1];
      out[dstIdx + 2] = rgb[srcIdx + 2];
    }
  }
  return out;
}
