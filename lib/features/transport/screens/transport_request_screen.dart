import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/address_search_field.dart';
import '../../../data/models/map/geocode_result.dart';
import '../../../data/models/motif_trajet.dart';
import '../../../data/models/transport_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/api_providers.dart';

/// Écran de demande de transport adapté : urgence ou quotidien, lieu de départ, destination, optionnellement date/heure et type d'assistance.
class TransportRequestScreen extends ConsumerStatefulWidget {
  const TransportRequestScreen({super.key});

  @override
  ConsumerState<TransportRequestScreen> createState() =>
      _TransportRequestScreenState();
}

class _TransportRequestScreenState extends ConsumerState<TransportRequestScreen> {
  final _departController = TextEditingController();
  final _destinationController = TextEditingController();
  GeocodeResult? _departGeocode;
  GeocodeResult? _destinationGeocode;

  TransportType _type = TransportType.quotidien;
  bool _scheduleLater = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  /// Estimation locale (itinéraire) avant création de la course.
  Map<String, String>? _priceEstimate;

  /// Clés exactes attendues par le backend.
  static const List<Map<String, String>> _besoinsOptions = [
    {'key': 'fauteuil_roulant', 'label': 'Fauteuil roulant', 'icon': '♿'},
    {'key': 'aide_embarquement', 'label': 'Aide montée/descente', 'icon': '🤝'},
    {'key': 'rampe_acces', 'label': 'Rampe d\'accès', 'icon': '🔔'},
    {'key': 'porte_large', 'label': 'Porte large', 'icon': '🚪'},
  ];

  final List<String> _besoinsAssistance = [];
  MotifTrajet? _motif;
  bool _prioriteMedicale = false;

