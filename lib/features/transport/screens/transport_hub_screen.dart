import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/ma3ak_ui.dart';
import '../../../data/models/transport_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/transport_history_provider.dart';

/// Tableau de bord du **module transport** : accès rapide (demande, trajets,
/// détection d’obstacles, carte, historique, réservation véhicule), trajets
/// actifs et demandes disponibles (chauffeur solidaire). Tout le contenu de cet écran
/// relève du périmètre transport côté produit.
class TransportHubScreen extends ConsumerStatefulWidget {
  const TransportHubScreen({super.key});

  @override
  ConsumerState<TransportHubScreen> createState() => _TransportHubScreenState();
}

class _TransportHubScreenState extends ConsumerState<TransportHubScreen> {
  bool _loading = true;
  String? _error;
  List<TransportModel> _asDemandeur = [];
  List<TransportModel> _asAccompagnant = [];
  List<TransportModel> _availableRequests = [];

  bool _isBlindProfile(String? typeHandicap) {
    final raw = typeHandicap?.toLowerCase().trim() ?? '';
    return raw.contains('visuel') ||
        raw.contains('malvoy') ||
        raw.contains('blind') ||
        raw.contains('aveugle');
  }

  @override
  void initState() {
    super.initState();
    _loadHubData();
  }

  Future<void> _loadHubData() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(transportRepositoryProvider);
      final me = await repo.getMe();
      final available =
          user.isChauffeurSolidaire ? await repo.getAvailable() : <TransportModel>[];
      if (!mounted) return;
      setState(() {
        _asDemandeur = me['asDemandeur'] ?? [];
        _asAccompagnant = me['asAccompagnant'] ?? [];
        _availableRequests = available;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<TransportModel> _activeTrips(UserModel user) {
    final list = user.isBeneficiary ? _asDemandeur : _asAccompagnant;
    const active = {
      'EN_ATTENTE',
      'ACCEPTEE',
      'EN_ROUTE',
      'ARRIVEE',
      'EN_COURS',
    };
    return list.where((t) => active.contains(t.statut)).toList()
      ..sort((a, b) {
        final da = a.dateHeure ?? a.createdAt ?? DateTime(0);
        final db = b.dateHeure ?? b.createdAt ?? DateTime(0);
        return db.compareTo(da);
      });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final activeTrips = _activeTrips(user);
    final theme = Theme.of(context);

    ref.listen<int>(transportUiRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        ref.invalidate(tripHistoryUnifiedRowsProvider);
        _loadHubData();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.transportHubTitle),
        actions: [
          IconButton(
            tooltip: strings.save,
            onPressed: _loadHubData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHubData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _HeaderCard(
              title: strings.transportHubTitle,
              subtitle: strings.transportHubSubtitle,
            ),
            const SizedBox(height: 14),
            _SectionTitle(title: strings.quickActionsTitle),
            const SizedBox(height: 10),
            _ActionsGrid(actions: _buildQuickActions(context, user, strings)),
            const SizedBox(height: 16),
            _SectionTitle(title: strings.activeTripsTitle),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_error != null)
              _ErrorBlock(message: _error!, onRetry: _loadHubData, retryLabel: strings.save)
            else if (activeTrips.isEmpty)
              _EmptyBlock(
                icon: Icons.directions_bus_outlined,
                text: strings.noActiveTripsMessage,
              )
            else
              ...activeTrips.take(3).map(
                (trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TripCard(
                    strings: strings,
                    trip: trip,
                    onTap: () => context.push('/transport/${trip.id}'),
                  ),
                ),
              ),
            if (user.isChauffeurSolidaire) ...[
              const SizedBox(height: 8),
              _SectionTitle(title: strings.availableRequestsTitle),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_availableRequests.isEmpty)
                _EmptyBlock(
                  icon: Icons.inbox_outlined,
                  text: strings.noAvailableRequestsChauffeurScopedMessage,
                )
              else
                ..._availableRequests.take(3).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TripCard(
                      strings: strings,
                      trip: t,
                      showUrgency: true,
                      onTap: () => context.push('/beneficiaires'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<_ActionItem> _buildQuickActions(
    BuildContext context,
    UserModel user,
    AppStrings strings,
  ) {
    final chauffeur = user.isChauffeurSolidaire;
    final canUseObstacleAssist =
        user.isBeneficiary && _isBlindProfile(user.typeHandicap);
    final actions = <_ActionItem>[
      if (user.isBeneficiary)
        _ActionItem(
          icon: Icons.add_rounded,
          label: strings.requestTransportShort,
          onTap: () => context.push('/transport/request'),
        ),
      _ActionItem(
        icon: Icons.list_alt_outlined,
        label: strings.myTripsLabel,
        onTap: () => context.push('/transport/my-requests'),
      ),
      if (!chauffeur && canUseObstacleAssist) ...[
        _ActionItem(
          icon: Icons.remove_red_eye_outlined,
          label: strings.obstacleDetection,
          onTap: () => context.push('/transport/obstacle-detection'),
        ),
        _ActionItem(
          icon: Icons.explore_outlined,
          label: strings.guidedObstacleNavShort,
          onTap: () => context.push('/transport/obstacle-navigation-hub'),
        ),
      ],
      if (chauffeur)
        _ActionItem(
          icon: Icons.assignment_outlined,
          label: strings.requestsTitle,
          onTap: () => context.push('/beneficiaires'),
        ),
      _ActionItem(
        icon: Icons.map_outlined,
        label: strings.liveMapLabel,
        onTap: () => context.push('/transport/dynamic'),
      ),
      _ActionItem(
        icon: Icons.history,
        label: strings.tripHistoryTitle,
        onTap: () => context.push('/transport/history'),
      ),
      if (!chauffeur)
        _ActionItem(
          icon: Icons.local_taxi_outlined,
          label: strings.bookVehicle,
          onTap: () => context.push('/transport/dynamic'),
        ),
      if (chauffeur) ...[
        _ActionItem(
          icon: Icons.directions_car_outlined,
          label: strings.myVehicles,
          onTap: () => context.push('/vehicles'),
        ),
        _ActionItem(
          icon: Icons.calendar_today_outlined,
          label: strings.myVehicleReservations,
          onTap: () => context.push('/vehicle-reservations'),
        ),
      ],
    ];

    return actions;
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Ma3akUi.cardBackground(context),
        borderRadius: Ma3akUi.borderRadiusCard,
        border: Border.all(color: Ma3akUi.subtleBorder(context)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.directions_bus_rounded, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.actions});

  final List<_ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, i) {
        final action = actions[i];
        return Material(
          color: Ma3akUi.cardBackground(context),
          borderRadius: Ma3akUi.borderRadiusCard,
          elevation: 0,
          shadowColor: cs.primary.withValues(alpha: 0.12),
          child: InkWell(
            borderRadius: Ma3akUi.borderRadiusCard,
            onTap: action.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: Ma3akUi.borderRadiusCard,
                border: Border.all(color: Ma3akUi.subtleBorder(context)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(action.icon, size: 22, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.strings,
    required this.trip,
    required this.onTap,
    this.showUrgency = false,
  });

  final AppStrings strings;
  final TransportModel trip;
  final VoidCallback onTap;
  final bool showUrgency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = trip.statut ?? 'EN_ATTENTE';
    final statusColor = switch (status) {
      'EN_ATTENTE' => Colors.orange.shade700,
      'ACCEPTEE' => cs.primary,
      'TERMINEE' => Colors.green.shade700,
      _ => cs.onSurfaceVariant,
    };

    return Material(
      color: Ma3akUi.cardBackground(context),
      borderRadius: Ma3akUi.borderRadiusCard,
      child: InkWell(
        borderRadius: Ma3akUi.borderRadiusCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: Ma3akUi.borderRadiusCard,
            border: Border.all(color: Ma3akUi.subtleBorder(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.route_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.depart ?? '—'} → ${trip.destination ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.dateHeure != null
                          ? strings.formatRequestListDate(trip.dateHeure!)
                          : strings.tripIdLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showUrgency && trip.typeTransport == TransportType.urgence) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.urgencyBadge,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (showUrgency && trip.isFromVehicleReservation) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.tripFromVehicleReservationBadge,
                        style: TextStyle(
                          color: cs.onTertiaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Ma3akUi.cardBackground(context),
        borderRadius: Ma3akUi.borderRadiusCard,
        border: Border.all(color: Ma3akUi.subtleBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: cs.primary.withValues(alpha: 0.55)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: Ma3akUi.borderRadiusCard,
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.error, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
