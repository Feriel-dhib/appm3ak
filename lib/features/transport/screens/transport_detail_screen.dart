import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/transport_model.dart';
import '../../../data/models/transport_review_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/transport_history_provider.dart';
import '../../../providers/vehicle_reservation_providers.dart';

/// Couleur primaire bleue (maquette Détails du trajet).
const Color _primaryBlue = Color(0xFF1976D2);

/// Détail d'une demande de transport — UI type maquette : AppBar bleue, carte statut+ETA, trajet (timeline), participants, bouton Terminer.
class TransportDetailScreen extends ConsumerStatefulWidget {
  const TransportDetailScreen({super.key, required this.transportId});

  final String transportId;

  @override
  ConsumerState<TransportDetailScreen> createState() =>
      _TransportDetailScreenState();
}

class _TransportDetailScreenState extends ConsumerState<TransportDetailScreen> {
  TransportModel? _transport;
  bool _loading = true;
  String? _error;
  TransportEtaResult? _eta;
  Timer? _etaTimer;
  List<TransportReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(transportRepositoryProvider);
      final t = await repo.findById(widget.transportId);
      List<TransportReviewModel> reviews = [];
      try {
        reviews = await repo.getReviewsForTransport(widget.transportId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _transport = t;
          _reviews = reviews;
          _loading = false;
        });
        if (t.isActiveTrip) {
          _startEtaPolling();
        } else {
          _etaTimer?.cancel();
        }
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

  void _startEtaPolling() {
    _etaTimer?.cancel();
    void poll() async {
      if (!mounted || _transport == null || !_transport!.isActiveTrip) return;
      try {
        final repo = ref.read(transportRepositoryProvider);
        final eta = await repo.getEta(widget.transportId);
        if (mounted && _transport != null && _transport!.isActiveTrip) {
          setState(() => _eta = eta);
        }
      } catch (_) {}
    }

    poll();
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
  }

  bool _canCancel(UserModel? user, TransportModel t) {
    if (user == null) return false;
    if (t.isTerminee || t.isAnnulee) return false;
    return t.isDemandeurUser(user) || t.isAssignedDriver(user);
  }

  bool _canShare(UserModel? user, TransportModel t) {
    if (user == null) return false;
    if (!t.isActiveTrip) return false;
    return t.isDemandeurUser(user) || t.isAssignedDriver(user);
  }