  @override
  void dispose() {
    _departController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _estimerPrixSiPossible() async {
    final d = _departGeocode;
    final a = _destinationGeocode;
    if (d == null || a == null) return;
    try {
      final route = await ref.read(mapRepositoryProvider).route(
            originLat: d.lat,
            originLon: d.lon,
            destinationLat: a.lat,
            destinationLon: a.lon,
          );
      final distKm = route.distance / 1000;
      final durMin = route.duration / 60;
      final prix = 2.5 + distKm * 0.8 + durMin * 0.15;
      if (mounted) {
        setState(() => _priceEstimate = {
              'distanceKm': distKm.toStringAsFixed(1),
              'durationMin': durMin.toStringAsFixed(0),
              'prixEstimeTnd': prix.toStringAsFixed(2),
            });
      }
    } catch (_) {
      /* estimation optionnelle */
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit(AppStrings strings) async {
    final departName = _departGeocode?.displayName ?? _departController.text.trim();
    final destName = _destinationGeocode?.displayName ?? _destinationController.text.trim();

    if (departName.isEmpty || destName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.fillAddressesFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double? latDepart;
    double? lonDepart;
    double? latArrivee;
    double? lonArrivee;
    if (_departGeocode != null) {
      latDepart = _departGeocode!.lat;
      lonDepart = _departGeocode!.lon;
    }
    if (_destinationGeocode != null) {
      latArrivee = _destinationGeocode!.lat;
      lonArrivee = _destinationGeocode!.lon;
    }

    DateTime dateHeure;
    if (_type == TransportType.quotidien && _scheduleLater) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.chooseDateAndTime)),
        );
        return;
      }
      dateHeure = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      // Le backend exige toujours une date ISO 8601, même pour "Immédiat".
      dateHeure = DateTime.now();
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(transportRepositoryProvider);
      await repo.create(
        typeTransport: _type.toApiString(),
        depart: departName,
        destination: destName,
        latitudeDepart: latDepart,
        longitudeDepart: lonDepart,
        latitudeArrivee: latArrivee,
        longitudeArrivee: lonArrivee,
        dateHeure: dateHeure.toUtc(),
        besoinsAssistance: List<String>.from(_besoinsAssistance),
        motifTrajet: _motif,
        prioriteMedicale: _motif == MotifTrajet.medical ? _prioriteMedicale : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.transportRequestSent),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          strings.creationRequestTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == 0 ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              strings.chooseTransportType,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: strings.transportUrgency,
                    selected: _type == TransportType.urgence,
                    onTap: () => setState(() => _type = TransportType.urgence),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChip(
                    label: strings.transportDaily,
                    selected: _type == TransportType.quotidien,
                    onTap: () => setState(() => _type = TransportType.quotidien),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings.tripMotifLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MotifTrajet?>(
              value: _motif,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<MotifTrajet?>(
                  value: null,
                  child: Text(strings.motifNone),
                ),
                DropdownMenuItem(
                  value: MotifTrajet.medical,
                  child: Text(strings.motifMedical),
                ),
                DropdownMenuItem(
                  value: MotifTrajet.administratif,
                  child: Text(strings.motifAdministratif),
                ),
                DropdownMenuItem(
                  value: MotifTrajet.quotidien,
                  child: Text(strings.motifQuotidienMotif),
                ),
                DropdownMenuItem(
                  value: MotifTrajet.loisir,
                  child: Text(strings.motifLoisir),
                ),
              ],
              onChanged: (v) => setState(() {
                _motif = v;
                if (v != MotifTrajet.medical) _prioriteMedicale = false;
              }),
            ),
            if (_motif == MotifTrajet.medical) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.medicalPriorityLabel),
                value: _prioriteMedicale,
                onChanged: (v) => setState(() => _prioriteMedicale = v),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              strings.departure,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AddressSearchField(
              controller: _departController,
              hint: strings.departure,
              countrycodes: 'TN',
              limit: 6,
              onSelected: (r) {
                setState(() {
                  _departGeocode = r;
                  if (r != null) _departController.text = r.displayName;
                });
                _estimerPrixSiPossible();
              },
            ),
            const SizedBox(height: 20),
            Text(
              strings.destination,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AddressSearchField(
              controller: _destinationController,
              hint: strings.destination,
              countrycodes: 'TN',
              limit: 6,
              onSelected: (r) {
                setState(() {
                  _destinationGeocode = r;
                  if (r != null) _destinationController.text = r.displayName;
                });
                _estimerPrixSiPossible();
              },
            ),
            if (_priceEstimate != null) ...[
              const SizedBox(height: 16),
              Semantics(
                label: 'Estimation : ${_priceEstimate!['prixEstimeTnd']} TND '
                    'pour ${_priceEstimate!['distanceKm']} kilomètres',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('${_priceEstimate!['distanceKm']} km'),
                      const Text('·'),
                      Text('${_priceEstimate!['durationMin']} min'),
                      const Text('·'),
                      Text(
                        '${_priceEstimate!['prixEstimeTnd']} TND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_type == TransportType.quotidien) ...[
              const SizedBox(height: 24),
              Text(
                strings.scheduleDateAndTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: strings.requestNow,
                      selected: !_scheduleLater,
                      onTap: () => setState(() => _scheduleLater = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeChip(
                      label: strings.scheduleLater,
                      selected: _scheduleLater,
                      onTap: () => setState(() => _scheduleLater = true),
                    ),
                  ),
                ],
              ),
              if (_scheduleLater) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(context),
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(context),
                        icon: const Icon(Icons.access_time, size: 20),
                        label: Text(
                          _selectedTime != null
                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Heure',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_scheduleLater && (_selectedDate == null || _selectedTime == null))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Veuillez choisir une date et une heure.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ),
              ],
            ],
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Besoins d\'assistance',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _besoinsOptions
                      .map(
                        (b) => Semantics(
                          label: b['label']!,
                          selected: _besoinsAssistance.contains(b['key']),
                          child: FilterChip(
                            label: Text('${b['icon']}  ${b['label']}'),
                            selected: _besoinsAssistance.contains(b['key']),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _besoinsAssistance.add(b['key']!);
                              } else {
                                _besoinsAssistance.remove(b['key']!);
                              }
                            }),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submit(strings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.continueButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cs.primary : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

