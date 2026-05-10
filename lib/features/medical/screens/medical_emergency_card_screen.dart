import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/medical_record_model.dart';
import '../../../providers/api_providers.dart';

class MedicalEmergencyCardScreen extends ConsumerStatefulWidget {
  const MedicalEmergencyCardScreen({super.key});

  @override
  ConsumerState<MedicalEmergencyCardScreen> createState() =>
      _MedicalEmergencyCardScreenState();
}

class _MedicalEmergencyCardScreenState
    extends ConsumerState<MedicalEmergencyCardScreen> {
  MedicalRecordModel? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final localStore = ref.read(localMedicalRecordStoreProvider);
    final local = await localStore.read();
    if (mounted) {
      setState(() {
        _record = local;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte médicale d\'urgence'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune donnée d\'urgence hors ligne.\nOuvrez d\'abord le dossier médical.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _tile(
                  Icons.shield_outlined,
                  'Type de handicap',
                  _record!.typeHandicap,
                ),
                _tile(
                  Icons.bloodtype,
                  'Groupe sanguin',
                  _record!.groupeSanguin,
                ),
                _tile(
                  Icons.warning_amber_outlined,
                  'Allergies',
                  _record!.allergies,
                ),
                _tile(
                  Icons.medication_outlined,
                  'Médicaments',
                  _record!.medicaments,
                ),
                _tile(
                  Icons.local_hospital_outlined,
                  'Médecin',
                  _record!.medecinTraitant,
                ),
                _tile(
                  Icons.contact_phone_outlined,
                  'Contact médecin',
                  _record!.medecinContact,
                ),
                _tile(
                  Icons.phone_in_talk_outlined,
                  'Contact urgence',
                  _record!.contactUrgence,
                ),
              ],
            ),
    );
  }

  Widget _tile(IconData icon, String title, String? value) {
    final display = (value == null || value.trim().isEmpty)
        ? 'Non renseigné'
        : value.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(display),
      ),
    );
  }
}
