import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/address_search_field.dart';
import '../../../core/widgets/ma3ak_map_widget.dart';
import '../../../data/models/map/route_result.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/api_providers.dart';

/// Écran Transport : carte, choix départ/destination, calcul et affichage du trajet.
class TransportMapScreen extends ConsumerStatefulWidget {
  const TransportMapScreen({super.key});

  @override
  ConsumerState<TransportMapScreen> createState() => _TransportMapScreenState();
}

class _TransportMapScreenState extends ConsumerState<TransportMapScreen> {
  final _lieuDepartController = TextEditingController();
  final _lieuDestinationController = TextEditingController();
  double? _originLat;
  double? _originLon;
  double? _destLat;
  double? _destLon;
  RouteResult? _routeResult;
  bool _routeLoading = false;
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);

  @override
  void dispose() {
    _lieuDepartController.dispose();
    _lieuDestinationController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    final departureText = _lieuDepartController.text.trim();
    final destinationText = _lieuDestinationController.text.trim();
    if (departureText.isEmpty || destinationText.isEmpty) return;

    setState(() => _routeLoading = true);
    try {
      final repo = ref.read(mapRepositoryProvider);
      double originLat = _originLat ?? 0, originLon = _originLon ?? 0;
      double destLat = _destLat ?? 0, destLon = _destLon ?? 0;

      if (_originLat == null || _originLon == null) {
        final list = await repo.geocode(query: departureText, countrycodes: 'TN', limit: 1);
        if (list.isEmpty) throw Exception('Adresse de départ introuvable');
        originLat = list.first.lat;
        originLon = list.first.lon;
        if (mounted) setState(() { _originLat = originLat; _originLon = originLon; });
      }
      if (_destLat == null || _destLon == null) {
        final list = await repo.geocode(query: destinationText, countrycodes: 'TN', limit: 1);
        if (list.isEmpty) throw Exception('Adresse de destination introuvable');
        destLat = list.first.lat;
        destLon = list.first.lon;
        if (mounted) setState(() { _destLat = destLat; _destLon = destLon; });
      }

      final result = await repo.route(
        originLat: originLat,
        originLon: originLon,
        destinationLat: destLat,
        destinationLon: destLon,
      );
      if (mounted) setState(() { _routeResult = result; _routeLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _routeLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();
    final origin = (_originLat != null && _originLon != null)
        ? LatLng(_originLat!, _originLon!)
        : null;
    final destination = (_destLat != null && _destLon != null)
        ? LatLng(_destLat!, _destLon!)
        : null;
    final hasDeparture = _lieuDepartController.text.isNotEmpty;
    final hasDestination = _lieuDestinationController.text.isNotEmpty;
    final canCalculate = hasDeparture && hasDestination;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          strings.transport,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddressSearchField(
                    controller: _lieuDepartController,
                    label: strings.departurePlace,
                    hint: strings.searchAddress,
                    countrycodes: 'TN',
                    limit: 5,
                    onSelected: (r) {
                      if (r != null) {
                        setState(() {
                          _originLat = r.lat;
                          _originLon = r.lon;
                          _routeResult = null;
                        });
                      } else {
                        setState(() { _originLat = null; _originLon = null; _routeResult = null; });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AddressSearchField(
                    controller: _lieuDestinationController,
                    label: strings.destinationPlace,
                    hint: strings.searchAddress,
                    countrycodes: 'TN',
                    limit: 5,
                    onSelected: (r) {
                      if (r != null) {
                        setState(() {
                          _destLat = r.lat;
                          _destLon = r.lon;
                          _routeResult = null;
                        });
                      } else {
                        setState(() { _destLat = null; _destLon = null; _routeResult = null; });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: canCalculate && !_routeLoading ? _calculateRoute : null,
                    icon: _routeLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.route, size: 22),
                    label: Text(
                      _routeLoading
                          ? (strings.isAr ? 'جاري الحساب...' : 'Calcul en cours...')
                          : (canCalculate ? strings.calculateRoute : strings.fillAddressesFirst),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  if (_routeResult != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(
                          icon: Icons.straighten,
                          text: '${strings.routeDistance} : ${_routeResult!.distanceFormatted}',
                        ),
                        _buildInfoChip(
                          icon: Icons.schedule,
                          text: '${strings.routeDuration} : ${_routeResult!.durationFormatted}',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Ma3akMapWidget(
                      initialCenter: origin ?? destination ?? _tunisCenter,
                      initialZoom: 11,
                      origin: origin,
                      destination: destination,
                      routeResult: _routeResult,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: _primaryBlue),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
