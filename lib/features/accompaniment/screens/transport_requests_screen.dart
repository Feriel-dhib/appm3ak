import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/transport_model.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/vehicle_providers.dart';

const Color _primaryBlue = Color(0xFF1976D2);

/// Valeur retournée quand l'utilisateur choisit "Sans véhicule" et confirme (pour distinguer de "annuler").
const String _kNoVehicleChoice = '__no_vehicle__';

/// Demandes de transport (accompagnants) — UI type maquette : cartes avec avatar, "Il y a X min", départ/destination, URGENCE, Accepter ; modal "Choisir le véhicule" avec radio et "Confirmer l'acceptation".
class TransportRequestsScreen extends ConsumerStatefulWidget {
  const TransportRequestsScreen({super.key});

  @override
  ConsumerState<TransportRequestsScreen> createState() =>
      _TransportRequestsScreenState();
}

class _TransportRequestsScreenState extends ConsumerState<TransportRequestsScreen> {
  List<TransportModel> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(transportRepositoryProvider);
      final list = await repo.getAvailable();
      if (mounted) setState(() => _requests = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _requests = [];
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _timeAgo(AppStrings strings, DateTime? date) {
    if (date == null) return '—';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return strings.timeAgoMinutes(diff.inMinutes.clamp(0, 59));
    if (diff.inHours < 24) return strings.timeAgoHours(diff.inHours);
    return '${diff.inDays} j';
  }

  String _shortName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '—';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].length > 10 ? '${parts[0].substring(0, 10)}.' : parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }

  Future<void> _accept(TransportModel t) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final preassignedVehicleId = t.vehicleId;
    if (preassignedVehicleId != null && preassignedVehicleId.isNotEmpty) {
      try {
        final repo = ref.read(transportRepositoryProvider);
        await repo.accept(
          t.id,
          vehicleId: preassignedVehicleId,
          scoreMatching: t.scoreMatching,
        );
        if (mounted) await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    List<Vehicle> vehicles = [];
    try {
      vehicles = await ref.read(myVehiclesProvider(user.id).future);
    } catch (_) {}

    String? selectedVehicleId;
    if (mounted) {
      final appStrings = AppStrings.fromPreferredLanguage(
        user.preferredLanguage?.name,
      );
      final result = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ChooseVehicleSheet(
          vehicles: vehicles,
          strings: appStrings,
        ),
      );
      if (result == null) return;
      if (result == _kNoVehicleChoice) {
        selectedVehicleId = null;
      } else {
        selectedVehicleId = result;
      }
    }
    if (!mounted) return;

    try {
      final repo = ref.read(transportRepositoryProvider);
      await repo.accept(
        t.id,
        vehicleId: selectedVehicleId,
        scoreMatching: t.scoreMatching,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    ref.listen<int>(transportUiRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        _load();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          strings.requestsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _isLoading
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
              : _requests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              strings.noAvailableRequestsChauffeurScopedMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _requests.length,
                        itemBuilder: (_, i) {
                          final t = _requests[i];
                          final demandeur = t.demandeur;
                          final photo = UserRepository.photoUrl(demandeur?.photoProfil);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                                        child: photo.isEmpty ? const Icon(Icons.person) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _shortName(demandeur?.displayName),
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.trip_origin, size: 14, color: _primaryBlue),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    t.depart ?? '—',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey.shade700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    t.destination ?? '—',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey.shade700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _timeAgo(strings, t.createdAt),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (t.typeTransport == TransportType.urgence) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                strings.urgencyBadge,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (t.isFromVehicleReservation) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                strings.tripFromVehicleReservationBadge,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onTertiaryContainer,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => context.push('/transport/${t.id}'),
                                        icon: const Icon(Icons.info_outline, size: 18),
                                        label: Text(strings.detailsLink),
                                      ),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed: () {},
                                            child: const Text('Ignorer'),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: _primaryBlue,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => _accept(t),
                                            child: Text(strings.accept),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ChooseVehicleSheet extends StatefulWidget {
  const _ChooseVehicleSheet({
    required this.vehicles,
    required this.strings,
  });

  final List<Vehicle> vehicles;
  final AppStrings strings;

  @override
  State<_ChooseVehicleSheet> createState() => _ChooseVehicleSheetState();
}

class _ChooseVehicleSheetState extends State<_ChooseVehicleSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = widget.strings;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appStrings.chooseVehicleForTrip,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appStrings.selectTransportForRide,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionTile(
                      value: null,
                      groupValue: _selectedId,
                      selected: _selectedId == null,
                      icon: Icons.directions_walk,
                      title: appStrings.noVehicleOption,
                      subtitle: appStrings.pedestrianAccompagnement,
                      onTap: () => setState(() => _selectedId = null),
                    ),
                    ...widget.vehicles.map((v) => _OptionTile(
                          value: v.id,
                          groupValue: _selectedId,
                          selected: _selectedId == v.id,
                          icon: Icons.directions_car,
                          title: v.displayName,
                          subtitle: v.immatriculation.isNotEmpty
                              ? '${v.immatriculation} · ${appStrings.verified}'
                              : appStrings.verified,
                          subtitleVerified: true,
                          onTap: () => setState(() => _selectedId = v.id),
                        )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(
                      _selectedId == null ? _kNoVehicleChoice : _selectedId,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: Text(appStrings.confirmAcceptance),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.value,
    required this.groupValue,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleVerified = false,
    required this.onTap,
  });

  final String? value;
  final String? groupValue;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool subtitleVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: selected ? _primaryBlue : Colors.grey.shade600),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleVerified ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String?>(
              value: value,
              groupValue: groupValue,
              onChanged: (_) => onTap(),
              activeColor: _primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
