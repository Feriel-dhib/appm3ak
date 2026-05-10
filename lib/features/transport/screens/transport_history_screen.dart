import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/transport_history_unified.dart';
import '../../../data/models/transport_model.dart';
import '../../../data/models/transport_request_model.dart';
import '../../../data/models/vehicle_reservation.dart';
import '../../../data/models/vehicle_reservation_statut.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/transport_history_provider.dart';
import '../../../providers/vehicle_reservation_providers.dart';

/// Historique des trajets — style maquette : header (avatar, recherche, titre), filtres Tous/Terminés/Annulés, sections Aujourd'hui/Hier, cartes compactes.
class TransportHistoryScreen extends ConsumerStatefulWidget {
  const TransportHistoryScreen({super.key});

  @override
  ConsumerState<TransportHistoryScreen> createState() => _TransportHistoryScreenState();
}

class _TransportHistoryScreenState extends ConsumerState<TransportHistoryScreen> {
  /// 0 = Tous, 1 = Terminés, 2 = Annulés
  int _filterIndex = 0;

  static List<TransportHistoryRow> _applyRowFilter(
    List<TransportHistoryRow> list,
    int filterIndex,
  ) {
    if (filterIndex == 0) return list;
    if (filterIndex == 1) {
      return list.where((r) => r.isCompleted).toList();
    }
    return list.where((r) => r.isCancelled).toList();
  }

