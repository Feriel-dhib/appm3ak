import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/accessibilite.dart';

/// Formulaire pour les caractéristiques d'accessibilité d'un véhicule.
class AccessibiliteForm extends StatelessWidget {
  const AccessibiliteForm({
    super.key,
    required this.accessibilite,
    required this.onChanged,
    this.isAr = false,
  });

  final Accessibilite accessibilite;
  final ValueChanged<Accessibilite> onChanged;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final strings = isAr ? AppStrings.ar() : AppStrings.fr();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.accessibilite,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitch(
          context: context,
          label: strings.coffreVaste,
          value: accessibilite.coffreVaste,
          onChanged: (value) => onChanged(
            accessibilite.copyWith(coffreVaste: value),
          ),
        ),
        _buildSwitch(
          context: context,
          label: strings.rampeAcces,
          value: accessibilite.rampeAcces,
          onChanged: (value) => onChanged(
            accessibilite.copyWith(rampeAcces: value),
          ),
        ),
        _buildSwitch(
          context: context,
          label: strings.siegePivotant,
          value: accessibilite.siegePivotant,
          onChanged: (value) => onChanged(
            accessibilite.copyWith(siegePivotant: value),
          ),
        ),
        _buildSwitch(
          context: context,
          label: strings.climatisation,
          value: accessibilite.climatisation,
          onChanged: (value) => onChanged(
            accessibilite.copyWith(climatisation: value),
          ),
        ),
        _buildSwitch(
          context: context,
          label: strings.animalAccepte,
          value: accessibilite.animalAccepte,
          onChanged: (value) => onChanged(
            accessibilite.copyWith(animalAccepte: value),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
