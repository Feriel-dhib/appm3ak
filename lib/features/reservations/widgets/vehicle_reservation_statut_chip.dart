import 'package:flutter/material.dart';

import '../../../../data/models/vehicle_reservation_statut.dart';

/// Badge affichant le statut d'une réservation.
class VehicleReservationStatutChip extends StatelessWidget {
  const VehicleReservationStatutChip({
    super.key,
    required this.statut,
  });

  final VehicleReservationStatut statut;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (statut) {
      case VehicleReservationStatut.enAttente:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case VehicleReservationStatut.confirmee:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case VehicleReservationStatut.annulee:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      case VehicleReservationStatut.terminee:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statut == VehicleReservationStatut.terminee) ...[
            Icon(Icons.check_circle, size: 18, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            statut == VehicleReservationStatut.terminee
                ? 'TERMINÉE'
                : statut.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
