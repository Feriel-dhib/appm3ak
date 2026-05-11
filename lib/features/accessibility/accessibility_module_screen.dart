part of 'accessibility_module.dart';

// Retour matériel / GoRouter : évite de dépiler une route vide.
void _safePopAccessibilityMap(BuildContext context) {
  if (!context.mounted) return;
  try {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  } catch (_) {
    if (context.mounted) {
      try {
        context.go('/home');
      } catch (_) {}
    }
  }
}

const String _accessibilityPostHintQuery =
    "Partagez votre expérience d'accessibilité dans ce lieu...";

// ═══════════════════════════════════════════════════════════════════════════════
//  AccessibilityModuleScreen  —  LOGIQUE PRINCIPALE MODIFIÉE
// ═══════════════════════════════════════════════════════════════════════════════
class AccessibilityModuleScreen extends ConsumerStatefulWidget {
  const AccessibilityModuleScreen({super.key});
  @override
  ConsumerState<AccessibilityModuleScreen> createState() =>
      _AccessibilityModuleScreenState();
}

class _AccessibilityModuleScreenState
    extends ConsumerState<AccessibilityModuleScreen> {
  // ── Services ─────────────────────────────────────────────────────────────────
  final GeoapifyPlacesService        _geoapifyPlacesService       = GeoapifyPlacesService();
  // NOUVEAU : votre IA Python
  final AccessibleRouteService       _accessibleRouteService      = AccessibleRouteService();
  // Fallback ORS si l'API Python est éteinte
  final OpenRouteDirectionsService   _openRouteDirectionsService  = OpenRouteDirectionsService();
  final OsrmDirectionsService        _osrmService                 = OsrmDirectionsService();

  TransportMode _selectedTransportMode = TransportMode.apied;

  final TextEditingController _searchController      = TextEditingController();

  List<AccessiblePlace> _allPlaces    = [];
  bool   _placesLoading               = true;
  String? _placesLoadError;

  final Set<PlaceCategory> _selectedCategories = Set.from(PlaceCategory.values);
  DisabilityType _selectedDisability  = DisabilityType.moteur;
  int  _selectedTab                   = 0;
  bool _offlineEnabled                = false;
  bool _isMapExpanded                 = false;
  bool _mapDownloaded                 = false;
  bool _routesDownloaded              = false;
  bool _placesDownloaded              = false;
  bool _avoidObstacles                = true;
  bool _includeElevators              = true;
  final int _geoapifyRadiusMeters     = 500;

  AccessiblePlace? _selectedPlace;
  AIAccessibilityResult? _aiResult;
  bool             _aiLoading         = false;
  RoutePlan?       _currentRoute;
  List<LatLng>?    _routePolyline;
  String?          _routeError;
  bool             _routeLoading      = false;
  bool             _hasActiveRouteSession = false;
  int              _routeFitToken     = 0;

  // NOUVEAU : source de l'itinéraire affiché
  RouteSource      _routeSource       = RouteSource.pythonAI;

  // Navigation active (mode "Démarrer")
  int              _reservationsReloadToken = 0;
  bool             _navigationActive       = false;
  int              _navStepIndex           = 0;
  double           _navProgressFraction    = 0.0;  // 0.0 → 1.0
  double           _navDistanceRemaining   = 0.0;  // mètres
  double           _navDurationRemaining   = 0.0;  // secondes
  int              _navClosestPointIndex   = 0;     // index sur le polyline
  // Masque la fiche lieu quand on visualise le tracé sur la carte
  bool             _showPlaceCardOnMap = true;

  final Map<String, PlaceGeoInsights> _geoInsightsByPlace = {};
  final Set<String>                   _geoLoadingByPlace  = {};
  final List<UserContribution>   _contributions  = [];

  LatLng?  _userLatLng;
  bool     _locationSetupComplete     = false;
  int      _myLocationRecenterSignal  = 0;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    unawaited(AccessibleRouteService.preloadEndpointFromAsset());
    _searchController.addListener(() {
      setState(() {});
      _scheduleLoadSelectedPlaceGeoInsights();
    });
    unawaited(_loadPlacesFromJson());
    unawaited(_startUserLocationTracking());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Catalogue fusionné : `assets/accessibility/places.json`, `assets/places.json`, puis API `/lieux`.
  Future<void> _loadPlacesFromJson() async {
    final merged = <AccessiblePlace>[];
    final seen = <String>{};

    Future<void> addPlaces(List<AccessiblePlace> list) async {
      for (final p in list) {
        if (!p.latitude.isFinite || !p.longitude.isFinite) continue;
        if (p.latitude.abs() < 1e-7 && p.longitude.abs() < 1e-7) continue;
        if (seen.add(p.id)) merged.add(p);
      }
    }

    try {
      await addPlaces(
          await AccessiblePlace.loadFromAsset('assets/accessibility/places.json'));
    } catch (e, st) {
      debugPrint('assets/accessibility/places.json: $e\n$st');
    }
    try {
      await addPlaces(await AccessiblePlace.loadFromAsset('assets/places.json'));
    } catch (e) {
      debugPrint('assets/places.json: $e');
    }

    try {
      final repo = ref.read(locationRepositoryProvider);
      final lieux = await repo.getAllLocations();
      for (final m in lieux) {
        if (m.statut != LocationStatus.approved) continue;
        final p = _accessiblePlaceFromLocationModel(m);
        if (seen.add(p.id)) merged.add(p);
      }
    } catch (e) {
      debugPrint('GET /lieux (catalogue carte): $e');
    }

    if (!mounted) return;
    if (merged.isEmpty) {
      setState(() {
        _placesLoading = false;
        _placesLoadError = 'Aucun lieu disponible.';
        _allPlaces = [];
        _selectedPlace = null;
      });
      return;
    }
    setState(() {
      _allPlaces = merged;
      _placesLoading = false;
      _placesLoadError = null;
      _selectedPlace = merged.first;
    });
    _scheduleLoadSelectedPlaceGeoInsights();
  }

  AccessiblePlace _accessiblePlaceFromLocationModel(LocationModel m) {
    final score = (m.scoreAccessibilite ?? 0).clamp(0, 100);
    final desc = (m.description ?? m.aiSummary ?? '').trim();
    final amenities = m.amenities ?? const <String>[];
    bool has(String needle) => amenities.any(
          (a) => a.toLowerCase().contains(needle.toLowerCase()),
        );

    var wheelchair = has('wheel') || has('fauteuil') || has('ramp');
    var elevator = has('elev') || has('ascenseur');
    final braille = has('braille');
    final audio = has('audio') || has('boucle') || has('hearing');
    final toilets = has('toilet') || has('wc') || has('sanitaire');

    if (m.categorie == LocationCategory.hospital) {
      elevator = elevator || true;
      wheelchair = wheelchair || score >= 50;
    }

    final adapted = <DisabilityType>{};
    if (has('moteur') || wheelchair) adapted.add(DisabilityType.moteur);
    if (has('visuel') || has('cecit') || braille) adapted.add(DisabilityType.visuel);
    if (has('auditif') || has('sourd') || audio) adapted.add(DisabilityType.auditif);
    if (has('cognitif')) adapted.add(DisabilityType.cognitif);
    if (adapted.isEmpty) adapted.add(DisabilityType.moteur);

    final PlaceCategory cat;
    switch (m.categorie) {
      case LocationCategory.hospital:
        cat = PlaceCategory.hopital;
        break;
      case LocationCategory.restaurant:
        cat = PlaceCategory.cafe;
        break;
      case LocationCategory.pharmacy:
      case LocationCategory.shop:
        cat = PlaceCategory.commerce;
        break;
      case LocationCategory.publicTransport:
        cat = PlaceCategory.transport;
        break;
      case LocationCategory.school:
      case LocationCategory.park:
      case LocationCategory.other:
        cat = PlaceCategory.autre;
    }

    final description =
        desc.isNotEmpty ? desc : '${m.adresse}, ${m.ville}'.trim();

    return AccessiblePlace(
      id: m.id,
      name: m.nom,
      city: m.ville,
      latitude: m.latitude,
      longitude: m.longitude,
      wheelchairAccess: wheelchair,
      elevator: elevator,
      braille: braille,
      audioAssistance: audio,
      accessibleToilets: toilets || m.categorie == LocationCategory.hospital,
      accessibilityScore: score,
      description: description,
      category: cat,
      adaptedFor: adapted,
      distanceKm: 0,
      baseReports: 0,
      basePhotos: 0,
    );
  }

  Future<void> _startUserLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) { setState(()=>_locationSetupComplete=true); _maybeShowLocationSnack('Activez la localisation dans les réglages du téléphone.'); }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission==LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission==LocationPermission.deniedForever) {
        if (mounted) { setState(()=>_locationSetupComplete=true); _maybeShowLocationSnack('Autorisation refusée.'); }
        return;
      }
      if (permission==LocationPermission.denied) { if (mounted) setState(()=>_locationSetupComplete=true); return; }
      final current = await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));
      if (!mounted) return;
      setState(() { _userLatLng=LatLng(current.latitude,current.longitude); _locationSetupComplete=true; });
      _positionSub = Geolocator.getPositionStream(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:5))
        .listen((Position pos) {
          if(!mounted)return;
          setState(()=>_userLatLng=LatLng(pos.latitude,pos.longitude));
          // Mise à jour navigation en temps réel
          if (_navigationActive) _updateNavigationProgress();
        });
    } catch (_) { if (mounted) setState(()=>_locationSetupComplete=true); }
  }

  void _maybeShowLocationSnack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
    });
  }

  /// Point A réel pour l’itinéraire : GPS courant (timeout 10s), puis dernier connu.
  /// Sans position valide → snack « Activez la localisation », pas de calcul avec faux départ.
  Future<LatLng?> _ensureRouteStartLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _maybeShowLocationSnack('Activez la localisation');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _maybeShowLocationSnack('Activez la localisation');
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      final ll = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _userLatLng = ll);
      return ll;
    } catch (_) {}

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      final ll = LatLng(last.latitude, last.longitude);
      if (mounted) setState(() => _userLatLng = ll);
      return ll;
    }

    _maybeShowLocationSnack('Activez la localisation');
    return null;
  }

  void _onMyLocationFabPressed() {
    unawaited(_recenterOnUserLocation());
  }

  Future<void> _recenterOnUserLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _maybeShowLocationSnack('Activez la localisation dans les réglages du téléphone.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _maybeShowLocationSnack('Autorisation de localisation refusée.');
        return;
      }
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _userLatLng = LatLng(current.latitude, current.longitude);
        _myLocationRecenterSignal++;
      });
    } catch (_) {
      if (!mounted) return;
      if (_userLatLng != null) {
        setState(() => _myLocationRecenterSignal++);
      } else {
        _maybeShowLocationSnack('Position indisponible pour le moment.');
      }
    }
  }

  bool _selectionAlignScheduled = false;

  List<AccessiblePlace> _computeFilteredPlaces() {
    final query = _searchController.text.trim().toLowerCase();
    return _allPlaces.where((p) {
      final matchesSearch = query.isEmpty
          || p.name.toLowerCase().contains(query)
          || p.city.toLowerCase().contains(query)
          || p.description.toLowerCase().contains(query)
          || _categoryLabel(p.category).toLowerCase().contains(query);
      // Si aucun filtre handicap actif, on affiche tous les lieux
      final matchesDisability = p.adaptedFor.contains(_selectedDisability);
      return matchesDisability && _selectedCategories.contains(p.category) && matchesSearch;
    }).toList();
  }

  String _categoryLabel(PlaceCategory c) {
    switch(c) {
      case PlaceCategory.hopital: return 'hopital';
      case PlaceCategory.administration: return 'administration';
      case PlaceCategory.cafe: return 'cafe';
      case PlaceCategory.commerce: return 'commerce';
      case PlaceCategory.transport: return 'transport';
      case PlaceCategory.autre: return 'autre';
    }
  }

  int _placeReports(AccessiblePlace place) {
    final localReports = _contributions.where((c)=>c.placeId==place.id&&c.type==ContributionType.signalement).length;
    final geoIssues    = _geoInsightsByPlace[place.id]?.issueSignals??0;
    return place.baseReports+localReports+geoIssues;
  }

  int _placePhotos(AccessiblePlace place) {
    final localPhotos = _contributions.where((c)=>c.placeId==place.id&&c.type==ContributionType.photo).length;
    final geoPhotos   = _geoInsightsByPlace[place.id]?.photoUrls.length??0;
    return place.basePhotos+localPhotos+geoPhotos;
  }

  void _scheduleLoadSelectedPlaceGeoInsights() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted||_selectedPlace==null) return;
      _loadGeoInsightsForPlace(_selectedPlace!);
    });
  }

  Future<void> _loadGeoInsightsForPlace(AccessiblePlace place) async {
    if (!_geoapifyPlacesService.isEnabled) return;
    if (_geoInsightsByPlace.containsKey(place.id)||_geoLoadingByPlace.contains(place.id)) return;
    setState(()=>_geoLoadingByPlace.add(place.id));
    final insights = await _geoapifyPlacesService.fetchInsights(place:place,category:_geoapifyCategoryFor(place.category),radiusMeters:_geoapifyRadiusMeters);
    if (!mounted) return;
    setState(() { _geoLoadingByPlace.remove(place.id); if(insights!=null) _geoInsightsByPlace[place.id]=insights; });
  }

  void _setSelectedPlace(AccessiblePlace place) {
    final previousId = _selectedPlace?.id;
    setState((){ _selectedPlace=place; _aiResult=null; _aiLoading=true; _showPlaceCardOnMap=true; });
    _loadGeoInsightsForPlace(place);
    AccessibilityAIService.analyze(
      placeName: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      wheelchairAccess: place.wheelchairAccess,
      elevator: place.elevator,
      braille: place.braille,
      audioAssistance: place.audioAssistance,
      accessibleToilets: place.accessibleToilets,
    ).then((result) {
      if (!mounted) return;
      setState(() { _aiResult = result; _aiLoading = false; });
    });
    if (_hasActiveRouteSession&&_userLatLng!=null&&previousId!=null&&previousId!=place.id) {
      unawaited(_fetchRoute(showSuccessSnack:false));
    }
  }

  void _resetRouteStateFields() {
    _routePolyline=null; _routeError=null; _currentRoute=null;
    _hasActiveRouteSession=false; _routeFitToken=0; _navigationActive=false;
    _navProgressFraction=0.0; _navDistanceRemaining=0; _navDurationRemaining=0;
    _navClosestPointIndex=0; _isMapExpanded=false;
    _showPlaceCardOnMap=true;
  }

  // Réinitialise l'affichage de l'itinéraire sans fermer la session
  void _clearRouteDisplay() {
    _routePolyline=null; _routeError=null; _currentRoute=null; _routeFitToken=0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  NOUVELLE LOGIQUE : votre IA Python EN PRIORITÉ, ORS en fallback
  // ═══════════════════════════════════════════════════════════════════════════
  // ── Distance Haversine (vol d'oiseau) ────────────────────────────────────
  double _haversineMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  /// Longueur du polyline (somme des segments), en mètres.
  double _pathLengthMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double sum = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      sum += _haversineMeters(pts[i], pts[i + 1]);
    }
    return sum;
  }

  /// Tracé trop proche du vol d’oiseau → ne pas remplacer la géométrie OSRM.
  bool _isNearlyStraightLine(List<LatLng> pts) {
    if (pts.length < 3) return true;
    final air = _haversineMeters(pts.first, pts.last);
    if (air < 30) return false;
    final path = _pathLengthMeters(pts);
    return path / air < 1.12;
  }

  // ── Mise à jour de la progression de navigation ───────────────────────────
  // Appelée à chaque update GPS. Trouve le point du polyline le plus proche
  // de la position actuelle, calcule la distance et durée restantes.
  void _updateNavigationProgress() {
    final polyline = _routePolyline;
    final pos = _userLatLng;
    if (!_navigationActive || polyline == null || polyline.length < 2 || pos == null) return;

    // Trouver le segment le plus proche de la position actuelle
    double minDist = double.infinity;
    int closestIdx = _navClosestPointIndex;

    // On cherche uniquement en avant de la position actuelle (ne pas revenir en arrière)
    final searchFrom = (_navClosestPointIndex - 2).clamp(0, polyline.length - 1);
    for (int i = searchFrom; i < polyline.length; i++) {
      final d = _haversineMeters(pos, polyline[i]);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
      // Arrêter la recherche si on s'éloigne trop (optimisation)
      if (d > 300 && i > searchFrom + 10) break;
    }

    // Calculer la distance restante sur le tracé (du point le plus proche à la fin)
    double distRemaining = 0;
    for (int i = closestIdx; i < polyline.length - 1; i++) {
      distRemaining += _haversineMeters(polyline[i], polyline[i + 1]);
    }

    // Distance totale du tracé
    double totalDist = 0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDist += _haversineMeters(polyline[i], polyline[i + 1]);
    }

    // Progression (0.0 = départ, 1.0 = arrivée)
    final progress = totalDist > 0
        ? ((totalDist - distRemaining) / totalDist).clamp(0.0, 1.0)
        : 0.0;

    // Durée restante basée sur la vitesse du mode
    final durRemaining = _selectedTransportMode.estimateDurationSeconds(distRemaining);

    // Arrivée détectée : moins de 30m
    if (distRemaining < 30) {
      setState(() {
        _navigationActive = false;
        _navProgressFraction = 1.0;
        _showPlaceCardOnMap = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Vous êtes arrivé à destination !'),
          backgroundColor: Color(0xFF2A9F58),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _navClosestPointIndex   = closestIdx;
      _navProgressFraction    = progress;
      _navDistanceRemaining   = distRemaining;
      _navDurationRemaining   = durRemaining;
    });

    // Recentrer la carte sur la position en navigation
    _myLocationRecenterSignal++;
  }

  Future<void> _fetchRoute({bool showSuccessSnack=true}) async {
    final place = _selectedPlace;
    if (place==null) { _maybeShowLocationSnack('Sélectionnez une destination.'); return; }
    if (!place.latitude.isFinite ||
        !place.longitude.isFinite ||
        (place.latitude.abs() < 1e-7 && place.longitude.abs() < 1e-7)) {
      _maybeShowLocationSnack('Ce lieu n\'a pas de coordonnées GPS valides pour l\'itinéraire.');
      return;
    }

    final start = await _ensureRouteStartLatLng();
    if (!mounted) return;
    if (start == null) return;

    final end = LatLng(place.latitude, place.longitude);
    final sepM =
        const Distance().as(LengthUnit.Meter, start, end);
    if (sepM < 3) {
      _maybeShowLocationSnack('Vous êtes déjà à destination');
      return;
    }
    if (sepM > 500000) {
      _maybeShowLocationSnack(
          'Destination trop éloignée, vérifiez votre position');
      return;
    }

    if (!mounted) return;
    setState(() { _routeLoading=true; _routeError=null; _currentRoute=null; _routePolyline=null; });

    final mode = _selectedTransportMode;

    try {
      // ══════════════════════════════════════════════════════════════════════
      //  ÉTAPE 1 — Tracé routier : OSRM → Nest POST /map/route → Valhalla →
      //  dernier recours ligne droite (vol d'oiseau) avec message utilisateur.
      // ══════════════════════════════════════════════════════════════════════
      final roadResult = await _osrmService.fetchRoute(start:start, end:end, mode:mode);
      if (!mounted) return;

      // Échec si aucun tracé (y compris vol d’oiseau en dernier recours)
      if (!roadResult.isSuccess) {
        setState(() {
          _routeLoading=false;
          _routeError='Réseau indisponible — impossible de calculer un itinéraire réel.\n(${roadResult.errorMessage})';
          _routePolyline=null; _currentRoute=null; _hasActiveRouteSession=false;
        });
        return;
      }

      // Le tracé OSRM/Valhalla est garanti d'avoir ≥ 2 points sur de vraies rues
      final roadPoints = roadResult.points!;
      double distMeters = roadResult.distanceMeters;
      double durSeconds = mode == TransportMode.moto
          ? mode.estimateDurationSeconds(distMeters)
          : roadResult.durationSeconds;

      debugPrint('[ROUTE] ✅ Tracé routier réel — ${roadPoints.length} pts, '
          '${_formatRouteDistance(distMeters)}, ${_formatRouteDuration(durSeconds)}');

      // Afficher immédiatement le tracé réel (sans attendre l'IA)
      final realDistance = _formatRouteDistance(distMeters);
      final realDuration = _formatRouteDuration(durSeconds);
      setState(() {
        _routePolyline        = roadPoints;
        _routeSource          = RouteSource.openRoute;
        _hasActiveRouteSession= true;
        _routeFitToken++;
        _routeLoading         = false;
        _currentRoute = RoutePlan(
          summary       : 'Itinéraire vers ${place.name}',
          duration      : realDuration,
          distance      : realDistance,
          avoidObstacles: _avoidObstacles,
          includesElevator: _includeElevators,
          source        : RouteSource.openRoute,
        );
      });

      if (roadResult.isBirdFlightOnly) {
        debugPrint('[ROUTE] Fallback vol d\'oiseau (OSRM/Valhalla indisponibles)');
        if (showSuccessSnack) {
          _maybeShowLocationSnack(
            'Tracé approximatif (ligne droite) : les services d’itinéraire en ligne ne répondent pas. '
            'Le tracé sur route réapparaîtra quand le réseau ou le serveur Ma3ak est joignable.',
          );
        }
      }

      // ══════════════════════════════════════════════════════════════════════
      //  ÉTAPE 2 — API Python (optionnelle, ne bloque plus l’UI : timeout court)
      // ══════════════════════════════════════════════════════════════════════
      AccessibleRouteResult aiResult;
      try {
        aiResult = await _accessibleRouteService
            .fetchAccessibleRoute(start: start, end: end)
            .timeout(const Duration(seconds: 18));
      } on TimeoutException catch (_) {
        debugPrint('[ROUTE] Enrichissement IA timeout — tracé étape 1 conservé');
        aiResult = AccessibleRouteResult.failure('timeout');
      }
      if (!mounted) return;

      final bool aiHasRealTrace = aiResult.isSuccess && aiResult.coordinates.length >= 12;
      final bool aiTraceFollowsRoads =
          !_isNearlyStraightLine(aiResult.coordinates);
      final bool useAiPolyline = aiHasRealTrace && aiTraceFollowsRoads;

      if (useAiPolyline) {
        final double aiDistM = aiResult.distanceMeters > 0 ? aiResult.distanceMeters : distMeters;
        final double aiDurS  = mode == TransportMode.apied && aiResult.durationSeconds > 0
            ? aiResult.durationSeconds
            : mode.estimateDurationSeconds(aiDistM);
        setState(() {
          _routePolyline   = aiResult.coordinates;   // tracé IA (suit les rues via OSRM interne)
          _routeSource     = RouteSource.pythonAI;
          _routeFitToken++;
          _currentRoute    = RoutePlan(
            summary        : 'Itinéraire accessible vers ${place.name}',
            duration       : _formatRouteDuration(aiDurS),
            distance       : _formatRouteDistance(aiDistM),
            avoidObstacles : _avoidObstacles,
            includesElevator: _includeElevators,
            source         : RouteSource.pythonAI,
            aiScore        : aiResult.accessibilityScore,
          );
        });
        debugPrint('[ROUTE] ✅ Tracé IA appliqué — ${aiResult.coordinates.length} pts, score=${aiResult.accessibilityScore}');
        if (showSuccessSnack) _maybeShowLocationSnack('Itinéraire accessible IA calculé.');
      } else {
        if (aiResult.isSuccess && aiResult.coordinates.length < 12) {
          debugPrint('[ROUTE] IA retourne ${aiResult.coordinates.length} pts (< 12) — tracé OSRM conservé');
        } else if (aiResult.isSuccess &&
            aiResult.coordinates.length >= 12 &&
            _isNearlyStraightLine(aiResult.coordinates)) {
          debugPrint('[ROUTE] Tracé IA trop rectiligne — polyline OSRM conservée');
        } else if (!aiResult.isSuccess) {
          debugPrint('[ROUTE] IA KO (${aiResult.errorMessage}) — tracé OSRM conservé');
        }
        if (showSuccessSnack) _maybeShowLocationSnack('Itinéraire calculé vers ${place.name}.');
      }
    } catch (e, st) {
      debugPrint('[ROUTE] Exception : $e\n$st');
      if (!mounted) return;
      setState(() {
        _routeLoading=false;
        _routeError='Erreur inattendue : $e';
        _routePolyline=null; _currentRoute=null; _hasActiveRouteSession=false;
      });
    }
  }

  // Ancienne méthode renommée pour compatibilité avec les boutons existants
  Future<void> _fetchRouteFromOpenRouteService({bool showSuccessSnack=true}) =>
      _fetchRoute(showSuccessSnack:showSuccessSnack);

  Color _scoreColor(int score) {
    if (score>=80) return const Color(0xFF2A9F58);
    if (score>=60) return const Color(0xFFE69D2A);
    return const Color(0xFFD24C4C);
  }

  void _toggleCategory(PlaceCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)&&_selectedCategories.length>1) _selectedCategories.remove(category);
      else _selectedCategories.add(category);
    });
    _scheduleLoadSelectedPlaceGeoInsights();
  }

  String _geoapifyCategoryFor(PlaceCategory category) {
    switch(category) {
      case PlaceCategory.hopital:       return 'healthcare.hospital';
      case PlaceCategory.administration:return 'service.public';
      case PlaceCategory.cafe:          return 'catering.restaurant';
      case PlaceCategory.commerce:      return 'commercial.supermarket';
      case PlaceCategory.transport:     return 'public_transport';
      case PlaceCategory.autre:         return 'tourism.sights';
    }
  }

  Future<void> _openReservationScreen(AccessiblePlace place) async {
    if (!mounted) return;
    await context.push<void>(
      '/reserve-access',
      extra: place.name,
    );
    if (!mounted) return;
    // Recharge l’historique local (le SnackBar de succès est sur [ReservationScreen]).
    setState(() => _reservationsReloadToken++);
  }

  void _downloadOfflineData() {
    if (!_offlineEnabled) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Active le mode hors ligne.'))); return; }
    setState((){_mapDownloaded=true;_routesDownloaded=true;_placesDownloaded=true;});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Zone telechargee.')));
  }

  void _closeAccessibilitySecondaryPanel() {
    setState(() {
      _selectedTab = 0;
      _isMapExpanded = false;
    });
  }

  void _openContributeAccessibilityPost(BuildContext context) {
    context.go(Uri(
      path: '/create-post',
      queryParameters: {'accessibilityContentHint': _accessibilityPostHintQuery},
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final places = _computeFilteredPlaces();
    if (!_placesLoading&&_placesLoadError==null) {
      if (_selectedPlace!=null&&places.isNotEmpty&&!places.contains(_selectedPlace)) {
        final next=places.first; final prevId=_selectedPlace!.id;
        if (!_selectionAlignScheduled) {
          _selectionAlignScheduled=true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectionAlignScheduled=false;
            if (!mounted) return;
            setState(()=>_selectedPlace=next);
            if (_hasActiveRouteSession&&_userLatLng!=null&&prevId!=next.id) unawaited(_fetchRoute(showSuccessSnack:false));
          });
        }
      }
    }
    final selected=_selectedPlace;
    return PopScope(
      // Toujours intercepter le retour système : sinon `canPop: true` peut dépiler
      // la mauvaise route (écran dans le shell) et faire planter l'app.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMapExpanded) {
          setState(() => _isMapExpanded = false);
          return;
        }
        if (_selectedTab != 0) {
          setState(() => _selectedTab = 0);
          return;
        }
        if (_selectedPlace != null && _showPlaceCardOnMap) {
          setState(() => _showPlaceCardOnMap = false);
          return;
        }
        if (_selectedPlace != null) {
          setState(() {
            _selectedPlace = null;
            _resetRouteStateFields();
          });
          return;
        }
        _safePopAccessibilityMap(context);
      },
      child:Scaffold(
        body:SafeArea(
          child:Padding(
            padding:_selectedTab==0&&_isMapExpanded?EdgeInsets.zero:const EdgeInsets.fromLTRB(10,8,10,0),
            child:Column(children:[
              if (_selectedTab==0&&!_isMapExpanded)
                const Align(alignment:Alignment.centerLeft,child:Padding(padding:EdgeInsets.only(left:4,bottom:6),
                  child:Text('Accessibility Map & Places',style:TextStyle(color:Color(0xFF6C7A89),fontSize:28,fontWeight:FontWeight.w600)))),
              Expanded(child:_placesLoading
                ? const Center(child:CircularProgressIndicator())
                : _placesLoadError!=null
                  ? Center(child:Padding(padding:const EdgeInsets.all(20),child:Text(_placesLoadError!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF6B7C8E),fontSize:15))))
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IndexedStack(
                          index: _selectedTab,
                          children: [
                            AccessibilityMapTabScreen(
                              searchController: _searchController,
                              selectedDisability: _selectedDisability,
                              onSelectDisability: (d) {
                                setState(() => _selectedDisability = d);
                                _scheduleLoadSelectedPlaceGeoInsights();
                              },
                              selectedCategories: _selectedCategories,
                              onToggleCategory: _toggleCategory,
                              isExpanded: _isMapExpanded,
                              onExpandMap: () => setState(() => _isMapExpanded = true),
                              onCollapseMap: () => setState(() => _isMapExpanded = false),
                              places: places,
                              selectedPlace: selected,
                              onSelectPlace: _setSelectedPlace,
                              onDismissPlaceCard: () => setState(() {
                                _showPlaceCardOnMap = false;
                              }),
                              onOpenPlaceCard: () => setState(() {
                                _showPlaceCardOnMap = true;
                              }),
                              onClearSelection: () => setState(() {
                                _selectedPlace = null;
                                _resetRouteStateFields();
                              }),
                              scoreColor: _scoreColor,
                              reportsForPlace: _placeReports,
                              photosForPlace: _placePhotos,
                              geoInsights: selected == null
                                  ? null
                                  : _geoInsightsByPlace[selected.id],
                              geoInsightsLoading: selected != null &&
                                  _geoLoadingByPlace.contains(selected.id),
                              geoEnabled: _geoapifyPlacesService.isEnabled,
                              onReserve: selected == null
                                  ? null
                                  : () => _openReservationScreen(selected),
                              onOpenReservationsHistory: () =>
                                  context.push('/reservations-history'),
                              onOpenRoute: () {
                                setState(() {
                                  _selectedTab = 1;
                                  _showPlaceCardOnMap = true;
                                });
                                unawaited(_fetchRoute());
                              },
                              showPlaceCard: _showPlaceCardOnMap,
                              userLocation: _userLatLng,
                              locationSetupComplete: _locationSetupComplete,
                              myLocationRecenterSignal: _myLocationRecenterSignal,
                              onMyLocationPressed: _onMyLocationFabPressed,
                              routePolyline: _routePolyline,
                              routeFitToken: _routeFitToken,
                              aiResult: _aiResult,
                              aiLoading: _aiLoading,
                            ),
                            Scaffold(
                              appBar: AppBar(
                                leading: BackButton(
                                  onPressed: _closeAccessibilitySecondaryPanel,
                                ),
                                title: const Text('Itinéraire accessible'),
                              ),
                              body: AccessibilityItineraryTabScreen(
                                selectedPlace: selected,
                                offlineEnabled: _offlineEnabled,
                                mapDownloaded: _mapDownloaded,
                                routesDownloaded: _routesDownloaded,
                                placesDownloaded: _placesDownloaded,
                                avoidObstacles: _avoidObstacles,
                                includeElevators: _includeElevators,
                                currentRoute: _currentRoute,
                                routeLoading: _routeLoading,
                                routeError: _routeError,
                                openRouteConfigured:
                                    _openRouteDirectionsService.isConfigured,
                                selectedTransportMode: _selectedTransportMode,
                                onTransportModeChange: (m) {
                                  setState(() {
                                    _selectedTransportMode = m;
                                    _currentRoute = null;
                                    _routePolyline = null;
                                    _routeError = null;
                                  });
                                  if (_selectedPlace != null) {
                                    unawaited(_fetchRoute(showSuccessSnack: false));
                                  }
                                },
                                onOfflineToggle: (v) => setState(() => _offlineEnabled = v),
                                onAvoidObstaclesToggle: (v) {
                                  setState(() {
                                    _avoidObstacles = v;
                                    _currentRoute = null;
                                    _routePolyline = null;
                                    _routeError = null;
                                  });
                                  if (_selectedPlace != null) {
                                    unawaited(_fetchRoute(showSuccessSnack: false));
                                  }
                                },
                                onIncludeElevatorToggle: (v) =>
                                    setState(() => _includeElevators = v),
                                onDownloadOffline: _downloadOfflineData,
                                onBuildRoute: () => unawaited(_fetchRoute()),
                                onViewOnMap: _currentRoute == null
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedTab = 0;
                                          _showPlaceCardOnMap = false;
                                          if (_routePolyline != null &&
                                              _routePolyline!.length >= 2) {
                                            _routeFitToken++;
                                          }
                                        });
                                      },
                                onStartNavigation: (_currentRoute == null ||
                                        _selectedPlace == null)
                                    ? null
                                    : () {
                                        setState(() {
                                          _navigationActive = true;
                                          _navStepIndex = 0;
                                          _navProgressFraction = 0.0;
                                          _navDistanceRemaining =
                                              _routePolyline != null
                                                  ? () {
                                                      double d = 0;
                                                      final pts = _routePolyline!;
                                                      for (int i = 0;
                                                          i < pts.length - 1;
                                                          i++) {
                                                        d += _haversineMeters(
                                                            pts[i], pts[i + 1]);
                                                      }
                                                      return d;
                                                    }()
                                                  : 0.0;
                                          _navDurationRemaining =
                                              _selectedTransportMode
                                                  .estimateDurationSeconds(
                                                      _navDistanceRemaining);
                                          _navClosestPointIndex = 0;
                                          _selectedTab = 0;
                                          _showPlaceCardOnMap = false;
                                          _isMapExpanded = true;
                                        });
                                      },
                              ),
                            ),
                            Scaffold(
                              appBar: AppBar(
                                leading: BackButton(
                                  onPressed: _closeAccessibilitySecondaryPanel,
                                ),
                                title: const Text('Réservations'),
                              ),
                              body: ReservationsHistoryScreen(
                                key: ValueKey(_reservationsReloadToken),
                                embedded: true,
                              ),
                            ),
                          ],
                        ),
                        if (_navigationActive &&
                            _currentRoute != null &&
                            selected != null &&
                            _selectedTab == 0)
                          _NavigationOverlay(
                            route: _currentRoute!,
                            destination: selected,
                            mode: _selectedTransportMode,
                            routePolyline: _routePolyline ?? [],
                            userLocation: _userLatLng,
                            progressFraction: _navProgressFraction,
                            distanceRemaining: _navDistanceRemaining,
                            durationRemaining: _navDurationRemaining,
                            closestPointIndex: _navClosestPointIndex,
                            onStop: () => setState(() {
                              _navigationActive = false;
                              _showPlaceCardOnMap = true;
                              _isMapExpanded = false;
                            }),
                          ),
                        if (_selectedTab == 0 &&
                            !_navigationActive &&
                            !_placesLoading &&
                            _placesLoadError == null)
                          Positioned(
                            right: 12,
                            bottom: kBottomNavigationBarHeight +
                                MediaQuery.paddingOf(context).bottom +
                                12,
                            child: FloatingActionButton.extended(
                              heroTag: 'btn_accessibility_contribute',
                              onPressed: () =>
                                  _openContributeAccessibilityPost(context),
                              backgroundColor: const Color(0xFF1B5E20),
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                'Contribuer',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    )),
            ]),
          ),
        ),
      ),
    );
  }
}
