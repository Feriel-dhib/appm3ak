import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transport_history_unified.dart';
import '../data/models/vehicle_reservation_statut.dart';
import 'api_providers.dart';
import 'vehicle_reservation_providers.dart';

/// Historique unifié (`GET /transport/history`) ; en cas d’échec API, repli sur les réservations véhicule seules.
final tripHistoryUnifiedRowsProvider =
    FutureProvider.autoDispose<List<TransportHistoryRow>>((ref) async {
  try {
    final repo = ref.watch(transportRepositoryProvider);
    final page = await repo.getHistory(page: 1, limit: 100);
    return page.items;
  } catch (_) {
    final reservations = await ref.watch(myVehicleReservationsProvider.future);
    final forHistory = reservations
        .where(
          (r) =>
              r.statut == VehicleReservationStatut.terminee ||
              r.statut == VehicleReservationStatut.annulee,
        )
        .toList();
    forHistory.sort((a, b) {
      final da = DateTime(a.date.year, a.date.month, a.date.day);
      final db = DateTime(b.date.year, b.date.month, b.date.day);
      final cmp = db.compareTo(da);
      if (cmp != 0) return cmp;
      return b.heure.compareTo(a.heure);
    });
    return forHistory.map(TransportHistoryRow.reservation).toList();
  }
});
