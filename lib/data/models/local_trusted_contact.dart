import 'package:equatable/equatable.dart';

/// Accompagnant / proche enregistré **sur l’appareil** (pas besoin d’ID API).
class LocalTrustedContact extends Equatable {
  const LocalTrustedContact({
    required this.id,
    required this.displayName,
    required this.phone,
    this.priority = 0,
  });

  final String id;
  final String displayName;
  final String phone;
  final int priority;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'phone': phone,
        'priority': priority,
      };

  factory LocalTrustedContact.fromJson(Map<String, dynamic> j) {
    return LocalTrustedContact(
      id: j['id'] as String? ?? '',
      displayName: j['displayName'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      priority: (j['priority'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, displayName, phone, priority];
}
