import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/address_search_field.dart';
import '../../../data/models/driver_nearby.dart';
import '../../../data/models/map/geocode_result.dart';
import '../../../data/models/map/route_result.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/vehicle_providers.dart';

/// Écran Transport réel : barre "Transport", champ "Où allez-vous ?", carte, bottom sheet "Chauffeurs à proximité".
class TransportDynamicScreen extends ConsumerStatefulWidget {
  const TransportDynamicScreen({super.key});

  @override
  ConsumerState<TransportDynamicScreen> createState() => _TransportDynamicScreenState();
}

class _TransportDynamicScreenState extends ConsumerState<TransportDynamicScreen> {
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);

  final _searchController = TextEditingController();
  final _mapController = MapController();
  Timer? _debounce;

  List<GeocodeResult> _searchResults = [];
  GeocodeResult? _selectedPlace;
  LatLng? _origin;
  LatLng? _destination;
  String? _originName;
  String? _destinationName;
  RouteResult? _routeResult;
  bool _routeLoading = false;
  bool _showRouteSheet = false;
  LatLng? _tappedPoint;
  GeocodeResult? _tappedGeocode;
  bool _tappedLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showObstacleAndGuidanceSheet() {
    final user = ref.read(authStateProvider).valueOrNull;
    final st = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                st.obstacleNavHubTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.remove_red_eye_outlined),
              title: Text(st.obstacleDetection),
              subtitle: Text(st.obstacleNavOptionSoloSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transport/obstacle-detection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(st.obstacleNavOptionGuided),
              subtitle: Text(st.obstacleNavOptionGuidedSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transport/obstacle-guided-ar');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _selectedPlace = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _doSearch(q));
  }

  Future<void> _doSearch(String query) async {
    setState(() {});
    try {
      final repo = ref.read(mapRepositoryProvider);
      final list = await repo.geocode(query: query, countrycodes: 'TN', limit: 8);
      if (mounted) {
        setState(() {
          _searchResults = list;
          if (list.isNotEmpty) _selectedPlace = null;
        });
        if (list.length == 1) {
          _mapController.move(LatLng(list.first.lat, list.first.lon), 14);
        } else if (list.isNotEmpty) {
          _fitBounds(list);
        }
      }
    } catch (_) {
      if (mounted) setState(() { _searchResults = []; });
    }
  }

  void _fitBounds(List<GeocodeResult> list) {
    double minLat = list.first.lat, maxLat = list.first.lat;
    double minLon = list.first.lon, maxLon = list.first.lon;
    for (final p in list) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    final bounds = LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)));
  }

  void _onPlaceTap(GeocodeResult place) {
    setState(() {
      _selectedPlace = place;
      _showRouteSheet = false;
      _tappedPoint = null;
      _tappedGeocode = null;
    });
    _mapController.move(LatLng(place.lat, place.lon), 15);
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedPlace = null;
      _tappedPoint = point;
      _tappedGeocode = null;
      _tappedLoading = true;
    });
    try {
      final repo = ref.read(mapRepositoryProvider);
      final result = await repo.reverseGeocodeGet(lat: point.latitude, lon: point.longitude);
      if (mounted) {
        setState(() {
          _tappedGeocode = result;
          _tappedLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _tappedLoading = false);
        final u = ref.read(authStateProvider).valueOrNull;
        final st = u != null
            ? AppStrings.fromPreferredLanguage(u.preferredLanguage?.name)
            : AppStrings.fr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(st.reverseGeocodeError)),
        );
      }
    }
  }

  void _useTappedAsOrigin() {
    if (_tappedPoint == null) return;
    final name = _tappedGeocode?.displayName ?? '${_tappedPoint!.latitude.toStringAsFixed(5)}, ${_tappedPoint!.longitude.toStringAsFixed(5)}';
    setState(() {
      _origin = _tappedPoint;
      _originName = name;
      _tappedPoint = null;
      _tappedGeocode = null;
    });
  }

  void _useTappedAsDestination() {
    if (_tappedPoint == null) return;
    final name = _tappedGeocode?.displayName ?? '${_tappedPoint!.latitude.toStringAsFixed(5)}, ${_tappedPoint!.longitude.toStringAsFixed(5)}';
    setState(() {
      _destination = _tappedPoint;
      _destinationName = name;
      _tappedPoint = null;
      _tappedGeocode = null;
    });
  }

  Future<void> _calculateRouteToSelected() async {
    if (_selectedPlace == null) return;
    final dest = LatLng(_selectedPlace!.lat, _selectedPlace!.lon);
    _destination ??= dest;
    _destinationName ??= _selectedPlace!.displayName;
    await _calculateRouteBetweenOriginAndDestination();
  }

  Future<void> _calculateRouteBetweenOriginAndDestination() async {
    final origin = _origin ?? _tunisCenter;
    final dest = _destination;
    if (dest == null) return;
    setState(() => _routeLoading = true);
    try {
      final repo = ref.read(mapRepositoryProvider);
      final result = await repo.route(
        originLat: origin.latitude,
        originLon: origin.longitude,
        destinationLat: dest.latitude,
        destinationLon: dest.longitude,
      );
      if (mounted) {
        setState(() {
          _origin ??= _tunisCenter;
          _originName ??= 'Tunis';
          _routeResult = result;
          _routeLoading = false;
          _showRouteSheet = true;
        });
        _fitBoundsRoute();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _routeLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _fitBoundsRoute() {
    if (_routeResult == null) return;
    final points = _routeResult!.geometry.toLatLngList();
    if (points.length < 2) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLon = points.first.longitude, maxLon = points.first.longitude;
    for (final p in points) {
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
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();

    final showCustomSheet = _selectedPlace != null ||
        (_showRouteSheet && _routeResult != null) ||
        _tappedPoint != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          strings.transport,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home?tab=0');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: strings.myRequestsTitle,
            onPressed: () => context.push('/transport/my-requests'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: strings.tripHistory,
            onPressed: () => context.push('/transport/history'),
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            tooltip: strings.obstacleNavHubTitle,
            onPressed: _showObstacleAndGuidanceSheet,
          ),
          TextButton.icon(
            onPressed: () => context.push('/transport/request'),
            icon: const Icon(Icons.add_road, size: 20),
            label: Text(strings.requestTransportShort),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Champ de recherche destination : "Où allez-vous ?"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AddressSearchField(
              controller: _searchController,
              hint: strings.whereAreYouGoing,
              countrycodes: 'TN',
              limit: 8,
              onSelected: (r) {
                if (r != null) {
                  setState(() {
                    _searchResults = [r];
                    _selectedPlace = r;
                    _showRouteSheet = false;
                    _tappedPoint = null;
                    _tappedGeocode = null;
                  });
                  _mapController.move(LatLng(r.lat, r.lon), 15);
                }
              },
            ),
          ),
          // Carte
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _tunisCenter,
                initialZoom: 12,
                backgroundColor: Colors.grey.shade300,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.flingAnimation,
                ),
                onTap: (_, point) => _onMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'tn.ma3ak.app',
                ),
                if (_routeResult != null && _routeResult!.geometry.toLatLngList().length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeResult!.geometry.toLatLngList(),
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ..._searchResults.map((r) => Marker(
                          point: LatLng(r.lat, r.lon),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _onPlaceTap(r),
                            child: Icon(
                              _selectedPlace == r ? Icons.location_on : Icons.place,
                              color: _selectedPlace == r ? Theme.of(context).colorScheme.primary : Colors.green.shade700,
                              size: 44,
                            ),
                          ),
                        )),
                    if (_origin != null)
                      Marker(
                        point: _origin!,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.trip_origin, color: Colors.green, size: 36),
                      ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                      ),
                    if (_tappedPoint != null)
                      Marker(
                        point: _tappedPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.place, color: Colors.orange, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          // Contrôles carte : zoom +, zoom -, Ma position (droite)
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          final z = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, z + 1);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 28),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade300),
                      InkWell(
                        onTap: () {
                          final z = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, (z - 1).clamp(2.0, 18.0));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.remove, color: Theme.of(context).colorScheme.primary, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _mapController.move(_tunisCenter, 14),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bouton "Calculer l'itinéraire" quand départ et destination sont choisis
          if (_origin != null && _destination != null && _routeResult == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: InkWell(
                    onTap: _routeLoading ? null : _calculateRouteBetweenOriginAndDestination,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_routeLoading)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.route, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            strings.calculateRoute,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  ],
      ),
      bottomSheet: showCustomSheet
          ? _buildBottomSheet(strings)
          : _DriversNearbySheet(
              strings: strings,
              driversAsync: ref.watch(driversNearbyProvider),
              onReserve: (vehicleId) {
                if (vehicleId != null && vehicleId.isNotEmpty) {
                  context.push('/vehicle-reservations/new?vehicleId=$vehicleId');
                } else {
                  context.push('/vehicle-reservations/new');
                }
              },
              onFilters: () {},
            ),
    );
  }

  Widget _buildBottomSheet(AppStrings strings) {
    if (_showRouteSheet && _routeResult != null) {
      return _RouteBottomSheet(
        routeResult: _routeResult!,
        destinationName: _destinationName ?? _selectedPlace?.displayName ?? '',
        onReserveVehicle: () => context.push('/vehicle-reservations/new'),
        onClose: () => setState(() {
          _showRouteSheet = false;
          _routeResult = null;
          _origin = null;
          _destination = null;
          _originName = null;
          _destinationName = null;
        }),
        strings: strings,
      );
    }
    if (_tappedPoint != null) {
      return _TappedPointSheet(
        point: _tappedPoint!,
        geocode: _tappedGeocode,
        loading: _tappedLoading,
        onUseAsOrigin: _useTappedAsOrigin,
        onUseAsDestination: _useTappedAsDestination,
        onClose: () => setState(() { _tappedPoint = null; _tappedGeocode = null; }),
        strings: strings,
      );
    }
    if (_selectedPlace != null) {
      return _PlaceBottomSheet(
        place: _selectedPlace!,
        onBookAssistance: () => context.push('/vehicle-reservations/new'),
        onDirections: _routeLoading ? null : _calculateRouteToSelected,
        routeLoading: _routeLoading,
        onClose: () => setState(() => _selectedPlace = null),
        strings: strings,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Bottom sheet fixe : Chauffeurs à proximité, cartes chauffeur (sélectionnable), Réserver maintenant.
class _DriversNearbySheet extends StatefulWidget {
  const _DriversNearbySheet({
    required this.strings,
    required this.driversAsync,
    required this.onReserve,
    required this.onFilters,
  });

  final AppStrings strings;
  final AsyncValue<List<DriverNearby>> driversAsync;
  final void Function(String? vehicleId) onReserve;
  final VoidCallback onFilters;

  @override
  State<_DriversNearbySheet> createState() => _DriversNearbySheetState();
}

class _DriversNearbySheetState extends State<_DriversNearbySheet> {
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final driversAsync = widget.driversAsync;
    final onReserve = widget.onReserve;
    final onFilters = widget.onFilters;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onVerticalDragUpdate: (_) {},
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      strings.driversNearby,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onFilters,
                      child: Text(
                        strings.filters,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                driversAsync.when(
                  data: (drivers) {
                    if (drivers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            strings.noDriverAvailable,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...drivers.take(5).map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DriverCard(
                              driver: d,
                              strings: strings,
                              isSelected: _selectedVehicleId == d.vehicleId,
                              onTap: () => setState(() => _selectedVehicleId = d.vehicleId),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Boutons accessibilité : Rampe, Assistance, Chien Guide
                Row(
                  children: [
                    Expanded(
                      child: _AccessibilityChip(
                        label: strings.ramp,
                        icon: Icons.accessible,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AccessibilityChip(
                        label: strings.assistance,
                        icon: Icons.back_hand,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AccessibilityChip(
                        label: strings.guideDog,
                        icon: Icons.pets,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final drivers = driversAsync.valueOrNull ?? [];
                      final vehicleId = _selectedVehicleId ?? (drivers.isNotEmpty ? drivers.first.vehicleId : null);
                      onReserve(vehicleId);
                    },
                    icon: const Icon(Icons.electric_car, size: 22),
                    label: Text(
                      strings.bookNow,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.strings,
    this.isSelected = false,
    this.onTap,
  });

  final DriverNearby driver;
  final AppStrings strings;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fareText = driver.fare != null && driver.fare!.isNotEmpty
        ? 'DT ${driver.fare}'
        : '—';
    final waitText = driver.waitMinutes != null
        ? '${driver.waitMinutes} ${strings.minWait}'
        : '—';
    final ratingDisplay = driver.rating > 0
        ? driver.rating.toStringAsFixed(1)
        : '—';

    final content = Row(
      children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: driver.photoUrl != null && driver.photoUrl!.isNotEmpty
                ? NetworkImage(driver.photoUrl!)
                : null,
            child: driver.photoUrl == null || driver.photoUrl!.isEmpty
                ? Icon(Icons.person, size: 32, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.vehicleName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      ratingDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fareText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                waitText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 24),
              ],
            ],
          ),
        ],
      );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _AccessibilityChip extends StatelessWidget {
  const _AccessibilityChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceBottomSheet extends StatelessWidget {
  const _PlaceBottomSheet({
    required this.place,
    required this.onBookAssistance,
    this.onDirections,
    required this.routeLoading,
    required this.onClose,
    required this.strings,
  });

  final GeocodeResult place;
  final VoidCallback onBookAssistance;
  final VoidCallback? onDirections;
  final bool routeLoading;
  final VoidCallback onClose;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final city = place.address?['city'] ?? place.address?['town'] ?? 'Tunis';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onVerticalDragUpdate: (_) {},
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.placeOfInterest.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      style: IconButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  place.displayName.length > 50 ? '${place.displayName.substring(0, 50)}...' : place.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('$city, à 1.2 km', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(strings.verified, style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.accessible,
                        label: strings.wheelchairAccess,
                        subtitle: '★★★☆☆',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.menu_book,
                        label: strings.brailleMenus,
                        badge: strings.available,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onBookAssistance,
                        icon: const Icon(Icons.person, size: 20),
                        label: Text(strings.bookAssistance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: routeLoading ? null : onDirections,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: routeLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.directions),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.icon, required this.label, this.subtitle, this.badge});

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!, style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _TappedPointSheet extends StatelessWidget {
  const _TappedPointSheet({
    required this.point,
    required this.geocode,
    required this.loading,
    required this.onUseAsOrigin,
    required this.onUseAsDestination,
    required this.onClose,
    required this.strings,
  });

  final LatLng point;
  final GeocodeResult? geocode;
  final bool loading;
  final VoidCallback onUseAsOrigin;
  final VoidCallback onUseAsDestination;
  final VoidCallback onClose;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Adresse en cours...'),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              geocode?.displayName ?? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onUseAsOrigin,
                              icon: const Icon(Icons.trip_origin, size: 20),
                              label: Text(strings.departurePlace),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onUseAsDestination,
                              icon: const Icon(Icons.location_on, size: 20),
                              label: Text(strings.destinationPlace),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RouteBottomSheet extends StatelessWidget {
  const _RouteBottomSheet({
    required this.routeResult,
    required this.destinationName,
    required this.onReserveVehicle,
    required this.onClose,
    required this.strings,
  });

  final RouteResult routeResult;
  final String destinationName;
  final VoidCallback onReserveVehicle;
  final VoidCallback onClose;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.calculateRoute,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                  ],
                ),
                if (destinationName.isNotEmpty)
                  Text(
                    destinationName.length > 45 ? '${destinationName.substring(0, 45)}...' : destinationName,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MiniCard(icon: Icons.straighten, label: strings.routeDistance, subtitle: routeResult.distanceFormatted),
                    const SizedBox(width: 12),
                    _MiniCard(icon: Icons.schedule, label: strings.routeDuration, subtitle: routeResult.durationFormatted),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onReserveVehicle,
                    icon: const Icon(Icons.directions_car, size: 22),
                    label: Text(strings.reserveVehicle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
