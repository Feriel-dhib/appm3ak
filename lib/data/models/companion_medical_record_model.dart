import 'package:equatable/equatable.dart';

/// Dossier médical d'un bénéficiaire visible côté accompagnant.
class CompanionMedicalRecordModel extends Equatable {
  const CompanionMedicalRecordModel({
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.qrPayload,
    this.groupeSanguin,
    this.allergies,
    this.medicaments,
    this.contactUrgence,
    this.typeHandicap,
    this.updatedAt,
  });

  factory CompanionMedicalRecordModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final beneficiary = json['beneficiary'];
    final beneficiaryMap = beneficiary is Map<String, dynamic>
        ? beneficiary
        : null;
    final beneficiaryId = readString([
      'beneficiaryId',
      'userId',
      'handicapeId',
      'id',
    ]);
    final nameFromBeneficiary = beneficiaryMap == null
        ? ''
        : [
                beneficiaryMap['displayName'],
                '${beneficiaryMap['prenom'] ?? ''} ${beneficiaryMap['nom'] ?? ''}',
                beneficiaryMap['nomComplet'],
                beneficiaryMap['name'],
              ]
              .map((e) => (e ?? '').toString().trim())
              .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final beneficiaryNameRaw = readString([
      'beneficiaryName',
      'nomBeneficiaire',
      'name',
    ]);
    final beneficiaryName = beneficiaryNameRaw.isNotEmpty
        ? beneficiaryNameRaw
        : nameFromBeneficiary;

    return CompanionMedicalRecordModel(
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName.isNotEmpty
          ? beneficiaryName
          : 'Bénéficiaire',
      qrPayload: readString(['qrPayload', 'medicalQr', 'qr', 'payload']),
      groupeSanguin: readString(['groupeSanguin', 'bloodGroup']),
      allergies: readString(['allergies']),
      medicaments: readString(['medicaments', 'medications']),
      contactUrgence: readString(['contactUrgence', 'emergencyContact']),
      typeHandicap: readString(['typeHandicap', 'handicapType']),
      updatedAt: DateTime.tryParse(
        readString(['updatedAt', 'qrUpdatedAt', 'medicalUpdatedAt']),
      ),
    );
  }

  final String beneficiaryId;
  final String beneficiaryName;
  final String qrPayload;
  final String? groupeSanguin;
  final String? allergies;
  final String? medicaments;
  final String? contactUrgence;
  final String? typeHandicap;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    beneficiaryId,
    beneficiaryName,
    qrPayload,
    updatedAt,
  ];
}
