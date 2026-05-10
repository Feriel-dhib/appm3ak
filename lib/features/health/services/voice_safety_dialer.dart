import 'package:flutter/foundation.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

/// Lance un appel téléphonique direct (Android / iOS) après permission.
class VoiceSafetyDialer {
  VoiceSafetyDialer._();

  static String sanitizeNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == '+' && buf.isEmpty) {
        buf.write(c);
        continue;
      }
      if (RegExp(r'\d').hasMatch(c)) buf.write(c);
    }
    return buf.toString();
  }

  static Future<bool> dialEmergency(String rawNumber) async {
    if (kIsWeb) return false;
    final n = sanitizeNumber(rawNumber);
    if (n.isEmpty) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
      }
      if (!status.isGranted) return false;
    }

    try {
      return await FlutterPhoneDirectCaller.callNumber(n) ?? false;
    } catch (_) {
      return false;
    }
  }
}
