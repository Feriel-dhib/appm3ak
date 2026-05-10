import 'package:flutter/material.dart';

import '../../../../data/models/vehicle_reservation.dart';
import 'vehicle_reservation_statut_chip.dart';

/// Carte affichant un résumé d'une réservation dans une liste.
class VehicleReservationCard extends StatelessWidget {
  const VehicleReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  final VehicleReservation reservation;
  final VoidCallback? onTap;

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleName = reservation.vehicle?.displayName ?? 'Véhicule';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vehicleName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  VehicleReservationStatutChip(statut: reservation.statut),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatDate(reservation.date)} • ${reservation.heure}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (reservation.lieuDepart != null &&
                  reservation.lieuDepart!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.trip_origin,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reservation.lieuDepart!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (reservation.lieuDestination != null &&
                  reservation.lieuDestination!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reservation.lieuDestination!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
