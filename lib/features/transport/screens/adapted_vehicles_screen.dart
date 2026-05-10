import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/geolocation_utils.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/models/vehicle_statut.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../widgets/adapted_vehicle_card.dart';

/// Écran catalogue "Véhicules Adaptés" pour l'interface transport (handicap).
class AdaptedVehiclesScreen extends ConsumerStatefulWidget {
  const AdaptedVehiclesScreen({super.key});

  @override
  ConsumerState<AdaptedVehiclesScreen> createState() => _AdaptedVehiclesScreenState();
}

class _AdaptedVehiclesScreenState extends ConsumerState<AdaptedVehiclesScreen> {
  static const Color _primaryBlue = Color(0xFF1976D2);
  int _page = 1;
  String? _selectedChip; // null = Tous, 'Tunis', 'Sousse', 'Disponible'
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  VehiclesListParams? _cachedParams;
  /// Point de référence pour le filtre 10 km (bénéficiaire uniquement).
  double? _nearLat;
  double? _nearLon;
  bool _geoReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGeoForBeneficiary());
  }

  Future<void> _initGeoForBeneficiary() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !user.isBeneficiary) {
      if (mounted) setState(() => _geoReady = true);
      return;
    }
    double? lat;
    double? lon;
    try {
      final pos = await resolveUserPosition(
        timeLimit: const Duration(seconds: 12),
      );
      final adj = preferTunisiaProfileWhenGpsMismatch(
        gpsLat: pos.latitude,
        gpsLon: pos.longitude,
        profileLat: user.latitude,
        profileLon: user.longitude,
      );
      lat = adj.lat;
      lon = adj.lon;
    } on GeolocationError catch (_) {
      final fb = profileCoordinatesFallback(user.latitude, user.longitude);
      lat = fb?.lat;
      lon = fb?.lon;
    } catch (_) {
      final fb = profileCoordinatesFallback(user.latitude, user.longitude);
      lat = fb?.lat;
      lon = fb?.lon;
    }
    if (!mounted) return;
    setState(() {
      _nearLat = lat;
      _nearLon = lon;
      _geoReady = true;
      _cachedParams = null;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  VehiclesListParams _buildListParams() {
    final user = ref.read(authStateProvider).valueOrNull;
    final statutFilter = _selectedChip == 'Disponible' ? 'VALIDE' : null;
    final beneficiaryGeo = user?.isBeneficiary == true &&
        _geoReady &&
        _nearLat != null &&
        _nearLon != null;
    final params = VehiclesListParams(
      statut: statutFilter,
      page: _page,
      limit: 20,
      nearLatitude: beneficiaryGeo ? _nearLat : null,
      nearLongitude: beneficiaryGeo ? _nearLon : null,
      maxDistanceKm: beneficiaryGeo ? 10 : null,
    );
    if (_cachedParams == null || _cachedParams != params) {
      _cachedParams = params;
    }
    return _cachedParams!;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();
    final isAr = strings.isAr;
    final theme = Theme.of(context);

    if (user != null && user.isBeneficiary) {
      if (!_geoReady) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(strings.adaptedVehicles, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (_nearLat == null || _nearLon == null) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(strings.adaptedVehicles, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    strings.vehiclesListNeedLocation10km,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _geoReady = false;
                        _nearLat = null;
                        _nearLon = null;
                      });
                      _initGeoForBeneficiary();
                    },
                    child: Text(strings.continueBtn),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final listParams = _buildListParams();
    final vehiclesAsync = ref.watch(vehiclesListProvider(listParams));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          strings.adaptedVehicles,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: strings.calculateRoute,
            onPressed: () => context.push('/transport/map'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Ouvrir notifications
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: strings.searchVehicle,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) {
                    // Debounce pour éviter les rebuilds excessifs
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                      // TODO: Implémenter la recherche côté API si nécessaire
                      // Pour l'instant, la recherche est uniquement côté client
                    });
                  },
                ),
              ),
            ),
            // Chips de filtre
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildChip(strings.all, null),
                  const SizedBox(width: 8),
                  _buildChip(strings.tunis, 'Tunis'),
                  const SizedBox(width: 8),
                  _buildChip(strings.sousse, 'Sousse'),
                  const SizedBox(width: 8),
                  _buildChip(strings.available, 'Disponible'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Liste des véhicules
            Expanded(
              child: vehiclesAsync.when(
                data: (response) {
                  final vehicles = response.data;
                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            strings.noVehicles,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(vehiclesListProvider(listParams));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: vehicles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == vehicles.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _page++;
                                    _cachedParams = null; // Invalider le cache pour forcer la recréation
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryBlue,
                                  side: BorderSide(color: _primaryBlue.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(strings.seeMoreVehicles),
                              ),
                            ),
                          );
                        }
                        final vehicle = vehicles[index];
                        final location = _getLocationForChip(vehicle);
                        final currentUser = ref.read(authStateProvider).valueOrNull;
                        
                        // Fonction pour mettre à jour le statut
                        Future<void> updateStatus(VehicleStatut newStatut) async {
                          final userStrings = AppStrings.fromPreferredLanguage(currentUser?.preferredLanguage?.name);
                          
                          try {
                            final repository = ref.read(vehicleRepositoryProvider);
                            await repository.updateStatus(vehicle.id, newStatut);
                            
                            // Invalider les providers pour rafraîchir les données
                            ref.invalidate(vehiclesListProvider(listParams));
                            ref.invalidate(vehicleProvider(vehicle.id));
                            if (currentUser != null) {
                              ref.invalidate(myVehiclesProvider(currentUser.id));
                            }
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(userStrings.vehicleStatusUpdated),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                        
                        // Navigation : si bénéficiaire ou accompagnant, aller directement au formulaire de réservation
                        // Sinon, aller à l'écran de détail
                        return AdaptedVehicleCard(
                          vehicle: vehicle,
                          pricePerDay: '45 ${strings.pricePerDay}',
                          location: location,
                          isAr: isAr,
                          user: currentUser,
                          onStatusUpdate: updateStatus,
                          onTap: () {
                            // Pour les bénéficiaires et accompagnants, aller directement au formulaire de réservation
                            if (currentUser != null && (currentUser.isBeneficiary || currentUser.isCompanion)) {
                              context.push('/vehicle-reservations/new?vehicleId=${vehicle.id}');
                            } else {
                              // Pour les autres utilisateurs (admin, etc.), aller à l'écran de détail
                              context.push('/vehicles/${vehicle.id}');
                            }
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => _buildSkeletonLoader(theme),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          error.toString().contains('timeout') || error.toString().contains('Timeout')
                              ? 'Le chargement prend trop de temps. Vérifiez votre connexion.'
                              : error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(vehiclesListProvider(listParams));
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(strings.continueBtn),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Action FAB (ex: filtres avancés)
        },
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChip(String label, String? value) {
    final isSelected = _selectedChip == value;
    return InkWell(
      onTap: () {
        if (_selectedChip != value) {
          setState(() {
            _selectedChip = value;
            _page = 1; // Reset à la première page lors du changement de filtre
            _cachedParams = null; // Invalider le cache pour forcer la recréation
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryBlue : _primaryBlue,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _primaryBlue,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  String _getLocationForChip(Vehicle vehicle) {
    if (_selectedChip == 'Tunis') return 'Tunis, Ariana';
    if (_selectedChip == 'Sousse') return 'Sousse, Centre';
    return 'Tunis, Ariana';
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              // Contenu skeleton
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre skeleton
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Lieu skeleton
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tags skeleton
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
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
      },
    );
  }
}

