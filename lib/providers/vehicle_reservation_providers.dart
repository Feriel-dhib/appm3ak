import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/trip_review_model.dart';
import '../data/models/vehicle_reservation.dart';
import '../data/models/vehicle_reservation_statut.dart';
import 'api_providers.dart';

/// Mes réservations de véhicules (handicapé connecté).
final myVehicleReservationsProvider = FutureProvider<List<VehicleReservation>>(
  (ref) async {
    final repository = ref.watch(vehicleReservationRepositoryProvider);
    return repository.getMe();
  },
);

/// Historique des déplacements : réservations terminées ou annulées, tri par date décroissante.
final tripHistoryProvider = FutureProvider<List<VehicleReservation>>((ref) async {
  final list = await ref.watch(myVehicleReservationsProvider.future);
  final forHistory = list
      .where((r) =>
          r.statut == VehicleReservationStatut.terminee ||
          r.statut == VehicleReservationStatut.annulee)
      .toList();
  forHistory.sort((a, b) {
    final da = DateTime(a.date.year, a.date.month, a.date.day);
    final db = DateTime(b.date.year, b.date.month, b.date.day);
    final cmp = db.compareTo(da);
    if (cmp != 0) return cmp;
    return b.heure.compareTo(a.heure);
  });
  return forHistory;
});

/// Détail d'une réservation.
final vehicleReservationProvider =
    FutureProvider.family<VehicleReservation, String>((ref, id) async {
  final repository = ref.watch(vehicleReservationRepositoryProvider);
  return repository.findOne(id);
});

/// Évaluation d'une réservation (après trajet).
final tripReviewProvider =
    FutureProvider.family<TripReviewModel?, String>((ref, reservationId) async {
  final repository = ref.watch(vehicleReservationRepositoryProvider);
  return repository.getReview(reservationId);
});
