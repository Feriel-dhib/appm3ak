import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/accessibility/accessible_place.dart';
import '../data/repositories/accessibility_places_repository.dart';
import 'api_providers.dart';
import 'community_providers.dart';

/// Repository "Accès & Lieux accessibles" (analyse IA, itinéraires, OSM).
final accessibilityPlacesRepositoryProvider =
    Provider<AccessibilityPlacesRepository>((ref) {
  return AccessibilityPlacesRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Indique si le backend /accessibility/* répond (ping `/health`).
/// Rafraîchi automatiquement à chaque `ref.refresh`.
final accessibilityBackendOnlineProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(accessibilityPlacesRepositoryProvider);
  return repo.isBackendOnline();
});

/// Catalogue des lieux accessibles : d’abord les lieux **approuvés** de l’API
/// [`GET /lieux`](Endpoints.lieux), sinon repli sur `assets/places.json`.
final accessiblePlacesCatalogProvider =
    FutureProvider<List<AccessiblePlace>>((ref) async {
  try {
    final repo = ref.watch(locationRepositoryProvider);
    final lieux = await repo.getAllLocations();
    final approved =
        lieux.where((l) => l.isApproved && l.nom.trim().isNotEmpty).toList();
    if (approved.isNotEmpty) {
      return approved.map(AccessiblePlace.fromLocation).toList();
    }
  } catch (_) {
    // Réseau ou backend indisponible → catalogue embarqué.
  }
  return AccessiblePlace.loadFromAsset('assets/places.json');
});
