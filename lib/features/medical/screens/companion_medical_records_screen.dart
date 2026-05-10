import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/companion_medical_record_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

class CompanionMedicalRecordsScreen extends ConsumerStatefulWidget {
  const CompanionMedicalRecordsScreen({super.key});

  @override
  ConsumerState<CompanionMedicalRecordsScreen> createState() =>
      _CompanionMedicalRecordsScreenState();
}

class _CompanionMedicalRecordsScreenState
    extends ConsumerState<CompanionMedicalRecordsScreen> {
  bool _loading = true;
  String? _error;
  List<CompanionMedicalRecordModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(medicalRecordsRepositoryProvider)
          .getForAccompagnant();
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() => _items = list);
      } else {
        final me = ref.read(authStateProvider).valueOrNull;
        final local = me == null
            ? <CompanionMedicalRecordModel>[]
            : await ref
                  .read(localCompanionMedicalQrStoreProvider)
                  .getForCompanion(me.id);
        if (!mounted) return;
        setState(() => _items = local);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Synchronisation serveur indisponible.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRecord(CompanionMedicalRecordModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.beneficiaryName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: QrImageView(
                      data: item.qrPayload,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dossiers médicaux liés')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_error!),
                      ),
                    ),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'Aucun dossier médical synchronisé pour le moment.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._items.map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.health_and_safety_outlined),
                          title: Text(item.beneficiaryName),
                          subtitle: const Text(
                            'QR synchronisé automatiquement',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showRecord(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
