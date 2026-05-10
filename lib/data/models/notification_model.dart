import 'package:equatable/equatable.dart';

/// Notification (SOS, risque, médicament, etc.).
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    this.userId,
    this.titre,
    this.message,
    this.type,
    this.lu = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String?,
      titre: json['titre'] as String?,
      message: json['message'] as String?,
      type: json['type'] as String?,
      lu: json['lu'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final String? userId;
  final String? titre;
  final String? message;
  final String? type;
  final bool lu;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, lu];
}
