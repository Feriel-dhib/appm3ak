import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/transport_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Mes demandes de transport — UI type maquette : onglets Tout / En attente / Terminées, cartes avec statut, rôle, destination, départ, durée, "Voir détails >".
class TransportMyRequestsScreen extends ConsumerStatefulWidget {
  const TransportMyRequestsScreen({super.key});

  @override
  ConsumerState<TransportMyRequestsScreen> createState() =>
      _TransportMyRequestsScreenState();
}

class _TransportMyRequestsScreenState extends ConsumerState<TransportMyRequestsScreen> {
  List<TransportModel> _asDemandeur = [];
  List<TransportModel> _asAccompagnant = [];
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(transportRepositoryProvider);
      final map = await repo.getMe();
      if (mounted) {
        setState(() {
          _asDemandeur = map['asDemandeur'] ?? [];
          _asAccompagnant = map['asAccompagnant'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<TransportModel> _filteredList(AppStrings strings) {
    final all = <TransportModel>[];
    for (final t in _asDemandeur) {
      all.add(t);
    }
    for (final t in _asAccompagnant) {
      if (!_asDemandeur.any((x) => x.id == t.id)) all.add(t);
    }
    all.sort((a, b) {
      final da = a.dateHeure ?? a.createdAt ?? DateTime(0);
      final db = b.dateHeure ?? b.createdAt ?? DateTime(0);
      return db.compareTo(da);
    });
    if (_tabIndex == 1) {
      return all.where((t) => t.statut == 'EN_ATTENTE').toList();
    }
    if (_tabIndex == 2) {
      return all.where((t) => t.statut == 'TERMINEE').toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final list = _filteredList(strings);

    ref.listen<int>(transportUiRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        _load();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          strings.myRequestsTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(strings, theme),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              child: Text(strings.save),
                            ),
                          ],
                        ),
                      )
                    : list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  strings.noRequestsYet,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final t = list[i];
                                final asDemandeur = _asDemandeur.any((x) => x.id == t.id);
                                return _RequestCard(
                                  transport: t,
                                  asDemandeur: asDemandeur,
                                  strings: strings,
                                  theme: theme,
                                  onTap: () => context.push('/transport/${t.id}'),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppStrings strings, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              _TabChip(
                theme: theme,
                label: strings.tabAll,
                selected: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0),
              ),
              _TabChip(
                theme: theme,
                label: strings.tabPending,
                selected: _tabIndex == 1,
                onTap: () => setState(() => _tabIndex = 1),
              ),
              _TabChip(
                theme: theme,
                label: strings.tabCompleted,
                selected: _tabIndex == 2,
                onTap: () => setState(() => _tabIndex = 2),
              ),
            ],
          ),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 2,
                  color: _tabIndex == i
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeData theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.transport,
    required this.asDemandeur,
    required this.strings,
    required this.theme,
    required this.onTap,
  });

  final TransportModel transport;
  final bool asDemandeur;
  final AppStrings strings;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statut = transport.statut ?? '';
    final isTerminee = transport.isTerminee;
    final isAnnulee = statut == 'ANNULEE';
    final isEnAttente = statut == 'EN_ATTENTE';

    Color statusColor;
    String statusLabel;
    if (isAnnulee) {
      statusColor = Colors.grey;
      statusLabel = 'ANNULÉE';
    } else if (isTerminee) {
      statusColor = Colors.green;
      statusLabel = 'TERMINÉE';
    } else if (isEnAttente) {
      statusColor = Colors.orange;
      statusLabel = 'EN ATTENTE';
    } else {
      statusColor = theme.colorScheme.primary;
      statusLabel = statut;
    }

    IconData destinationIcon;
    Color destinationIconColor;
    if (isAnnulee) {
      destinationIcon = Icons.cancel_outlined;
      destinationIconColor = Colors.grey;
    } else if (isTerminee) {
      destinationIcon = Icons.flag_outlined;
      destinationIconColor = Colors.grey;
    } else {
      destinationIcon = Icons.location_on;
      destinationIconColor = theme.colorScheme.primary;
    }

    final date = transport.dateHeure ?? transport.createdAt;
    final dateStr = date != null ? strings.formatRequestListDate(date) : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      asDemandeur ? Icons.person_outline : Icons.people_outline,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      asDemandeur ? strings.requester : strings.companion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(destinationIcon, size: 20, color: destinationIconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transport.destination ?? transport.depart ?? '—',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '${strings.departurePrefix}${transport.depart ?? '—'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                if (isTerminee && transport.dureeMinutes != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          strings.durationLabel(transport.dureeMinutes!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    strings.viewDetailsLink,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
