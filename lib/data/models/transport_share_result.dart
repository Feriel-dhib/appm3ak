import 'package:equatable/equatable.dart';

/// Réponse `POST /transport/:id/share`.
class TransportShareResult extends Equatable {
  const TransportShareResult({
    required this.token,
    this.expiresAt,
  });

  factory TransportShareResult.fromJson(Map<String, dynamic> json) {
    return TransportShareResult(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  final String token;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [token, expiresAt];
}
