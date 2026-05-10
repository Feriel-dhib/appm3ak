import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/vehicle_edit_permissions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/models/vehicle_statut.dart';

/// Carte de véhicule adapté pour le catalogue transport (interface handicap).
class AdaptedVehicleCard extends ConsumerWidget {
  const AdaptedVehicleCard({
    super.key,
    required this.vehicle,
    this.pricePerDay,
    this.location,
    this.isAr = false,
    required this.onTap,
    this.user,
    this.onStatusUpdate,
  });

  final Vehicle vehicle;
  final String? pricePerDay;
  final String? location;
  final bool isAr;
  final VoidCallback? onTap;
  final UserModel? user;
  final Future<void> Function(VehicleStatut)? onStatusUpdate;

  static const Color _primaryBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = isAr ? AppStrings.ar() : AppStrings.fr();
    final theme = Theme.of(context);
    final isAvailable = vehicle.statut == VehicleStatut.valide;
    final price = pricePerDay ?? '— ${strings.pricePerDay}';
    final loc = location ?? strings.tunis;
    
    // Déterminer les permissions si un utilisateur est fourni
    VehicleEditPermissions? permissions;
    if (user != null) {
      permissions = VehicleEditPermissions.fromUserAndVehicle(user!, vehicle);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge de disponibilité et favori
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: vehicle.photos.isNotEmpty
                      ? Image.network(
                          vehicle.photos.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.directions_car,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.directions_car,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
                // Badge disponibilité en haut à gauche
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? strings.available : strings.soonAvailable,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // Icône favori en haut à droite
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: Ajouter aux favoris
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            // Nom et prix
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _extractPriceNumber(price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      ),
                      Text(
                        '/ jour',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lieu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    loc,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Tags d'accessibilité
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildFeatureTags(strings, theme),
              ),
            ),
            // Actions rapides pour Chauffeurs solidaires (véhicules EN_ATTENTE)
            if (permissions != null &&
                permissions.canOnlyEditStatus &&
                vehicle.statut == VehicleStatut.enAttente)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onStatusUpdate != null
                            ? () async {
                                await onStatusUpdate!(VehicleStatut.valide);
                              }
                            : null,
                        icon: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                        label: Text(
                          strings.validateVehicle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onStatusUpdate != null
                            ? () async {
                                await onStatusUpdate!(VehicleStatut.refuse);
                              }
                            : null,
                        icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                        label: Text(
                          strings.rejectVehicle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _extractPriceNumber(String price) {
    // Extrait le nombre du prix (ex: "45 TND/jr" -> "45", "120 DT" -> "120")
    final match = RegExp(r'(\d+)').firstMatch(price);
    return match?.group(1) ?? price;
  }

  List<Widget> _buildFeatureTags(AppStrings strings, ThemeData theme) {
    final tags = <Widget>[];
    final bgColor = const Color(0xFFE3F2FD);
    final iconColor = _primaryBlue;

    if (vehicle.accessibilite.rampeAcces) {
      tags.add(_buildTag(icon: Icons.accessible, label: strings.rampeAcces, bg: bgColor, iconColor: iconColor));
    }
    if (vehicle.accessibilite.coffreVaste) {
      tags.add(_buildTag(icon: Icons.luggage, label: strings.espaceFauteuilRoulant, bg: bgColor, iconColor: iconColor));
    }
    if (vehicle.accessibilite.siegePivotant) {
      tags.add(_buildTag(icon: Icons.chair, label: strings.siegePivotant, bg: bgColor, iconColor: iconColor));
    }
    if (vehicle.accessibilite.climatisation) {
      tags.add(_buildTag(icon: Icons.ac_unit, label: strings.climatisation, bg: bgColor, iconColor: iconColor));
    }
    if (vehicle.accessibilite.animalAccepte) {
      tags.add(_buildTag(icon: Icons.pets, label: strings.animalAccepte, bg: bgColor, iconColor: iconColor));
    }
    if (tags.length >= 2) {
      tags.add(_buildTag(icon: Icons.accessible_forward, label: strings.wheelchairsAndPlaces, bg: bgColor, iconColor: iconColor));
    }
    return tags.isEmpty
        ? [
            _buildTag(icon: Icons.directions_car, label: strings.rampeAcces, bg: bgColor, iconColor: iconColor),
          ]
        : tags;
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
