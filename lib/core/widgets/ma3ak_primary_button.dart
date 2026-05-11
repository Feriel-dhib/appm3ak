import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// CTA principal unifié de Ma3ak — abstraction unique pour éviter le chaos
/// `ElevatedButton` (thème) / `FilledButton` (M3) / `AuthPrimaryGradientButton`
/// (custom) qui coexistaient.
///
/// Sous le capot : `FilledButton` (M3) déjà thémé via `AppTheme.filledButtonTheme`.
/// Expose une API simple, avec état `loading` intégré pour les actions async.
class Ma3akPrimaryButton extends StatelessWidget {
  const Ma3akPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
            ),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              );

    final button = FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pillBorder,
        ),
      ),
      child: child,
    );

    return Semantics(
      button: true,
      label: label,
      hint: semanticHint,
      enabled: !disabled,
      child: fullWidth ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// CTA secondaire (Outlined) avec la même ergonomie que [Ma3akPrimaryButton].
class Ma3akSecondaryButton extends StatelessWidget {
  const Ma3akSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pillBorder,
        ),
      ),
      child: child,
    );
    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
