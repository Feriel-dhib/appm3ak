import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/vehicle.dart';
import '../../../../data/models/vehicle_statut.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../providers/vehicle_providers.dart';
import '../widgets/vehicle_card_v2.dart';

/// Type de filtre pour les véhicules.
enum VehicleFilter {
  all,
  favorites,
  inService,
}

/// Écran affichant les véhicules de l'utilisateur connecté avec design inspiré de la maquette.
class MyVehiclesScreen extends ConsumerStatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  ConsumerState<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends ConsumerState<MyVehiclesScreen> {
  VehicleFilter _selectedFilter = VehicleFilter.all;
  final Set<String> _favoriteVehicleIds = {}; // TODO: Persister dans SharedPreferences ou backend

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final isAr = strings.isAr;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final vehiclesAsync = ref.watch(myVehiclesProvider(user.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre et recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.myVehicles,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, color: primary),
                      onPressed: () {
                        // TODO: Implémenter la recherche
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Filtres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    context: context,
                    label: strings.all,
                    isSelected: _selectedFilter == VehicleFilter.all,
                    onTap: () => setState(() => _selectedFilter = VehicleFilter.all),
                    primary: primary,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context: context,
                    label: strings.favorites,
                    isSelected: _selectedFilter == VehicleFilter.favorites,
                    onTap: () => setState(() => _selectedFilter = VehicleFilter.favorites),
                    primary: primary,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context: context,
                    label: strings.inService,
                    isSelected: _selectedFilter == VehicleFilter.inService,
                    onTap: () => setState(() => _selectedFilter = VehicleFilter.inService),
                    primary: primary,
                  ),
                ],
              ),
            ),
            // Liste des véhicules
            Expanded(
              child: vehiclesAsync.when(
                data: (vehicles) {
                  // Filtrer selon le filtre sélectionné
                  final filteredVehicles = _filterVehicles(vehicles);

                  if (filteredVehicles.isEmpty) {
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
                      ref.invalidate(myVehiclesProvider(user.id));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        final isFavorite = _favoriteVehicleIds.contains(vehicle.id);
                        return VehicleCardV2(
                          vehicle: vehicle,
                          isFavorite: isFavorite,
                          isAr: isAr,
                          onTap: () {
                            context.push('/vehicles/${vehicle.id}');
                          },
                          onFavoriteTap: () {
                            setState(() {
                              if (isFavorite) {
                                _favoriteVehicleIds.remove(vehicle.id);
                              } else {
                                _favoriteVehicleIds.add(vehicle.id);
                              }
                            });
                            // TODO: Sauvegarder dans le backend ou SharedPreferences
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(myVehiclesProvider(user.id));
                        },
                        child: Text(strings.continueBtn),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/vehicles/new');
        },
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Vehicle> _filterVehicles(List<Vehicle> vehicles) {
    switch (_selectedFilter) {
      case VehicleFilter.all:
        return vehicles;
      case VehicleFilter.favorites:
        return vehicles
            .where((v) => _favoriteVehicleIds.contains(v.id))
            .toList();
      case VehicleFilter.inService:
        // Filtrer les véhicules avec statut VALIDE (en service)
        return vehicles
            .where((v) => v.statut == VehicleStatut.valide)
            .toList();
    }
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
