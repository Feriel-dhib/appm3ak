/// Raccourcis Volume+ (Android) — version sans `dart:io` (web / analyse).
class AndroidVolumeHub {
  AndroidVolumeHub._();

  static Future<bool> Function()? onVolumeUpPriority;

  static void ensureInitialized() {}
}
