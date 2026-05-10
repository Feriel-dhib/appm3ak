import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/vehicle_reservation_providers.dart';
import '../widgets/vehicle_reservation_card.dart';

/// Liste « Mes réservations de véhicules » (bénéficiaire ou accompagnant).
class VehicleReservationListScreen extends ConsumerWidget {
  const VehicleReservationListScreen({super.key});

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

    final reservationsAsync = ref.watch(myVehicleReservationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(strings.myVehicleReservations),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/transport/history'),
            icon: const Icon(Icons.history, size: 20),
            label: Text(strings.tripHistory),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/home?tab=2');
            },
            tooltip: strings.adaptedVehicles,
          ),
        ],
      ),
      body: reservationsAsync.when(
        data: (reservations) {
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.noReservations,
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
              ref.invalidate(myVehicleReservationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return VehicleReservationCard(
                  reservation: reservation,
                  onTap: () {
                    context.push('/vehicle-reservations/${reservation.id}');
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
                  ref.invalidate(myVehicleReservationsProvider);
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
