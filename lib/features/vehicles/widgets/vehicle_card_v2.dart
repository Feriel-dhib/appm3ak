import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/vehicle.dart';
import '../../../../data/models/vehicle_statut.dart';

/// Carte de véhicule inspirée de la maquette avec image, statut, favori et détails.
class VehicleCardV2 extends StatelessWidget {
  const VehicleCardV2({
    super.key,
    required this.vehicle,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.isAr = false,
  });

  final Vehicle vehicle;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isAr;

  /// Détermine le statut d'affichage (ACTIF ou MAINTENANCE) basé sur le statut backend.
  String get _displayStatus {
    switch (vehicle.statut) {
      case VehicleStatut.valide:
        return isAr ? AppStrings.ar().active : AppStrings.fr().active;
      case VehicleStatut.enAttente:
      case VehicleStatut.refuse:
        return isAr ? AppStrings.ar().maintenance : AppStrings.fr().maintenance;
    }
  }

  /// Couleur du statut.
  Color _getStatusColor(BuildContext context) {
    switch (vehicle.statut) {
      case VehicleStatut.valide:
        return Colors.green;
      case VehicleStatut.enAttente:
      case VehicleStatut.refuse:
        return Colors.orange;
    }
  }

  /// Date formatée pour l'affichage.
  String _getFormattedDate() {
    if (vehicle.updatedAt != null) {
      final date = vehicle.updatedAt!;
      final months = isAr
          ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
          : ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final strings = isAr ? AppStrings.ar() : AppStrings.fr();
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);
    final statusText = _displayStatus;
    final dateText = _getFormattedDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du véhicule
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: vehicle.photos.isNotEmpty
                    ? Image.network(
                        vehicle.photos.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.directions_car,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.directions_car,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Informations du véhicule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et favori
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: onFavoriteTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Plaque
                    Text(
                      '${strings.plate}: ${vehicle.immatriculation}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Statut et date
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date
                    if (dateText.isNotEmpty)
                      Text(
                        vehicle.statut == VehicleStatut.valide
                            ? '${strings.lastMaintenance}: $dateText'
                            : '${strings.scheduledFor}: $dateText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Bouton Détails
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${strings.details} >',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
