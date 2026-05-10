import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/map/route_result.dart';
import '../../../data/models/transport_model.dart';
import '../../../data/models/transport_request_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/transport_realtime_provider.dart';

/// Bleu primaire (aligné détail trajet).
const Color _primaryBlue = Color(0xFF1976D2);

/// Suivi en direct — UI type maquette : barre titre chip, carte (départ / voiture / arrivée), panneau bas (ETA, chauffeur, véhicule).
/// [shareToken] : mode invité (sans JWT) — `?token=` sur la route ou lien partagé.
class TransportSuiviScreen extends ConsumerStatefulWidget {
  const TransportSuiviScreen({
    super.key,
    required this.transportId,
    this.shareToken,
  });

  final String transportId;
  final String? shareToken;

  /// Mode invité (token de partage présent).
  bool get isGuest => shareToken != null && shareToken!.trim().isNotEmpty;

  @override
  ConsumerState<TransportSuiviScreen> createState() => _TransportSuiviScreenState();
}

class _TransportSuiviScreenState extends ConsumerState<TransportSuiviScreen> {
  TransportSuiviResult? _suivi;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSocket();
      await _load();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(transportSocketProvider).disconnect();
    super.dispose();
  }

  Future<void> _initSocket() async {
    try {
      final socket = ref.read(transportSocketProvider);
      if (widget.isGuest) {
        socket.connectGuest(AppConfig.baseUrl);
        socket.joinRideAsGuest(widget.transportId, widget.shareToken!);
      } else {
        final token = await ref.read(tokenStorageProvider).getToken() ?? '';
        socket.connect(AppConfig.baseUrl, token);
        socket.joinRide(widget.transportId);
      }
      socket.onDriverLocation((lat, lng) {
        ref.read(driverLocationProvider.notifier).state = LatLng(lat, lng);
      });
      socket.onStatusUpdate((statut) {
        ref.read(rideStatusProvider.notifier).state = statut;
        _handleStatutChange(statut);
      });
      socket.onServerError((msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      });
    } catch (e) {
      debugPrint('[Suivi] Socket : $e');
    }
  }

  void _handleStatutChange(String statut) {
    HapticFeedback.mediumImpact();
    if (statut == 'ARRIVEE') {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre chauffeur est arrivé !')),
        );
      }
    }
    if (statut == 'TERMINEE' || statut == 'ANNULEE') {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (widget.isGuest) {
          context.pop();
        } else {
          context.go('/transport/history');
        }
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(transportRepositoryProvider);
      final s = widget.isGuest
          ? await repo.getSuiviPublic(widget.transportId, widget.shareToken!)
          : await repo.getSuivi(widget.transportId);
      if (mounted) {
        if (s.statut != null) {
          ref.read(rideStatusProvider.notifier).state = s.statut!;
        }
        setState(() {
          _suivi = s;
          _loading = false;
        });
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadSilent());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSilent() async {
    if (!mounted) return;
    try {
      final repo = ref.read(transportRepositoryProvider);
      final s = widget.isGuest
          ? await repo.getSuiviPublic(widget.transportId, widget.shareToken!)
          : await repo.getSuivi(widget.transportId);
      if (mounted) {
        setState(() => _suivi = s);
        if (s.statut != null) {
          ref.read(rideStatusProvider.notifier).state = s.statut!;
        }
      }
    } catch (_) {}
  }

  List<LatLng> _parseItineraireGeometry(Map<String, dynamic>? itineraire) {
    if (itineraire == null) return [];
    final geom = itineraire['geometry'];
    if (geom is! Map<String, dynamic>) return [];
    try {
      final routeGeom = RouteGeometry.fromJson(geom);
      return routeGeom.toLatLngList();
    } catch (_) {
      return [];
    }
  }

  LatLng? _chauffeurPoint(TransportSuiviResult s, LatLng? live) {
    if (live != null) return live;
    final p = s.positionChauffeur;
    if (p != null &&
        p['lat'] != null &&
        p['lon'] != null) {
      return LatLng(p['lat']!, p['lon']!);
    }
    return null;
  }

  void _fitBounds() {
    final s = _suivi;
    if (s == null) return;
    final transport = s.transport;
    final live = ref.read(driverLocationProvider);
    final positionChauffeur = _chauffeurPoint(s, live);
    final routePoints = _parseItineraireGeometry(s.itineraire);
    final allPoints = <LatLng>[
      if (positionChauffeur != null) positionChauffeur,
      ...routePoints,
      if (transport != null && transport.latitudeArrivee != null && transport.longitudeArrivee != null)
        LatLng(transport.latitudeArrivee!, transport.longitudeArrivee!),
      if (transport != null && transport.latitudeDepart != null && transport.longitudeDepart != null)
        LatLng(transport.latitudeDepart!, transport.longitudeDepart!),
    ];
    if (allPoints.length < 2) return;
    double minLat = allPoints.first.latitude, maxLat = allPoints.first.latitude;
    double minLon = allPoints.first.longitude, maxLon = allPoints.first.longitude;
    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = widget.isGuest
        ? AppStrings.fr()
        : AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final liveDriver = ref.watch(driverLocationProvider);

    if (_loading && _suivi == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, strings),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    if (_error != null && _suivi == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, strings),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: Text(strings.save)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _suivi!;
    final transport = s.transport;
    final chauffeurPoint = _chauffeurPoint(s, liveDriver);
    final routePoints = _parseItineraireGeometry(s.itineraire);

    LatLng center = const LatLng(36.8065, 10.1815);
    double zoom = 12;
    if (chauffeurPoint != null) {
      center = chauffeurPoint;
      zoom = 14;
    }

    final allPoints = <LatLng>[
      if (chauffeurPoint != null) chauffeurPoint,
      ...routePoints,
      if (transport != null && transport.latitudeArrivee != null && transport.longitudeArrivee != null)
        LatLng(transport.latitudeArrivee!, transport.longitudeArrivee!),
      if (transport != null && transport.latitudeDepart != null && transport.longitudeDepart != null)
        LatLng(transport.latitudeDepart!, transport.longitudeDepart!),
    ];

    if (allPoints.length >= 2) {
      double minLat = allPoints.first.latitude, maxLat = allPoints.first.latitude;
      double minLon = allPoints.first.longitude, maxLon = allPoints.first.longitude;
      for (final p in allPoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }
      center = LatLng(
        (minLat + maxLat) / 2,
        (minLon + maxLon) / 2,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, strings),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.flingAnimation,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'tn.ma3ak.app',
                      ),
                      if (routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              color: _primaryBlue,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (transport != null &&
                              transport.latitudeDepart != null &&
                              transport.longitudeDepart != null)
                            Marker(
                              point: LatLng(transport.latitudeDepart!, transport.longitudeDepart!),
                              width: 56,
                              height: 56,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.trip_origin, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    strings.labelDeparture,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (transport != null &&
                              transport.latitudeArrivee != null &&
                              transport.longitudeArrivee != null)
                            Marker(
                              point: LatLng(transport.latitudeArrivee!, transport.longitudeArrivee!),
                              width: 56,
                              height: 56,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.flag, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    strings.labelArrival,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (chauffeurPoint != null)
                            Marker(
                              point: chauffeurPoint,
                              width: 52,
                              height: 52,
                              child: liveDriver != null
                                  ? Semantics(
                                      label: 'Position actuelle du chauffeur',
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D9E75),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.directions_car,
                                            color: Colors.white, size: 24),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _primaryBlue.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.directions_car, color: Colors.white, size: 26),
                                    ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 12,
                    top: 80,
                    child: Column(
                      children: [
                        _MapControlButton(
                          icon: Icons.my_location,
                          onPressed: _fitBounds,
                        ),
                        const SizedBox(height: 8),
                        _MapControlButton(
                          icon: Icons.add,
                          onPressed: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(_mapController.camera.center, zoom + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isGuest)
                    Positioned(
                      bottom: 140,
                      right: 16,
                      child: Semantics(
                        label: 'Bouton SOS urgence',
                        button: true,
                        child: FloatingActionButton(
                          backgroundColor: const Color(0xFFE24B4A),
                          heroTag: 'sos_transport',
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            try {
                              final pos = await Geolocator.getCurrentPosition();
                              await ref.read(sosRepositoryProvider).create(
                                    latitude: pos.latitude,
                                    longitude: pos.longitude,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Alerte SOS envoyée'),
                                  backgroundColor: Color(0xFFE24B4A),
                                ),
                              );
                            } catch (e) {
                              debugPrint('[SOS] Erreur : $e');
                            }
                          },
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildBottomPanel(strings, theme, s),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: Semantics(
              label: 'Retour',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final statut = ref.watch(rideStatusProvider);
                      return Semantics(
                        label:
                            'Statut du trajet : ${TransportRequestModel.labelForStatut(statut)}',
                        liveRegion: true,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: TransportRequestModel.colorForStatut(statut),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            TransportRequestModel.labelForStatut(statut),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.liveTracking,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(AppStrings strings, ThemeData theme, TransportSuiviResult suivi) {
    final transport = suivi.transport;
    final apiDriver = suivi.driver;
    final demandeurDriver = transport?.accompagnant;
    final vehicle = transport?.vehicle;

    final String displayName;
    final String photoForUrl;
    final double note;
    final String? phone;
    if (apiDriver != null) {
      displayName = '${apiDriver.prenom} ${apiDriver.nom}'.trim();
      photoForUrl = apiDriver.photoProfil ?? '';
      note = apiDriver.noteMoyenne;
      phone = apiDriver.telephone;
    } else {
      displayName = demandeurDriver?.displayName ?? '—';
      photoForUrl = demandeurDriver?.photoProfil ?? '';
      note = demandeurDriver?.noteMoyenne ?? 0;
      phone = demandeurDriver?.telephone;
    }
    final photoUrl = UserRepository.photoUrl(photoForUrl.isEmpty ? null : photoForUrl);

    final eta = suivi.eta;
    final minutes = eta?.dureeMinutes.round() ?? 0;
    final etaTime = eta != null
        ? DateTime.now().add(Duration(minutes: minutes))
        : null;
    final etaTimeStr = etaTime != null
        ? '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$minutes min',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.estimatedArrivalLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final statut = ref.watch(rideStatusProvider);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: TransportRequestModel.colorForStatut(statut),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            TransportRequestModel.labelForStatut(statut),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    etaTimeStr,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (apiDriver != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFA9F42), size: 14),
                          Text(
                            ' ${note.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vehicle != null
                                ? '${vehicle.displayName} · ${vehicle.immatriculation}'
                                : '—',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                Semantics(
                  label: 'Appeler le chauffeur',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFF7F77DD)),
                    tooltip: 'Appeler le chauffeur',
                    onPressed: () async {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                )
              else
                IconButton(
                  onPressed: null,
                  style: IconButton.styleFrom(
                    backgroundColor: _primaryBlue.withValues(alpha: 0.12),
                  ),
                  icon: Icon(Icons.phone_disabled, color: Colors.grey.shade400, size: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(icon, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}
