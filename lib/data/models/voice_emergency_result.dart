import 'package:equatable/equatable.dart';

/// Réponse API `POST /safety/voice-emergency` (smart matching serveur).
class VoiceEmergencyResult extends Equatable {
  const VoiceEmergencyResult({
    this.alertId,
    this.matchedContactId,
    this.matchedName,
    this.primaryPhone,
    this.notificationSent = false,
  });

  factory VoiceEmergencyResult.fromJson(Map<String, dynamic> json) {
    return VoiceEmergencyResult(
      alertId: json['alertId'] as String? ?? json['alert_id'] as String?,
      matchedContactId: json['matchedContactId'] as String? ??
          json['matched_contact_id'] as String?,
      matchedName: json['matchedName'] as String? ?? json['matched_name'] as String?,
      primaryPhone: json['primaryPhone'] as String? ??
          json['primary_phone'] as String? ??
          json['phone'] as String?,
      notificationSent: json['notificationSent'] as bool? ??
          json['notification_sent'] as bool? ??
          false,
    );
  }

  final String? alertId;
  final String? matchedContactId;
  final String? matchedName;
  final String? primaryPhone;
  final bool notificationSent;

  @override
  List<Object?> get props =>
      [alertId, matchedContactId, matchedName, primaryPhone, notificationSent];
}
