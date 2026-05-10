import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/accessibility/accessible_place.dart';
import '../../../data/models/accessibility/accessible_route_result.dart';
import '../../../data/models/accessibility/ai_accessibility_result.dart';
import '../../../data/repositories/accessibility_places_repository.dart';
import '../../../providers/accessibility_places_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../widgets/ai_score_panel.dart';

/// Détail d'un [AccessiblePlace] + analyse IA temps réel + itinéraire accessible.
class AccessiblePlaceDetailScreen extends ConsumerStatefulWidget {
  const AccessiblePlaceDetailScreen({super.key, required this.place});

  final AccessiblePlace place;

  @override
  ConsumerState<AccessiblePlaceDetailScreen> createState() =>
      _AccessiblePlaceDetailScreenState();
}

class _AccessiblePlaceDetailScreenState
    extends ConsumerState<AccessiblePlaceDetailScreen> {
  AIAccessibilityResult? _aiResult;
  bool _aiLoading = false;
  String? _aiError;
  /// Extraits de posts `/community/posts` passés à l’IA via `user_comments`.
  List<String> _communitySnippetsForAi = const [];

  AccessibleRouteResult? _route;
  bool _routeLoading = false;
  LatLng? _startPoint;

  @override
  void initState() {
    super.initState();
    // Lance l'analyse IA automatiquement à l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalyze());
  }

  Future<void> _runAnalyze() async {
    if (!mounted) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _communitySnippetsForAi = const [];
    });
    try {
      final comments = await _collectCommunityCommentsForPlace();
      if (!mounted) return;
      setState(() => _communitySnippetsForAi = comments);

      final repo = ref.read(accessibilityPlacesRepositoryProvider);
      final result = await repo.analyze(
        placeName: widget.place.name,
        latitude: widget.place.latitude,
        longitude: widget.place.longitude,
        wheelchairAccess: widget.place.wheelchairAccess,
        elevator: widget.place.elevator,
        braille: widget.place.braille,
        audioAssistance: widget.place.audioAssistance,
        accessibleToilets: widget.place.accessibleToilets,
        userComments: comments,
      );
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _aiLoading = false;
      });
    } on AccessibilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = e.message;
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Erreur inattendue : $e';
        _aiLoading = false;
      });
    }
  }

  /// Récupère des témoignages communautaires liés au lieu pour enrichir
  /// `POST /accessibility/analyze` (`user_comments` → Groq côté serveur).
  Future<List<String>> _collectCommunityCommentsForPlace() async {
    final place = widget.place;
    final name = place.name.trim();
    if (name.isEmpty) return const [];

    final repo = ref.read(communityRepositoryProvider);
    final out = <String>[];
    final seenKey = <String>{};

    try {
      for (var page = 1; page <= 5 && out.length < 16; page++) {
        final r = await repo.getPosts(
          page: page,
          limit: 40,
          search: name.length >= 3 ? name : null,
        );
        for (final p in r.posts) {
          final raw = p.contenu.trim();
          if (raw.isEmpty) continue;
          if (!_postContenuLieAuLieu(raw, place)) continue;
          final key = raw.length > 140 ? raw.substring(0, 140) : raw;
          if (seenKey.contains(key)) continue;
          seenKey.add(key);
          out.add(raw.length > 480 ? '${raw.substring(0, 477)}…' : raw);
          if (out.length >= 15) break;
        }
        if (r.posts.length < 40) break;
      }
    } catch (_) {
      // Hors-ligne ou endpoint inconnu : l’IA s’appuie seulement sur OSM + métadonnées lieu.
    }
    return out;
  }

  bool _postContenuLieAuLieu(String contenu, AccessiblePlace place) {
    final t = contenu.toLowerCase();
    final n = place.name.toLowerCase().trim();
    if (n.isNotEmpty && t.contains(n)) return true;
    final city = place.city.toLowerCase().trim();
    if (city.isEmpty || n.isEmpty) return false;
    if (!t.contains(city)) return false;
    final prefix = n.length > 18 ? n.substring(0, 18) : n;
    return t.contains(prefix);
  }

  void _openContributeForPlace(BuildContext context) {
    final p = widget.place;
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final uri = Uri(
      path: '/create-post',
      queryParameters: {
        'lat': p.latitude.toString(),
        'lng': p.longitude.toString(),
        'bindLocation': '1',
        'returnTo': 'community-hub',
        'placeName': p.name,
        'placeCity': p.city,
        'contentHint': strings.createPostHintFromChosenPlace,
      },
    );
    context.push(uri.toString());
  }

  Future<void> _computeRoute() async {
    final start = _startPoint;
    if (start == null) return;
    setState(() {
      _routeLoading = true;
      _route = null;
    });
    try {
      final repo = ref.read(accessibilityPlacesRepositoryProvider);
      final r = await repo.accessibleRoute(
        start: start,
        end: LatLng(widget.place.latitude, widget.place.longitude),
      );
      if (!mounted) return;
      setState(() {
        _route = r;
        _routeLoading = false;
      });
      if (!r.isSuccess && r.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.errorMessage!)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _routeLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Itinéraire indisponible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = widget.place;
    final center = LatLng(place.latitude, place.longitude);
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openContributeForPlace(context),
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(strings.contributeFromAccessiblePlace),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(place: place),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                  onTap: (_, p) {
                    setState(() => _startPoint = p);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'tn.ma3ak.app',
                  ),
                  if (_route != null && _route!.isSuccess)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route!.coordinates,
                          strokeWidth: 4,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.place,
                          color: theme.colorScheme.primary,
                          size: 36,
                        ),
                      ),
                      if (_startPoint != null)
                        Marker(
                          point: _startPoint!,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _startPoint == null
                ? 'Touchez la carte pour définir votre point de départ.'
                : 'Départ choisi : ${_startPoint!.latitude.toStringAsFixed(4)}, '
                    '${_startPoint!.longitude.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _startPoint == null || _routeLoading ? null : _computeRoute,
                  icon: _routeLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.alt_route),
                  label: Text(_routeLoading
                      ? 'Calcul…'
                      : 'Calculer un itinéraire accessible'),
                ),
              ),
            ],
          ),
          if (_route != null && _route!.isSuccess) ...[
            const SizedBox(height: 8),
            _RouteSummary(route: _route!),
          ],
          const SizedBox(height: 16),
          Text('Analyse IA d\'accessibilité',
              style: theme.textTheme.titleMedium),
          AIScorePanel(
            result: _aiResult,
            isLoading: _aiLoading,
            error: _aiError,
            onRetry: _runAnalyze,
          ),
          if (_communitySnippetsForAi.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Avis communauté (${_communitySnippetsForAi.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ces extraits sont envoyés au service d’analyse IA avec les données '
              'OSM pour calculer les scores et le résumé.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ..._communitySnippetsForAi.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      s,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (!_aiLoading && _aiError == null && _aiResult != null) ...[
            const SizedBox(height: 12),
            Text(
              'Aucun avis communautaire lié à ce lieu n’a été trouvé : '
              'l’analyse IA repose surtout sur l’OpenStreetMap et les équipements déclarés.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Description', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(place.description.isEmpty
              ? 'Aucune description fournie.'
              : place.description),
          const SizedBox(height: 16),
          Text('Équipements déclarés', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _Equipments(place: place),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.place});

  final AccessiblePlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('${place.category.label} • ${place.city}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 30,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${place.accessibilityScore}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route});

  final AccessibleRouteResult route;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final km = (route.distanceMeters / 1000).toStringAsFixed(2);
    final min = (route.durationSeconds / 60).round();
    final scorePct = (route.accessibilityScore * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Itinéraire accessible : $km km • ~$min min • score $scorePct %',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Equipments extends StatelessWidget {
  const _Equipments({required this.place});

  final AccessiblePlace place;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, IconData icon, bool value})>[
      (
        label: 'Accès fauteuil roulant',
        icon: Icons.accessible_rounded,
        value: place.wheelchairAccess
      ),
      (label: 'Ascenseur', icon: Icons.elevator, value: place.elevator),
      (
        label: 'Signalétique braille',
        icon: Icons.text_fields_rounded,
        value: place.braille
      ),
      (
        label: 'Assistance audio',
        icon: Icons.hearing_rounded,
        value: place.audioAssistance
      ),
      (label: 'Toilettes adaptées', icon: Icons.wc, value: place.accessibleToilets),
    ];
    return Column(
      children: items
          .map(
            (it) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(it.icon,
                  color: it.value ? Colors.green : Colors.grey),
              title: Text(it.label),
              trailing: Icon(
                it.value ? Icons.check_circle : Icons.cancel_outlined,
                color: it.value ? Colors.green : Colors.grey,
              ),
            ),
          )
          .toList(),
    );
  }
}
