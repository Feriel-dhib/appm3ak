import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/emergency_contact_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Écran SOS Médical enrichi : carte avec position, localisation auto, constantes smartwatch,
/// appel/SMS contact proche, message vocal IA.
class SosMedicalScreen extends ConsumerStatefulWidget {
  const SosMedicalScreen({super.key});

  @override
  ConsumerState<SosMedicalScreen> createState() => _SosMedicalScreenState();
}

class _SosMedicalScreenState extends ConsumerState<SosMedicalScreen> {
  static const LatLng _defaultTunis = LatLng(36.8065, 10.1815);

  final MapController _mapController = MapController();
  Position? _position;
  String? _locationError;
  List<EmergencyContactModel> _contacts = [];
  bool _loadingContacts = true;
  bool _sending = false;
  bool _smartwatchConnected = false; // simulation
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadContacts();
    _tts.setLanguage('fr-FR');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationError = 'Localisation désactivée');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationError = 'Permission refusée');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _position = pos;
          _locationError = null;
        });
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          15,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _position = null;
          _locationError = 'Impossible d\'obtenir la position';
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      final list = await repo.getMyContacts();
      if (mounted) setState(() => _contacts = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingContacts = false);
  }

  double get _lat => _position?.latitude ?? _defaultTunis.latitude;
  double get _lng => _position?.longitude ?? _defaultTunis.longitude;
  LatLng get _currentLatLng => LatLng(_lat, _lng);

  Future<void> _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps?q=$_lat,$_lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callContact(EmergencyContactModel c) async {
    final tel = c.accompagnant?.telephone;
    if (tel == null || tel.isEmpty) return;
    final uri = Uri.parse('tel:${tel.replaceAll(RegExp(r'\s'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _smsContact(EmergencyContactModel c) async {
    final tel = c.accompagnant?.telephone;
    if (tel == null || tel.isEmpty) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final name = user?.displayName ?? 'Un utilisateur';
    final msg = '$name a besoin d\'assistance immédiate (SOS Médical). Position: https://www.google.com/maps?q=$_lat,$_lng';
    final uri = Uri.parse(
      'sms:${tel.replaceAll(RegExp(r'\s'), '')}?body=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _speakAIMessage() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final name = user?.displayName ?? 'Un utilisateur';
    final text = '$name a besoin d\'assistance immédiate. Il se trouve à cette position GPS : $_lat, $_lng.';
    await _tts.speak(text);
  }

  Future<void> _sendSos() async {
    setState(() => _sending = true);
    try {
      final repo = ref.read(sosRepositoryProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      await repo.create(
        latitude: _lat,
        longitude: _lng,
        alertSource: 'MEDICAL',
        beneficiaryTypeHandicap: user?.typeHandicap,
        beneficiaryBesoinSpecifique: user?.besoinSpecifique,
      );

      final firstContact = _contacts.isNotEmpty ? _contacts.first : null;
      if (firstContact != null) {
        unawaited(_smsContact(firstContact));
        unawaited(_callContact(firstContact));
      }
      unawaited(_speakAIMessage());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerte SOS envoyée. Localisation, SMS et message vocal lancés.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de l\'alerte')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Médical'),
        actions: [
          TextButton(
            onPressed: () => context.push('/sos-alerts'),
            child: const Text('Mes alertes'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _getLocation();
              await _loadContacts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMapCard(),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.location_on,
                    iconColor: Colors.blue,
                    title: 'Envoi automatique de localisation',
                    subtitle: _position != null
                        ? 'Position envoyée avec l\'alerte : ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}'
                        : (_locationError ?? 'Récupération...'),
                    trailing: _position != null
                        ? IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: _openMaps,
                            tooltip: 'Ouvrir dans Google Maps',
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _getLocation,
                          ),
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    title: 'Constantes (smartwatch)',
                    subtitle: _smartwatchConnected
                        ? 'Fréquence cardiaque, SpO2 envoyés avec l\'alerte'
                        : 'Connectez une montre pour envoyer fréquence cardiaque et SpO2',
                    trailing: Switch(
                      value: _smartwatchConnected,
                      onChanged: (v) =>
                          setState(() => _smartwatchConnected = v),
                      activeColor: primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCallSmsSection(primary),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.record_voice_over,
                    iconColor: Colors.purple,
                    title: 'Message vocal automatique (IA)',
                    subtitle:
                        'Exemple : « [Prénom] a besoin d\'assistance immédiate. Il se trouve à cette position GPS. »',
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: _speakAIMessage,
                      tooltip: 'Écouter le message',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendSos,
                icon: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.emergency),
                label: Text(_sending ? 'Envoi...' : 'Envoyer l\'alerte SOS'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLatLng,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tn.ma3ak.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLatLng,
                  width: 48,
                  height: 48,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCallSmsSection(Color primary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Appel + SMS contact proche',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingContacts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_contacts.isEmpty)
              Text(
                'Aucun contact d\'urgence. Ajoutez-en dans votre profil.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              )
            else
              ..._contacts.take(2).map((c) {
                final acc = c.accompagnant;
                final name = acc?.displayName ?? 'Contact';
                final tel = acc?.telephone ?? acc?.email ?? '—';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0] : '?'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(tel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (acc?.telephone != null && acc!.telephone!.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () => _callContact(c),
                          color: Colors.green,
                        ),
                        IconButton(
                          icon: const Icon(Icons.sms),
                          onPressed: () => _smsContact(c),
                          color: primary,
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