  /// Groupe par jour (clé de tri = [TransportHistoryRow.sortKey]).
  static Map<String, List<TransportHistoryRow>> _groupRowsByDay(
    List<TransportHistoryRow> list,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<TransportHistoryRow>>{};
    for (final r in list) {
      final d = DateTime(r.sortKey.year, r.sortKey.month, r.sortKey.day);
      String key;
      if (d == today) {
        key = 'today';
      } else if (d == yesterday) {
        key = 'yesterday';
      } else {
        key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      map.putIfAbsent(key, () => []).add(r);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    }
    return map;
  }

  static List<String> _orderedDayKeys(
    Map<String, List<TransportHistoryRow>> map,
    AppStrings strings,
  ) {
    final keys = map.keys.toList();
    keys.sort((a, b) {
      int order(String k) {
        if (k == 'today') return 0;
        if (k == 'yesterday') return 1;
        return 2; // older
      }
      final oa = order(a);
      final ob = order(b);
      if (oa != ob) return oa - ob;
      if (a.length >= 10 && b.length >= 10) return b.compareTo(a);
      return b.compareTo(a);
    });
    return keys;
  }

  static String _sectionTitle(String key, AppStrings strings) {
    if (key == 'today') return strings.sectionToday;
    if (key == 'yesterday') return strings.sectionYesterday;
    final parts = key.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final d = int.tryParse(parts[2]) ?? 0;
      return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);
    final historyAsync = ref.watch(tripHistoryUnifiedRowsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          strings.tripHistoryTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              // TODO: recherche
            },
          ),
          IconButton(
            icon: Icon(Icons.list_alt, color: theme.colorScheme.onSurface),
            tooltip: 'Mes demandes de transport',
            onPressed: () => context.push('/transport/my-requests'),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (list) {
          final filtered = _applyRowFilter(list, _filterIndex);
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.noTripHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final byDay = _groupRowsByDay(filtered);
          final orderedKeys = _orderedDayKeys(byDay, strings);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filtres : Tous | Terminés | Annulés
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: strings.filterCancelled,
                      icon: Icons.close,
                      selected: _filterIndex == 2,
                      onTap: () => setState(() => _filterIndex = 2),
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: strings.filterCompleted,
                      icon: Icons.check,
                      selected: _filterIndex == 1,
                      onTap: () => setState(() => _filterIndex = 1),
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: strings.filterAll,
                      icon: null,
                      selected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                      theme: theme,
                      primary: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tripHistoryUnifiedRowsProvider);
                    ref.invalidate(myVehicleReservationsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: orderedKeys.fold<int>(
                      0,
                      (sum, key) => sum + 1 + (byDay[key]?.length ?? 0),
                    ),
                    itemBuilder: (context, index) {
                      int offset = 0;
                      for (final key in orderedKeys) {
                        final rows = byDay[key]!;
                        if (index == offset) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 10),
                            child: Text(
                              _sectionTitle(key, strings),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }
                        offset++;
                        if (index < offset + rows.length) {
                          final row = rows[index - offset];
                          if (row.isTransport && row.transport != null) {
                            return _TransportTripCardCompact(
                              transport: row.transport!,
                              strings: strings,
                              theme: theme,
                              onTap: () => context.push('/transport/${row.transport!.id}'),
                            );
                          }
                          if (row.reservation != null) {
                            final r = row.reservation!;
                            return _TripHistoryCardCompact(
                              reservation: r,
                              strings: strings,
                              theme: theme,
                              onTap: () => context.push('/vehicle-reservations/${r.id}'),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        offset += rows.length;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                err.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tripHistoryUnifiedRowsProvider),
                child: Text(strings.continueBtn),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transport/request'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
    this.primary = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isPrimary = primary && selected;
    return Material(
      color: isPrimary
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isPrimary
                ? null
                : Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte compacte pour une course `TransportModel` (historique unifié).
class _TransportTripCardCompact extends StatelessWidget {
  const _TransportTripCardCompact({
    required this.transport,
    required this.strings,
    required this.theme,
    required this.onTap,
  });

  final TransportModel transport;
  final AppStrings strings;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = transport.isTerminee;
    final isCancelled = transport.isAnnulee;
    final destination = transport.destination?.isNotEmpty == true
        ? transport.destination!
        : strings.tripDetails;
    final dateStr = transport.dateHeure != null
        ? '${transport.dateHeure!.day}/${transport.dateHeure!.month} '
            '${transport.dateHeure!.hour.toString().padLeft(2, '0')}:'
            '${transport.dateHeure!.minute.toString().padLeft(2, '0')}'
        : '';
    final subtitle = transport.depart != null && transport.depart!.isNotEmpty
        ? '${transport.depart} • $dateStr'
        : dateStr;
    final statut = transport.statut ?? '';
    final tripIdShort = transport.id.length >= 4
        ? transport.id.substring(transport.id.length - 4).toUpperCase()
        : transport.id.toUpperCase();
    final badgeLabel = isCompleted
        ? strings.statusCompleted
        : isCancelled
            ? strings.statusCancelled
            : TransportRequestModel.labelForStatut(statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade600
                          : isCancelled
                              ? Colors.red.shade600
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted || isCancelled
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                destination,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.detailsLinkWithArrow,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    strings.tripNumberDisplay(tripIdShort),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte compacte : badge statut, destination, sous-titre (lieu • heure), icône véhicule, bas = Détails + note ou N° trajet.
class _TripHistoryCardCompact extends ConsumerWidget {
  const _TripHistoryCardCompact({
    required this.reservation,
    required this.strings,
    required this.theme,
    required this.onTap,
  });

  final VehicleReservation reservation;
  final AppStrings strings;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = reservation.statut == VehicleReservationStatut.terminee;
    final destination = reservation.lieuDestination?.isNotEmpty == true
        ? reservation.lieuDestination!
        : reservation.lieuDepart ?? strings.tripDetails;
    final subtitle = reservation.lieuDepart != null && reservation.lieuDepart!.isNotEmpty
        ? '${reservation.lieuDepart} • ${reservation.heure}'
        : reservation.heure;
    final tripIdShort = reservation.id.length >= 4
        ? reservation.id.substring(reservation.id.length - 4).toUpperCase()
        : reservation.id.toUpperCase();
    final reviewAsync = ref.watch(tripReviewProvider(reservation.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade600
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          Icon(Icons.check, size: 14, color: Colors.white),
                        if (isCompleted) const SizedBox(width: 4),
                        Text(
                          isCompleted
                              ? strings.statusCompleted
                              : strings.statusCancelled,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCompleted
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.accessible_forward,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                destination,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.detailsLinkWithArrow,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    reviewAsync.when(
                      data: (review) {
                        if (review != null && review.note > 0) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (review.note.toDouble()).toStringAsFixed(1),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          strings.tripNumberDisplay(tripIdShort),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => Text(
                        strings.tripNumberDisplay(tripIdShort),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Text(
                      strings.tripNumberDisplay(tripIdShort),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
