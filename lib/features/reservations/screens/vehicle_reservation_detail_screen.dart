import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/trip_review_model.dart';
import '../../../data/models/vehicle_reservation.dart';
import '../../../data/models/vehicle_reservation_statut.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/vehicle_reservation_providers.dart';
import '../widgets/vehicle_reservation_statut_chip.dart';

/// Détail d'une réservation de véhicule — style maquette (trajet, chauffeur, évaluation du service).
class VehicleReservationDetailScreen extends ConsumerWidget {
  const VehicleReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  final String reservationId;

  Future<void> _cancelReservation(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.cancelReservation),
        content: Text(strings.confirmCancelReservation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.ignore),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(strings.cancelReservation),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(vehicleReservationRepositoryProvider);
      await repo.delete(reservationId);

      if (context.mounted) {
        ref.invalidate(myVehicleReservationsProvider);
        ref.invalidate(vehicleReservationProvider(reservationId));
        ref.read(transportUiRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.reservationCancelled)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);

    final reservationAsync = ref.watch(vehicleReservationProvider(reservationId));
    final reviewAsync = ref.watch(tripReviewProvider(reservationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reservationDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vehicle-reservations');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: partager le trajet
            },
          ),
        ],
      ),
      body: reservationAsync.when(
        data: (r) {
          final canCancel = r.statut == VehicleReservationStatut.enAttente ||
              r.statut == VehicleReservationStatut.confirmee;
          final isCompleted = r.statut == VehicleReservationStatut.terminee;
          final driverName = r.vehicle?.owner?.displayName ?? strings.driver;
          final tripIdShort = r.id.length >= 4 ? r.id.substring(r.id.length - 4) : r.id;
          final driverPhotoUrl = r.vehicle?.owner != null
              ? UserRepository.photoUrl(r.vehicle!.owner!.photoProfil)
              : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleReservationStatutChip(statut: r.statut),
                if (r.transportId != null && r.transportId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(strings.tripFromVehicleReservationBadge),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/transport/${r.transportId}'),
                        icon: const Icon(Icons.directions_car_outlined, size: 18),
                        label: Text(strings.openLinkedTransportTrip),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Trajet #XXXX • date • heure
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.tripIdLabel} #$tripIdShort',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${strings.formatTripDateShort(r.date.day, r.date.month)} • ${r.heure}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Optionnel : prix / mode de paiement si dispo plus tard
                  ],
                ),
                // Timeline Départ / Arrivée
                if (r.lieuDepart != null || r.lieuDestination != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.trip_origin, size: 22, color: theme.colorScheme.primary),
                          Container(
                            width: 2,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Icon(Icons.location_on, size: 22, color: theme.colorScheme.error),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.lieuDepart != null && r.lieuDepart!.isNotEmpty) ...[
                              Text(
                                strings.labelDeparture,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.lieuDepart!,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (r.lieuDestination != null &&
                                r.lieuDestination!.isNotEmpty) ...[
                              Text(
                                strings.labelArrival,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.lieuDestination!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                // Carte Chauffeur & Véhicule
                if (r.vehicle != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: driverPhotoUrl.isNotEmpty
                                  ? NetworkImage(driverPhotoUrl)
                                  : null,
                              child: driverPhotoUrl.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  size: 14,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.vehicle!.owner?.displayName ?? strings.driver,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.vehicle!.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (r.vehicle!.owner?.telephone != null ||
                            r.vehicle!.owner?.email != null)
                          IconButton(
                            icon: Icon(
                              Icons.phone,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              // TODO: launch tel or copy
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                // Section Évaluation du service (si trajet terminé)
                if (isCompleted) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.serviceEvaluationTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TripReviewSection(
                    reservationId: reservationId,
                    reservation: r,
                    driverName: driverName,
                    reviewAsync: reviewAsync,
                    strings: strings,
                    theme: theme,
                    ref: ref,
                  ),
                ],
                if (r.besoinsSpecifiques != null &&
                    r.besoinsSpecifiques!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    strings.specificNeeds,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.besoinsSpecifiques!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
                if (r.qrCode != null && r.qrCode!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'QR Code',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            r.qrCode!,
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.qr_code,
                              size: 160,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelReservation(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(strings.cancelReservation),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
                  ref.invalidate(vehicleReservationProvider(reservationId));
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

class _TripReviewSection extends StatelessWidget {
  const _TripReviewSection({
    required this.reservationId,
    required this.reservation,
    required this.driverName,
    required this.reviewAsync,
    required this.strings,
    required this.theme,
    required this.ref,
  });

  final String reservationId;
  final VehicleReservation reservation;
  final String driverName;
  final AsyncValue<TripReviewModel?> reviewAsync;
  final AppStrings strings;
  final ThemeData theme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return reviewAsync.when(
      data: (review) {
        if (review != null) {
          return _AlreadyEvaluatedCard(
            review: review,
            strings: strings,
            theme: theme,
          );
        }
        // Invitation à évaluer
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                strings.serviceEvaluationPrompt(driverName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEvaluateDialog(context),
                icon: const Icon(Icons.star, size: 22),
                label: Text(strings.evaluateTrip),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _openEvaluateDialog(BuildContext context) {
    final repo = ref.read(vehicleReservationRepositoryProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => _EvaluateTripDialog(
        reservationId: reservationId,
        vehicleId: reservation.vehicle?.id,
        driverId: reservation.vehicle?.ownerId,
        strings: strings,
        theme: theme,
        onSubmit: (note, comment) async {
          await repo.submitReview(
            reservationId: reservationId,
            note: note,
            comment: comment.isNotEmpty ? comment : null,
            vehicleId: reservation.vehicle?.id,
            driverId: reservation.vehicle?.ownerId,
          );
          if (ctx.mounted) {
            ref.invalidate(tripReviewProvider(reservationId));
            ref.invalidate(vehicleReservationProvider(reservationId));
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.reviewSent)),
            );
          }
        },
      ),
    );
  }
}

/// Carte en lecture seule : l'utilisateur a déjà évalué (titre, SOUMIS, étoiles, libellé, commentaire, footer).
class _AlreadyEvaluatedCard extends StatelessWidget {
  const _AlreadyEvaluatedCard({
    required this.review,
    required this.strings,
    required this.theme,
  });

  final TripReviewModel review;
  final AppStrings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ratingText = strings.ratingLabel(review.note);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.yourReview,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  strings.reviewSubmittedTag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.note ? Icons.star : Icons.star_border,
                color: Colors.amber.shade700,
                size: 32,
              ),
            ),
          ),
          if (ratingText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ratingText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              strings.optionalComment,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                review.comment!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                strings.mobilityInclusiveFooter,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvaluateTripDialog extends StatefulWidget {
  const _EvaluateTripDialog({
    required this.reservationId,
    required this.vehicleId,
    required this.driverId,
    required this.strings,
    required this.theme,
    required this.onSubmit,
  });

  final String reservationId;
  final String? vehicleId;
  final String? driverId;
  final AppStrings strings;
  final ThemeData theme;
  final Future<void> Function(int note, String comment) onSubmit;

  @override
  State<_EvaluateTripDialog> createState() => _EvaluateTripDialogState();
}

class _EvaluateTripDialogState extends State<_EvaluateTripDialog> {
  int _note = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_note < 1 || _note > 5) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(_note, _commentController.text.trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = widget.theme;

    return AlertDialog(
      title: Text(
        strings.evaluateTrip,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.evaluationSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    _note >= star ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade700,
                    size: 40,
                  ),
                  onPressed: _isLoading ? null : () => setState(() => _note = star),
                );
              }),
            ),
            if (strings.ratingLabel(_note).isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  strings.ratingLabel(_note),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              strings.optionalComment,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: strings.commentPlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_note >= 1 && _note <= 5 && !_isLoading) ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(strings.submitReview),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  strings.cancelLabel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  strings.mobilityInclusiveFooter,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
