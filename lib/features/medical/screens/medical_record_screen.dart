import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/medical_record_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

class MedicalRecordScreen extends ConsumerStatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  ConsumerState<MedicalRecordScreen> createState() =>
      _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends ConsumerState<MedicalRecordScreen> {
  MedicalRecordModel? _record;
  bool _loading = true;
  bool _saving = false;
  bool _exportingQr = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _groupeSanguinController;
  late TextEditingController _typeHandicapController;
  late TextEditingController _allergiesController;
  late TextEditingController _maladiesController;
  late TextEditingController _medicamentsController;
  late TextEditingController _antecedentsController;
  late TextEditingController _medecinController;
  late TextEditingController _medecinContactController;
  late TextEditingController _contactUrgenceController;

  @override
  void initState() {
    super.initState();
    _groupeSanguinController = TextEditingController();
    _typeHandicapController = TextEditingController();
    _allergiesController = TextEditingController();
    _maladiesController = TextEditingController();
    _medicamentsController = TextEditingController();
    _antecedentsController = TextEditingController();
    _medecinController = TextEditingController();
    _medecinContactController = TextEditingController();
    _contactUrgenceController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _groupeSanguinController.dispose();
    _typeHandicapController.dispose();
    _allergiesController.dispose();
    _maladiesController.dispose();
    _medicamentsController.dispose();
    _antecedentsController.dispose();
    _medecinController.dispose();
    _medecinContactController.dispose();
    _contactUrgenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final localStore = ref.read(localMedicalRecordStoreProvider);
    final local = await localStore.read();
    if (mounted && local != null) {
      _record = local;
      _fillForm(local);
    }
    try {
      final repo = ref.read(medicalRecordsRepositoryProvider);
      final cloud = await repo.getMe();
      if (mounted && cloud != null) {
        _record = cloud;
        _fillForm(cloud);
        await localStore.save(cloud);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _fillForm(MedicalRecordModel r) {
    _typeHandicapController.text = r.typeHandicap ?? '';
    _groupeSanguinController.text = r.groupeSanguin ?? '';
    _allergiesController.text = r.allergies ?? '';
    _maladiesController.text = r.maladiesChroniques ?? '';
    _medicamentsController.text = r.medicaments ?? '';
    _antecedentsController.text = r.antecedentsImportants ?? '';
    _medecinController.text = r.medecinTraitant ?? '';
    _medecinContactController.text = r.medecinContact ?? '';
    _contactUrgenceController.text = r.contactUrgence ?? '';
  }

  MedicalRecordModel _buildRecordDraft() {
    String? val(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return MedicalRecordModel(
      id: _record?.id ?? 'local',
      typeHandicap: val(_typeHandicapController),
      groupeSanguin: val(_groupeSanguinController),
      allergies: val(_allergiesController),
      maladiesChroniques: val(_maladiesController),
      medicaments: val(_medicamentsController),
      antecedentsImportants: val(_antecedentsController),
      medecinTraitant: val(_medecinController),
      medecinContact: val(_medecinContactController),
      contactUrgence: val(_contactUrgenceController),
      createdAt: _record?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String _buildQrPayload(MedicalRecordModel r) {
    String compact(String? value) {
      if (value == null) return '';
      final v = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (v.length <= 120) return v;
      return '${v.substring(0, 117)}...';
    }

    final lines = <String>[
      'MA3AK_MEDICAL_RECORD_V1',
      'updatedAt:${r.updatedAt?.toIso8601String() ?? ''}',
      'typeHandicap:${compact(r.typeHandicap)}',
      'groupeSanguin:${compact(r.groupeSanguin)}',
      'allergies:${compact(r.allergies)}',
      'maladiesChroniques:${compact(r.maladiesChroniques)}',
      'medicaments:${compact(r.medicaments)}',
      'antecedentsImportants:${compact(r.antecedentsImportants)}',
      'medecinTraitant:${compact(r.medecinTraitant)}',
      'medecinContact:${compact(r.medecinContact)}',
      'contactUrgence:${compact(r.contactUrgence)}',
    ];
    return lines.join('\n');
  }

  bool get _hasAnyMedicalData {
    final r = _buildRecordDraft();
    return [
      r.typeHandicap,
      r.groupeSanguin,
      r.allergies,
      r.maladiesChroniques,
      r.medicaments,
      r.antecedentsImportants,
      r.medecinTraitant,
      r.medecinContact,
      r.contactUrgence,
    ].any((e) => e != null && e.trim().isNotEmpty);
  }

  Future<void> _showQrPreview() async {
    if (!_hasAnyMedicalData) return;
    final qrData = _buildQrPayload(_buildRecordDraft());
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR du dossier médical',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportQrToPhone() async {
    if (!_hasAnyMedicalData || _exportingQr) return;
    setState(() => _exportingQr = true);
    try {
      final qrData = _buildQrPayload(_buildRecordDraft());
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      );
      final img = await painter.toImageData(
        1200,
        format: ui.ImageByteFormat.png,
      );
      if (img == null) throw Exception('QR image unavailable');
      final bytes = Uint8List.view(img.buffer);
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/medical_record_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'QR dossier médical Ma3ak');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de générer le QR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingQr = false);
    }
  }

  Future<void> _syncQrToCompanions(MedicalRecordModel record) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final payload = _buildQrPayload(record);
    final beneficiaryName = user.displayName.trim().isEmpty
        ? 'Bénéficiaire'
        : user.displayName.trim();
    final now = record.updatedAt ?? DateTime.now();
    try {
      final contacts = await ref
          .read(emergencyContactsRepositoryProvider)
          .getMyContacts();
      final companionIds = contacts
          .map((e) => e.accompagnantId.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await ref
          .read(localCompanionMedicalQrStoreProvider)
          .saveForCompanions(
            beneficiaryId: user.id,
            beneficiaryName: beneficiaryName,
            qrPayload: payload,
            updatedAt: now,
            companionIds: companionIds.isEmpty ? const ['*'] : companionIds,
          );
    } catch (_) {}
    try {
      await ref
          .read(medicalRecordsRepositoryProvider)
          .publishMyQr(qrPayload: payload, qrUpdatedAt: record.updatedAt);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final localRecord = _buildRecordDraft();
    await ref.read(localMedicalRecordStoreProvider).save(localRecord);
    _record = localRecord;
    try {
      final repo = ref.read(medicalRecordsRepositoryProvider);
      final isCloudExisting =
          _record != null && _record!.id.isNotEmpty && _record!.id != 'local';
      final saved = isCloudExisting
          ? await repo.updateMe(
              typeHandicap: localRecord.typeHandicap,
              groupeSanguin: localRecord.groupeSanguin,
              allergies: localRecord.allergies,
              maladiesChroniques: localRecord.maladiesChroniques,
              medicaments: localRecord.medicaments,
              antecedentsImportants: localRecord.antecedentsImportants,
              medecinTraitant: localRecord.medecinTraitant,
              medecinContact: localRecord.medecinContact,
              contactUrgence: localRecord.contactUrgence,
            )
          : await repo.create(
              typeHandicap: localRecord.typeHandicap,
              groupeSanguin: localRecord.groupeSanguin,
              allergies: localRecord.allergies,
              maladiesChroniques: localRecord.maladiesChroniques,
              medicaments: localRecord.medicaments,
              antecedentsImportants: localRecord.antecedentsImportants,
              medecinTraitant: localRecord.medecinTraitant,
              medecinContact: localRecord.medecinContact,
              contactUrgence: localRecord.contactUrgence,
            );
      _record = saved;
      await ref.read(localMedicalRecordStoreProvider).save(saved);
      await _syncQrToCompanions(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier médical synchronisé.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde cloud indisponible.')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || !user.isBeneficiary) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dossier médical')),
        body: const Center(child: Text('Réservé aux utilisateurs Handicapé.')),
      );
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier médical'),
        actions: [
          IconButton(
            tooltip: 'Carte d\'urgence',
            onPressed: () => context.push('/medical-emergency-card'),
            icon: const Icon(Icons.emergency),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: const Text('Numériser des documents'),
                  subtitle: const Text(
                    'Stockage local + partage QR accompagnant',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/medical-documents'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showQrPreview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Aperçu QR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _exportingQr ? null : _exportQrToPhone,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Enregistrer QR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _typeHandicapController,
                decoration: const InputDecoration(
                  labelText: 'Type de handicap',
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groupeSanguinController,
                decoration: const InputDecoration(
                  labelText: 'Groupe sanguin',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maladiesController,
                decoration: const InputDecoration(
                  labelText: 'Maladies chroniques',
                  prefixIcon: Icon(Icons.health_and_safety_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicamentsController,
                decoration: const InputDecoration(
                  labelText: 'Médicaments',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _antecedentsController,
                decoration: const InputDecoration(
                  labelText: 'Antécédents importants',
                  prefixIcon: Icon(Icons.history_edu_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medecinController,
                decoration: const InputDecoration(
                  labelText: 'Médecin traitant',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medecinContactController,
                decoration: const InputDecoration(
                  labelText: 'Contact médecin',
                  prefixIcon: Icon(Icons.contact_phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactUrgenceController,
                decoration: const InputDecoration(
                  labelText: 'Contact urgence',
                  prefixIcon: Icon(Icons.emergency),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
