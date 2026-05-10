import 'dart:io' show Platform;

/// Raccourcis Volume+ : réservé Android ; no-op tant que le canal natif n’est pas branché.
class AndroidVolumeHub {
  AndroidVolumeHub._();

  static Future<bool> Function()? onVolumeUpPriority;

  static void ensureInitialized() {
    if (!Platform.isAndroid) return;
  }
}