  Future<void> _shareTrip(AppStrings strings) async {
    final t = _transport;
    if (t == null) return;
    try {
      final res = await ref.read(transportRepositoryProvider).createShare(t.id);
      if (!mounted) return;
      final inAppPath =
          '/transport/${t.id}/suivi?token=${Uri.encodeQueryComponent(res.token)}';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.shareTripTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.shareTripHint),
                const SizedBox(height: 12),
                SelectableText(res.token, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (res.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${res.expiresAt!.toLocal()}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.cancelLabel),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: res.token));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.copiedToClipboard)),
                );
              },
              child: Text(strings.copyToken),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(inAppPath);
              },
              child: Text(strings.openGuestSuivi),
            ),
          ],
        ),
      );
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

  Future<void> _confirmCancel(AppStrings strings) async {
    final t = _transport;
    if (t == null) return;
    String? raison;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.cancelTripAction),
        content: TextField(
          decoration: InputDecoration(
            hintText: strings.cancelReasonOptionalHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (v) => raison = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(transportRepositoryProvider).cancel(
            t.id,
            raison: raison,
          );
      if (mounted) {
        ref.read(transportUiRefreshProvider.notifier).state++;
        final resId = t.vehicleReservationId;
        if (resId != null && resId.isNotEmpty) {
          ref.invalidate(vehicleReservationProvider(resId));
        }
        ref.invalidate(myVehicleReservationsProvider);
        ref.invalidate(tripHistoryUnifiedRowsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.statusCancelled)),
        );
        _etaTimer?.cancel();
        _load();
      }
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

  Future<void> _patchStatut(String statut, AppStrings strings) async {
    final t = _transport;
    if (t == null) return;
    try {
      await ref.read(transportRepositoryProvider).updateStatut(t.id, statut);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.save)),
        );
        _load();
      }
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

  Future<void> _openReviewDialog(UserModel user, AppStrings strings) async {
    final t = _transport;
    if (t == null || !t.isTerminee || !t.isDemandeurUser(user)) return;
    int note = 5;
    final commentCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.evaluateTrip),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.rating),
                    Slider(
                      value: note.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$note',
                      onChanged: (v) => setDialogState(() => note = v.round()),
                    ),
                    TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        labelText: strings.optionalComment,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(strings.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(strings.submitReview),
                ),
              ],
            );
          },
        ),
      );
      if (ok != true || !mounted) return;
      await ref.read(transportRepositoryProvider).createReview(
            t.id,
            note: note,
            commentaire: commentCtrl.text.trim().isEmpty
                ? null
                : commentCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.reviewSent)),
        );
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError && e.message == 'TRANSPORT_REVIEW_CONFLICT'
          ? strings.reviewAlreadyExistsError
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      commentCtrl.dispose();
    }
  }

  Future<void> _terminer() async {
    final t = _transport;
    if (t == null) return;
    final ctx = context;
    final strings = AppStrings.fromPreferredLanguage(
        ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name);
    int? dureeMinutes;
    DateTime? dateHeureArrivee;

    final ok = await showDialog<bool>(
      context: ctx,
      builder: (context) {
        int? duree = dureeMinutes;
        DateTime? arrivee = dateHeureArrivee;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.endTrip),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.optionalDurationOrArrival,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Durée (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        duree = int.tryParse(v);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        arrivee = DateTime.now();
                        setDialogState(() {});
                      },
                      child: const Text('Maintenant'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancelLabel),
                ),
                FilledButton(
                  onPressed: () {
                    dureeMinutes = duree;
                    dateHeureArrivee = arrivee;
                    Navigator.of(context).pop(true);
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;
    try {
      final repo = ref.read(transportRepositoryProvider);
      await repo.terminer(t.id, dureeMinutes: dureeMinutes, dateHeureArrivee: dateHeureArrivee);
      if (mounted) {
        ref.read(transportUiRefreshProvider.notifier).state++;
        final resId = t.vehicleReservationId;
        if (resId != null && resId.isNotEmpty) {
          ref.invalidate(vehicleReservationProvider(resId));
        }
        ref.invalidate(myVehicleReservationsProvider);
        ref.invalidate(tripHistoryUnifiedRowsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.tripEnded), backgroundColor: Colors.green),
        );
        _etaTimer?.cancel();
        _load();
      }
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

  static String _shortId(String id) {
    if (id.length <= 4) return id;
    return id.substring(id.length - 4);
  }

  void _openPhone(BuildContext context, String? phone) {
    if (phone == null || phone.isEmpty) return;
    try {
      // Si url_launcher est installé : launchUrl(Uri.parse('tel:$phone'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phone)),
      );
    } catch (_) {}
  }

  static String _formatTerminedTripSummary(AppStrings strings, TransportModel t) {
    final parts = <String>[];
    if (t.dureeMinutes != null) {
      parts.add(strings.tripDurationMinutes(t.dureeMinutes!));
    }
    if (t.dateHeureArrivee != null) {
      final time = t.dateHeureArrivee!.toIso8601String();
      final hourMin = time.length >= 16 ? time.substring(11, 16) : time;
      parts.add('${strings.labelArrival} $hourMin');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          title: Text(strings.tripDetails),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _transport == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          title: Text(strings.tripDetails),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Demande introuvable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: Text(strings.save),
              ),
            ],
          ),
        ),
      );
    }

    final t = _transport!;
    final demandeur = t.demandeur;
    final accompagnant = t.accompagnant;
    final vehicle = t.vehicle;
    final photoDemandeur = UserRepository.photoUrl(demandeur?.photoProfil);
    final photoAccompagnant = UserRepository.photoUrl(accompagnant?.photoProfil);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          strings.tripDetails,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_canCancel(user, t))
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: strings.cancelTripAction,
              onPressed: () => _confirmCancel(strings),
            ),
          if (t.isActiveTrip)
            IconButton(
              icon: const Icon(Icons.location_on),
              tooltip: strings.liveTracking,
              onPressed: () => context.push('/transport/${t.id}/suivi'),
            ),
          if (_canShare(user, t))
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: strings.shareTripTitle,
              onPressed: () => _shareTrip(strings),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ——— Carte Statut + ETA ———
                  _buildStatusEtaCard(t, strings, theme),
                  if (t.isFromVehicleReservation &&
                      t.vehicleReservationId != null &&
                      t.vehicleReservationId!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(strings.tripFromVehicleReservationBadge),
                            visualDensity: VisualDensity.compact,
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/vehicle-reservations/${t.vehicleReservationId}',
                            ),
                            icon: const Icon(Icons.event_note_outlined, size: 18),
                            label: Text(strings.openVehicleReservationFromTrip),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (t.prixFinalTnd != null)
                    _buildPriceBanner(strings.finalPriceTnd(t.prixFinalTnd!), theme),
                  if (t.prixFinalTnd == null && t.prixEstimeTnd != null)
                    _buildPriceBanner(strings.estimatedPriceTnd(t.prixEstimeTnd!), theme),
                  if (t.prixFinalTnd != null || t.prixEstimeTnd != null)
                    const SizedBox(height: 16),
                  if (user != null &&
                      t.isAssignedDriver(user) &&
                      t.isActiveTrip) ...[
                    _buildDriverStatutActions(t, strings, theme),
                    const SizedBox(height: 16),
                  ],
                  // ——— Carte Trajet (Départ / Destination) ———
                  _buildRouteCard(t, vehicle, strings, theme),
                  const SizedBox(height: 20),
                  // ——— Section Participants ———
                  Text(
                    strings.participantsSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (demandeur != null) _buildParticipantCard(
                    context,
                    label: strings.beneficiary,
                    name: demandeur.displayName,
                    photoUrl: photoDemandeur,
                    isBeneficiary: true,
                    phone: demandeur.telephone,
                    theme: theme,
                  ),
                  if (demandeur != null) const SizedBox(height: 12),
                  if (accompagnant != null) _buildDriverCard(
                    context,
                    strings: strings,
                    name: accompagnant.displayName,
                    photoUrl: photoAccompagnant,
                    phone: accompagnant.telephone,
                    theme: theme,
                    noteMoyenne: accompagnant.noteMoyenne,
                  ),
                  if (vehicle != null) ...[
                    const SizedBox(height: 8),
                    _buildVehicleCard(vehicle, strings, theme),
                  ],
                  if (t.isTerminee &&
                      user != null &&
                      t.isDemandeurUser(user) &&
                      _reviews.isEmpty) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openReviewDialog(user, strings),
                      icon: const Icon(Icons.star_outline),
                      label: Text(strings.evaluateTrip),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // ——— Bouton fixe Terminer le trajet ———
          if (t.canTerminate)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              color: Colors.white,
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _terminer,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(
                    strings.endTrip,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (t.isTerminee) ...[
            const SizedBox(height: 16),
            if (t.dureeMinutes != null || t.dateHeureArrivee != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _formatTerminedTripSummary(strings, t),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBanner(String text, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDriverStatutActions(
    TransportModel t,
    AppStrings strings,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.driver,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        if (t.statut == 'ACCEPTEE')
          OutlinedButton.icon(
            onPressed: () => _patchStatut('EN_ROUTE', strings),
            icon: const Icon(Icons.directions_car_outlined),
            label: Text(strings.enRoute),
          ),
        if (t.statut == 'EN_ROUTE')
          OutlinedButton.icon(
            onPressed: () => _patchStatut('ARRIVEE', strings),
            icon: const Icon(Icons.place_outlined),
            label: Text(strings.arrivedAtPickupLabel),
          ),
        if (t.statut == 'ARRIVEE')
          OutlinedButton.icon(
            onPressed: () => _patchStatut('EN_COURS', strings),
            icon: const Icon(Icons.navigation_outlined),
            label: Text(strings.startRideToDestinationLabel),
          ),
      ],
    );
  }

  Widget _buildStatusEtaCard(TransportModel t, AppStrings strings, ThemeData theme) {
    final isActive = t.isActiveTrip;
    final isTerminee = t.isTerminee;
    final minutes = _eta?.dureeMinutes.round() ?? t.dureeMinutes ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isTerminee ? Colors.green : _primaryBlue.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isTerminee ? Colors.green.shade50 : _primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTerminee ? Colors.green.shade200 : _primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      t.statut ?? '—',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isTerminee ? Colors.green.shade800 : _primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                strings.orderNumberDisplay(_shortId(t.id)),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          if (isActive || isTerminee) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$minutes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'min',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.estimatedArrivalLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.35,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue.withValues(alpha: 0.7)),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(TransportModel t, dynamic vehicle, AppStrings strings, ThemeData theme) {
    final hasClimatisation = vehicle != null && vehicle.accessibilite.climatisation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: _primaryBlue.withValues(alpha: 0.5),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.labelDeparture,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.depart ?? '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Tunis, Tunisie',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.labelDestination,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.destination ?? '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Tunis, Tunisie',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                if (t.besoinsAssistance != null && t.besoinsAssistance!.isNotEmpty || hasClimatisation) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...?t.besoinsAssistance?.map((b) {
                        final isWheelchair = b == 'fauteuil_roulant';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isWheelchair ? Icons.accessible : Icons.directions_walk,
                                size: 16,
                                color: _primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isWheelchair ? strings.wheelchairAssistance : strings.boardingHelp,
                                style: theme.textTheme.labelMedium?.copyWith(color: _primaryBlue),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (hasClimatisation)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ac_unit, size: 16, color: _primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                strings.climatised,
                                style: theme.textTheme.labelMedium?.copyWith(color: _primaryBlue),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(
    BuildContext context, {
    required String label,
    required String name,
    required String photoUrl,
    required bool isBeneficiary,
    String? phone,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.person, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              onPressed: () => _openPhone(context, phone),
              style: IconButton.styleFrom(
                backgroundColor: _primaryBlue.withValues(alpha: 0.12),
              ),
              icon: Icon(Icons.phone, color: _primaryBlue, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context, {
    required AppStrings strings,
    required String name,
    required String photoUrl,
    String? phone,
    required ThemeData theme,
    double noteMoyenne = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.directions_car, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.driver,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                    Text(
                      noteMoyenne > 0
                          ? noteMoyenne.toStringAsFixed(1)
                          : '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty) ...[
            IconButton(
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: _primaryBlue.withValues(alpha: 0.12),
              ),
              icon: Icon(Icons.chat_bubble_outline, color: _primaryBlue, size: 20),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _openPhone(context, phone),
              style: IconButton.styleFrom(
                backgroundColor: _primaryBlue.withValues(alpha: 0.12),
              ),
              icon: Icon(Icons.phone, color: _primaryBlue, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, AppStrings strings, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_car, size: 28, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (vehicle.immatriculation.isNotEmpty)
                  Text(
                    vehicle.immatriculation,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          if (vehicle.immatriculation.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                vehicle.immatriculation,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
