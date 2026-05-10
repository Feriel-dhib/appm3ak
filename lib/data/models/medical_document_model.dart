import 'package:equatable/equatable.dart';

/// Document médical numérisé (ordonnance, analyse, compte rendu).
class MedicalDocumentModel extends Equatable {
  const MedicalDocumentModel({
    required this.id,
    required this.shareToken,
    required this.title,
    required this.localRelativePath,
    this.ocrText,
    this.cloudSynced = false,
    this.createdAt,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    return MedicalDocumentModel(
      id: json['id'] as String? ?? '',
      shareToken: json['shareToken'] as String? ?? '',
      title: json['title'] as String? ?? 'Document',
      localRelativePath: json['localRelativePath'] as String? ?? '',
      ocrText: json['ocrText'] as String?,
      cloudSynced: json['cloudSynced'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final String shareToken;
  final String title;
  final String localRelativePath;
  final String? ocrText;
  final bool cloudSynced;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'shareToken': shareToken,
    'title': title,
    'localRelativePath': localRelativePath,
    'ocrText': ocrText,
    'cloudSynced': cloudSynced,
    'createdAt': createdAt?.toIso8601String(),
  };

  MedicalDocumentModel copyWith({
    String? id,
    String? shareToken,
    String? title,
    String? localRelativePath,
    String? ocrText,
    bool? cloudSynced,
    DateTime? createdAt,
  }) {
    return MedicalDocumentModel(
      id: id ?? this.id,
      shareToken: shareToken ?? this.shareToken,
      title: title ?? this.title,
      localRelativePath: localRelativePath ?? this.localRelativePath,
      ocrText: ocrText ?? this.ocrText,
      cloudSynced: cloudSynced ?? this.cloudSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
