import 'package:flutter/material.dart';

import '../../../../data/models/vehicle_statut.dart';

/// Badge affichant le statut d'un véhicule.
class VehicleStatutChip extends StatelessWidget {
  const VehicleStatutChip({
    super.key,
    required this.statut,
    this.isAr = false,
  });

  final VehicleStatut statut;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (statut) {
      case VehicleStatut.enAttente:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case VehicleStatut.valide:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case VehicleStatut.refuse:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statut.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
