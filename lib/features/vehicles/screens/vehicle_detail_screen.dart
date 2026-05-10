import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/vehicle_edit_permissions.dart';
import '../../../../data/models/accessibilite.dart';
import '../../../../data/models/vehicle.dart';
import '../../../../data/models/vehicle_statut.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../providers/api_providers.dart';
import '../../../../providers/vehicle_providers.dart';
import '../widgets/accessibility_feature_card.dart';

/// Écran de détail d'un véhicule inspiré de la maquette.
class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  final String vehicleId;

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {

  Future<void> _updateVehicleStatus(Vehicle vehicle, VehicleStatut newStatut) async {
    try {
      final repository = ref.read(vehicleRepositoryProvider);
      await repository.updateStatus(vehicle.id, newStatut);
      
      if (mounted) {
        final user = ref.read(authStateProvider).valueOrNull;
        final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
        
        // Invalider le provider pour rafraîchir les données
        ref.invalidate(vehicleProvider(widget.vehicleId));
        ref.invalidate(vehiclesListProvider(VehiclesListParams()));
        if (user != null) {
          ref.invalidate(myVehiclesProvider(user.id));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.vehicleStatusUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showStatusChangeDialog(Vehicle vehicle) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    
    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    
    if (!mounted) return;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.changeStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vehicle.statut == VehicleStatut.enAttente) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(strings.validateVehicle),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.valide);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text(strings.rejectVehicle),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.refuse);
                },
              ),
            ] else if (vehicle.statut == VehicleStatut.valide) ...[
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: Text(strings.isAr ? 'في الانتظار' : 'En attente'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.enAttente);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text(strings.rejectVehicle),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.refuse);
                },
              ),
            ] else if (vehicle.statut == VehicleStatut.refuse) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(strings.validateVehicle),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.valide);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: Text(strings.isAr ? 'في الانتظار' : 'En attente'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateVehicleStatus(vehicle, VehicleStatut.enAttente);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.ignore),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final user = ref.read(authStateProvider).valueOrNull;
        final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
        return AlertDialog(
          title: Text(strings.deleteVehicle),
          content: Text(strings.confirmDeleteVehicle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.ignore),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(strings.deleteVehicle),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(vehicleRepositoryProvider);
      await repository.delete(widget.vehicleId);

      if (context.mounted) {
        final user = ref.read(authStateProvider).valueOrNull;
        final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
        
        if (user != null) {
          ref.invalidate(myVehiclesProvider(user.id));
        }
        ref.invalidate(vehiclesListProvider(VehiclesListParams()));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.vehicleDeleted),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Compte le nombre de services d'accessibilité activés.
  int _countAccessibilityServices(Accessibilite accessibilite) {
    int count = 0;
    if (accessibilite.coffreVaste) count++;
    if (accessibilite.rampeAcces) count++;
    if (accessibilite.siegePivotant) count++;
    if (accessibilite.climatisation) count++;
    if (accessibilite.animalAccepte) count++;
    return count;
  }

  /// Retourne le texte du statut pour le badge.
  String _getStatusText(VehicleStatut statut, bool isAr) {
    final strings = isAr ? AppStrings.ar() : AppStrings.fr();
    switch (statut) {
      case VehicleStatut.enAttente:
        return strings.isAr ? 'في الانتظار' : 'En attente';
      case VehicleStatut.valide:
        return strings.active;
      case VehicleStatut.refuse:
        return strings.maintenance;
    }
  }

  /// Couleur du badge de statut.
  Color _getStatusBadgeColor(VehicleStatut statut) {
    switch (statut) {
      case VehicleStatut.enAttente:
        return Colors.orange.shade100;
      case VehicleStatut.valide:
        return Colors.green.shade100;
      case VehicleStatut.refuse:
        return Colors.red.shade100;
    }
  }

  /// Couleur du point du badge de statut.
  Color _getStatusDotColor(VehicleStatut statut) {
    switch (statut) {
      case VehicleStatut.enAttente:
        return Colors.orange;
      case VehicleStatut.valide:
        return Colors.green;
      case VehicleStatut.refuse:
        return Colors.red;
    }
  }

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

    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text(strings.vehicleDetailsTitle),
        actions: vehicleAsync.whenData((vehicle) {
          final permissions = VehicleEditPermissions.fromUserAndVehicle(user, vehicle);
          
          // Pour les Chauffeurs solidaires, afficher uniquement le bouton de changement de statut
          if (permissions.canOnlyEditStatus) {
            return <Widget>[
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                tooltip: strings.changeStatus,
                onPressed: () => _showStatusChangeDialog(vehicle),
              ),
            ];
          }
          // Pour les propriétaires et admins, afficher les boutons d'édition et suppression
          else if (permissions.canEditAll) {
            return <Widget>[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  context.push('/vehicles/${widget.vehicleId}/edit');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteVehicle(context, ref),
              ),
            ];
          }
          // Aucun bouton pour les autres utilisateurs
          return <Widget>[];
        }).valueOrNull ?? <Widget>[],
      ),
      body: vehicleAsync.when(
        data: (vehicle) {
          final servicesCount = _countAccessibilityServices(vehicle.accessibilite);
          final statusText = _getStatusText(vehicle.statut, isAr);
          final statusBadgeColor = _getStatusBadgeColor(vehicle.statut);
          final statusDotColor = _getStatusDotColor(vehicle.statut);
          final permissions = VehicleEditPermissions.fromUserAndVehicle(user, vehicle);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du véhicule avec badge de statut
                Stack(
                  children: [
                    // Image principale
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: vehicle.photos.isNotEmpty
                          ? Image.network(
                              vehicle.photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 80,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.directions_car,
                                size: 80,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    // Badge de statut qui chevauche l'image
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBadgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusDotColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Carte d'informations principales
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Marque & Modèle avec icône
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.marqueAndModele.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.displayName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Immatriculation et Capacité
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.immatriculation.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.immatriculation,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.capacity,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '5 ${strings.capacityPlaces}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Section Accessibilité
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.accessibilite,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$servicesCount ${strings.servicesIncluded}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Grille de cartes d'accessibilité
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      if (vehicle.accessibilite.coffreVaste)
                        AccessibilityFeatureCard(
                          icon: Icons.luggage,
                          iconColor: Colors.blue,
                          title: strings.coffreVaste,
                          subtitle: strings.spacious,
                        ),
                      if (vehicle.accessibilite.rampeAcces)
                        AccessibilityFeatureCard(
                          icon: Icons.accessible,
                          iconColor: Colors.green,
                          title: strings.rampeAcces,
                          subtitle: strings.pmrOptimized,
                        ),
                      if (vehicle.accessibilite.siegePivotant)
                        AccessibilityFeatureCard(
                          icon: Icons.chair,
                          iconColor: Colors.purple,
                          title: strings.siegePivotant,
                          subtitle: strings.comfortable,
                        ),
                      if (vehicle.accessibilite.climatisation)
                        AccessibilityFeatureCard(
                          icon: Icons.ac_unit,
                          iconColor: Colors.lightBlue,
                          title: strings.climatisation,
                          subtitle: strings.dualZone,
                        ),
                      if (vehicle.accessibilite.animalAccepte)
                        AccessibilityFeatureCard(
                          icon: Icons.pets,
                          iconColor: Colors.orange,
                          title: strings.animalAccepte,
                          subtitle: strings.assistanceDogsWelcome,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions pour Chauffeurs solidaires (changement de statut uniquement)
                // Afficher si l'utilisateur est un Chauffeur solidaire OU si les permissions le permettent
                if (user.isChauffeurSolidaire || permissions.canOnlyEditStatus)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.admin_panel_settings, color: Colors.blue.shade700, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.vehicleStatus,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Statut actuel: $statusText',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (vehicle.statut == VehicleStatut.enAttente) ...[
                            // Pour les véhicules EN_ATTENTE, afficher Valider et Refuser
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateVehicleStatus(vehicle, VehicleStatut.valide),
                                    icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    label: Text(
                                      strings.validateVehicle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateVehicleStatus(vehicle, VehicleStatut.refuse),
                                    icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                                    label: Text(
                                      strings.rejectVehicle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Pour les autres statuts, afficher un bouton pour ouvrir le dialogue
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showStatusChangeDialog(vehicle),
                                icon: Icon(Icons.edit, color: primary, size: 20),
                                label: Text(
                                  strings.changeStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: primary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primary,
                                  side: BorderSide(color: primary),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                // Bouton Réserver (bénéficiaire OU accompagnant, véhicule VALIDE uniquement)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: (user.isBeneficiary || user.isCompanion) && vehicle.statut == VehicleStatut.valide
                        ? ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                '/vehicle-reservations/new?vehicleId=${vehicle.id}',
                              );
                            },
                            icon: const Icon(Icons.calendar_today, color: Colors.white),
                            label: Text(
                              strings.bookVehicle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : (user.isBeneficiary || user.isCompanion) && vehicle.statut != VehicleStatut.valide
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  strings.vehicleNotAvailableForDate,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.calendar_today, color: Colors.white),
                                label: Text(
                                  strings.checkAvailabilities,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
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
                  ref.invalidate(vehicleProvider(widget.vehicleId));
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
