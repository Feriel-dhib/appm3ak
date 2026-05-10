import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Résolu dans [init] avant [runApp] pour distinguer téléphone réel vs émulateur
/// (URLs : localhost / `10.0.2.2` ne sont pas valables sur un appareil physique).
class Ma3akDeviceContext {
  Ma3akDeviceContext._();

  /// `null` : [init] pas encore appelé (tests). Ne pas déduire « physique ».
  static bool? isPhysicalMobileDevice;

  static Future<void> init() async {
    if (kIsWeb) {
      isPhysicalMobileDevice = false;
      return;
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        isPhysicalMobileDevice = ios.isPhysicalDevice;
      } else if (Platform.isAndroid) {
        final android = await plugin.androidInfo;
        isPhysicalMobileDevice = android.isPhysicalDevice;
      } else {
        isPhysicalMobileDevice = false;
      }
    } catch (_) {
      isPhysicalMobileDevice = false;
    }
  }
}
