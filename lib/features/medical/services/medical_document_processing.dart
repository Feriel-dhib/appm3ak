import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Amélioration légère du scan + OCR optionnel (ML Kit, Android/iOS).
class MedicalDocumentProcessing {
  MedicalDocumentProcessing._();

  static Uint8List enhanceDocumentBytes(Uint8List raw) {
    try {
      final decoded = img.decodeImage(raw);
      if (decoded == null) return raw;
      final adjusted = img.adjustColor(
        decoded,
        brightness: 1.06,
        contrast: 1.12,
        saturation: 1.03,
      );
      return Uint8List.fromList(img.encodeJpg(adjusted, quality: 90));
    } catch (_) {
      return raw;
    }
  }

  static Future<String?> extractTextFromFile(String absolutePath) async {
    if (kIsWeb) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(absolutePath);
      final result = await recognizer.processImage(input);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
