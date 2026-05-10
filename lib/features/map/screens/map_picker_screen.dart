import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/geolocation_utils.dart';
import '../../../data/models/map/geocode_result.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Écran plein écran : carte, tap pour choisir un point → reverse-geocode → retourne [GeocodeResult].
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({
    super.key,
    this.title,
    this.initialCenter = const LatLng(36.8065, 10.1815),
    this.initialZoom = 12,
  });

  final String? title;
  final LatLng initialCenter;
  final double initialZoom;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final _mapController = MapController();
  LatLng? _pickedPoint;
  GeocodeResult? _geocodeResult;
  bool _loading = false;
  bool _gettingLocation = false;
  static const Color _primaryBlue = Color(0xFF1976D2);

  Future<void> _goToCurrentLocation() async {
    setState(() => _gettingLocation = true);
    final strings = AppStrings.fromPreferredLanguage(
      ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
    );
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      late final double lat;
      late final double lon;
      String? infoSnack;

      try {
        final position = await resolveUserPosition();
        final gLat = position.latitude;
        final gLon = position.longitude;
        final adj = preferTunisiaProfileWhenGpsMismatch(
          gpsLat: gLat,
          gpsLon: gLon,
          profileLat: user?.latitude,
          profileLon: user?.longitude,
        );
        lat = adj.lat;
        lon = adj.lon;
        if (adj.lat != gLat || adj.lon != gLon) {
          infoSnack = strings.usedProfileLocationInsteadOfGps;
        }
      } on GeolocationError catch (e) {
        if (!mounted) return;
        if (e == GeolocationError.permissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'L\'accès à la position est nécessaire. Activez-la dans les paramètres.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        final fb = profileCoordinatesFallback(user?.latitude, user?.longitude);
        if (fb != null &&
            (e == GeolocationError.timeout ||
                e == GeolocationError.serviceDisabled)) {
          lat = fb.lat;
          lon = fb.lon;
          infoSnack = strings.usedSavedCoordinatesWhenGpsUnavailable;
        } else {
          final msg = switch (e) {
            GeolocationError.serviceDisabled =>
              'Activez la localisation (GPS) et réessayez.',
            GeolocationError.timeout =>
              'Délai dépassé. Déplacez la carte manuellement ou réessayez.',
            GeolocationError.permissionDenied => '',
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('disabled')
                    ? 'Activez le GPS et réessayez.'
                    : 'Impossible d\'obtenir la position.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final point = LatLng(lat, lon);
      if (!mounted) return;
      _mapController.move(point, 16);
      await _onMapTap(point);
      if (!mounted) return;
      if (infoSnack != null) {
        final bg = Theme.of(context).colorScheme.secondaryContainer;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(infoSnack),
            backgroundColor: bg,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _pickedPoint = point;
      _geocodeResult = null;
      _loading = true;
    });
    try {
      final repo = ref.read(mapRepositoryProvider);
      final result = await repo.reverseGeocodeGet(lat: point.latitude, lon: point.longitude);
      if (mounted) {
        setState(() {
          _geocodeResult = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer l\'adresse pour ce point.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _confirm() {
    if (_geocodeResult != null) {
      Navigator.of(context).pop(_geocodeResult);
    } else if (_pickedPoint != null) {
      Navigator.of(context).pop(GeocodeResult(
        lat: _pickedPoint!.latitude,
        lon: _pickedPoint!.longitude,
        displayName: '${_pickedPoint!.latitude.toStringAsFixed(5)}, ${_pickedPoint!.longitude.toStringAsFixed(5)}',
        type: 'point',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.fr();
    final title = widget.title ?? strings.chooseOnMap;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              onTap: (_, point) => _onMapTap(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.flingAnimation,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tn.ma3ak.app',
              ),
              if (_pickedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          if (_loading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Adresse en cours...'),
                    ],
                  ),
                ),
              ),
            ),
          // Bouton Ma position (localisation actuelle)
          Positioned(
            right: 16,
            bottom: _geocodeResult != null || _pickedPoint != null ? 200 : 24,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: InkWell(
                onTap: _gettingLocation ? null : _goToCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _gettingLocation
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location, color: _primaryBlue, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              strings.currentLocation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          if (!_loading && (_geocodeResult != null || _pickedPoint != null))
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_geocodeResult != null)
                        Text(
                          _geocodeResult!.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${_pickedPoint!.latitude.toStringAsFixed(5)}, ${_pickedPoint!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check),
                          label: Text(strings.save),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
