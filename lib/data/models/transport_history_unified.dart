import 'package:equatable/equatable.dart';

import 'transport_model.dart';
import 'vehicle_reservation.dart';

/// Une ligne d’historique unifié (`GET /transport/history`) ou fallback réservations.
class TransportHistoryRow extends Equatable {
  const TransportHistoryRow._({
    required this.sortKey,
    this.transport,
    this.reservation,
  }) : assert(transport != null || reservation != null);

  factory TransportHistoryRow.transport(TransportModel t) {
    final key = t.dateHeureArrivee ??
        t.dateHeure ??
        t.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return TransportHistoryRow._(sortKey: key, transport: t);
  }

  factory TransportHistoryRow.reservation(VehicleReservation r) {
    final parts = r.heure.split(':');
    var h = 0;
    var min = 0;
    if (parts.isNotEmpty) h = int.tryParse(parts[0]) ?? 0;
    if (parts.length > 1) min = int.tryParse(parts[1]) ?? 0;
    final key = DateTime(r.date.year, r.date.month, r.date.day, h, min);
    return TransportHistoryRow._(sortKey: key, reservation: r);
  }

  static TransportHistoryRow? tryParse(Map<String, dynamic> json) {
    if (json['transport'] is Map) {
      try {
        return TransportHistoryRow.transport(
          TransportModel.fromJson(Map<String, dynamic>.from(json['transport'] as Map)),
        );
      } catch (_) {}
    }
    if (json['vehicleReservation'] is Map) {
      try {
        return TransportHistoryRow.reservation(
          VehicleReservation.fromJson(Map<String, dynamic>.from(json['vehicleReservation'] as Map)),
        );
      } catch (_) {}
    }
    if (json['reservation'] is Map) {
      try {
        return TransportHistoryRow.reservation(
          VehicleReservation.fromJson(Map<String, dynamic>.from(json['reservation'] as Map)),
        );
      } catch (_) {}
    }
    if (json['typeTransport'] != null) {
      try {
        return TransportHistoryRow.transport(TransportModel.fromJson(json));
      } catch (_) {}
    }
    if (json['vehicleId'] != null && json['heure'] != null) {
      try {
        return TransportHistoryRow.reservation(VehicleReservation.fromJson(json));
      } catch (_) {}
    }
    return null;
  }

  final DateTime sortKey;
  final TransportModel? transport;
  final VehicleReservation? reservation;

  bool get isTransport => transport != null;

  bool get isCompleted {
    if (transport != null) return transport!.isTerminee;
    if (reservation != null) return reservation!.statut.toApiString() == 'TERMINEE';
    return false;
  }

  bool get isCancelled {
    if (transport != null) return transport!.isAnnulee;
    if (reservation != null) return reservation!.statut.toApiString() == 'ANNULEE';
    return false;
  }

  @override
  List<Object?> get props => [transport?.id, reservation?.id];
}

/// Page `GET /transport/history`.
class TransportHistoryPage extends Equatable {
  const TransportHistoryPage({
    required this.items,
    this.page = 1,
    this.limit = 20,
    this.total,
    this.note,
  });

  factory TransportHistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        json['results'] as List<dynamic>? ??
        [];
    final rows = <TransportHistoryRow>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        final row = TransportHistoryRow.tryParse(e);
        if (row != null) rows.add(row);
      } else if (e is Map) {
        final row = TransportHistoryRow.tryParse(Map<String, dynamic>.from(e));
        if (row != null) rows.add(row);
      }
    }
    rows.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return TransportHistoryPage(
      items: rows,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length.clamp(1, 100),
      total: (json['total'] as num?)?.toInt() ?? (json['totalCount'] as num?)?.toInt(),
      note: json['note']?.toString(),
    );
  }

  final List<TransportHistoryRow> items;
  final int page;
  final int limit;
  final int? total;
  final String? note;

  @override
  List<Object?> get props => [items.length, page, limit];
}
