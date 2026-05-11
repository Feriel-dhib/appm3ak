/// Endpoints de la nouvelle API Ma3ak.
class Endpoints {
  Endpoints._();

  // ——— Auth ———
  static const String authLogin = '/auth/login';
  static const String authGoogle = '/auth/google';
  static const String authConfigTest = '/auth/config-test';

  // ——— User ———
  /// Inscription : `POST /users/register` (le backend ne monte pas `/user/register` ni `/auth/register`).
  static const String userRegister = '/users/register';
  // Le backend NestJS expose les routes au **pluriel** (`/users/...`). Une
  // version antérieure utilisait `/user/me` qui renvoyait 404 (`Cannot GET /user/me`).
  static const String userMe = '/users/me';
  static const String userMeLocation = '/users/me/location';
  static const String userMePhoto = '/users/me/photo';

  /// Animal d’assistance (NestJS : `PUT /users/animal`).
  static const String usersAnimal = '/users/animal';

  // ——— Dossier médical (HANDICAPE) ———
  static const String medicalRecords = '/medical-records';
  static const String medicalRecordsMe = '/medical-records/me';
  static const String medicalRecordsPublishQr =
      '/medical-records/me/publish-qr';
  static const String medicalRecordsForAccompagnant =
      '/medical-records/for-accompagnant';

  /// Documents médicaux numérisés (upload + partage QR cloud).
  static const String medicalDocuments = '/medical-documents';
  static String medicalDocumentShare(String shareToken) =>
      '/medical-documents/share/$shareToken';

  /// Chat santé IA (OpenAI côté serveur si configuré).
  static const String healthChat = '/health/chat';

  /// Alerte vocale (stress / danger) + matching contact → numéro à composer.
  static const String safetyVoiceEmergency = '/safety/voice-emergency';

  // ——— Alertes SOS ———
  static const String sosAlerts = '/sos-alerts';
  static const String sosAlertsMe = '/sos-alerts/me';
  static const String sosAlertsForAccompagnant = '/sos-alerts/for-accompagnant';
  static String sosAlertsNearby(double lat, double lng) =>
      '/sos-alerts/nearby?latitude=$lat&longitude=$lng';
  static String sosAlertById(String id) => '/sos-alerts/$id';
  static String sosAlertNotifyNext(String id) => '/sos-alerts/$id/notify-next';
  static String sosAlertStatut(String id) => '/sos-alerts/$id/statut';
  static String sosAlertRespond(String id) => '/sos-alerts/$id/respond';

  // ——— Contacts urgence ———
  static const String emergencyContacts = '/emergency-contacts';
  static const String emergencyContactsMe = '/emergency-contacts/me';
  static const String emergencyContactsLinkByPhone =
      '/emergency-contacts/link-by-phone';
  static String emergencyContactId(String id) => '/emergency-contacts/$id';

  // ——— Relations (handicapé–accompagnant, many-to-many) ———
  static const String relations = '/relations';
  static const String relationsMe = '/relations/me';
  static const String relationsMeAccompagnants = '/relations/me/accompagnants';
  static const String relationsMeHandicapes = '/relations/me/handicapes';
  static String relationById(String id) => '/relations/$id';
  static String relationAccept(String id) => '/relations/$id/accept';

  // ——— Transport ———
  static const String transport = '/transport';
  static String transportById(String id) => '/transport/$id';
  static String transportAccept(String id) => '/transport/$id/accept';
  static String transportCancel(String id) => '/transport/$id/cancel';
  static String transportTermine(String id) => '/transport/$id/termine';
  static String transportStatut(String id) => '/transport/$id/statut';
  static String transportEta(String id) => '/transport/$id/eta';
  static String transportSuivi(String id) => '/transport/$id/suivi';
  static String transportSuiviPublic(String id) =>
      '/transport/$id/suivi/public';
  static String transportEtaPublic(String id) => '/transport/$id/eta/public';
  static String transportShare(String id) => '/transport/$id/share';
  static String transportMatchingCandidates(String id) =>
      '/transport/$id/matching-candidates';
  static String transportPriceEstimate(String id) =>
      '/transport/$id/price-estimate';
  static const String transportMatchingPath = '/transport/matching';
  static String transportHistory({required int page, required int limit}) =>
      '/transport/history?page=$page&limit=$limit';

  /// Matching : latitude, longitude, optionnel typeHandicap, urgence, rayonKm, besoinsAssistance
  static String transportMatching({
    required double latitude,
    required double longitude,
    String? typeHandicap,
    bool? urgence,
    double? rayonKm,
    List<String>? besoinsAssistance,
  }) {
    final buf = StringBuffer(
      '/transport/matching?latitude=$latitude&longitude=$longitude',
    );
    if (typeHandicap != null && typeHandicap.isNotEmpty) {
      buf.write('&typeHandicap=${Uri.encodeComponent(typeHandicap)}');
    }
    if (urgence == true) buf.write('&urgence=true');
    if (rayonKm != null && rayonKm > 0) buf.write('&rayonKm=$rayonKm');
    if (besoinsAssistance != null) {
      for (final b in besoinsAssistance) {
        if (b.isEmpty) continue;
        buf.write('&besoinsAssistance=${Uri.encodeComponent(b)}');
      }
    }
    return buf.toString();
  }

  static const String transportMe = '/transport/me';
  static const String transportAvailable = '/transport/available';

  // ——— Évaluations transport ———
  static String transportReviewsByTransportId(String transportId) =>
      '/transport-reviews/transport/$transportId';

  // ——— Lieux accessibles ———
  static const String lieux = '/lieux';
  static String lieuxNearby(double lat, double lng, [double? maxDistance]) {
    final q = 'latitude=$lat&longitude=$lng';
    return maxDistance != null
        ? '/lieux/nearby?$q&maxDistance=$maxDistance'
        : '/lieux/nearby?$q';
  }

  static String lieuById(String id) => '/lieux/$id';

  // ——— Réservations lieux ———
  static const String lieuReservations = '/lieu-reservations';
  static const String lieuReservationsMe = '/lieu-reservations/me';
  static String lieuReservationStatut(String id) =>
      '/lieu-reservations/$id/statut';

  // ——— Communauté ———
  static const String communityPosts = '/community/posts';
  static const String communityPostsForMe = '/community/posts/for-me';
  static String communityPostById(String id) => '/community/posts/$id';
  static String communityPostMerci(String id) => '/community/posts/$id/merci';
  static String communityPostMerciState(String id) =>
      '/community/posts/$id/merci/state';
  static String communityPostValidateObstacle(String id) =>
      '/community/posts/$id/validate-obstacle';
  static String communityPostComments(String postId) =>
      '/community/posts/$postId/comments';
  static String communityPostCommentById(String postId, String commentId) =>
      '/community/posts/$postId/comments/$commentId';
  static String communityPostCommentsFlashSummary(String postId) =>
      '/community/posts/$postId/comments/flash-summary';
  static const String communityAiActionPlan = '/community/ai/action-plan';

  /// Optionnel — si le backend expose `/ai/community/*` (voir `AppConfig.aiCommunityRemoteEnabled`).
  static const String aiCommunitySummarizePost = '/ai/community/summarize-post';
  static const String aiCommunitySummarizeComments =
      '/ai/community/summarize-comments';
  static const String aiCommunityPostToHelpRequest =
      '/ai/community/post-to-help-request';

  static const String communityHelpRequests = '/community/help-requests';
  static String communityHelpRequestAccept(String id) =>
      '/community/help-requests/$id/accept';
  static String communityHelpRequestStatut(String id) =>
      '/community/help-requests/$id/statut';

  // ——— Éducation ———
  static const String educationModules = '/education/modules';
  static String educationModuleById(String id) => '/education/modules/$id';
  static const String educationProgress = '/education/progress';

  // ——— Notifications ———
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // ——— Véhicules ———
  static const String vehicles = '/vehicles';
  static String vehicleById(String id) => '/vehicles/$id';
  static String vehiclesByOwner(String ownerId) => '/vehicles/owner/$ownerId';

  // ——— Réservations de véhicules ———
  static const String vehicleReservations = '/vehicle-reservations';
  static const String vehicleReservationsMe = '/vehicle-reservations/me';
  static String vehicleReservationsByVehicle(String vehicleId) =>
      '/vehicle-reservations/vehicle/$vehicleId';
  static String vehicleReservationById(String id) =>
      '/vehicle-reservations/$id';
  static String vehicleReservationStatut(String id) =>
      '/vehicle-reservations/$id/statut';

  /// Évaluation après trajet (véhicule + chauffeur).
  static String vehicleReservationReview(String id) =>
      '/vehicle-reservations/$id/review';

  // ——— Map (géocodage, itinéraires — sans JWT) ———
  static const String mapGeocode = '/map/geocode';
  static const String mapReverseGeocode = '/map/reverse-geocode';
  static const String mapRoute = '/map/route';

  // ——— Accessibilité & Lieux accessibles (module IA Groq + OSM) ———
  // Nouveaux endpoints préfixés /accessibility/*, avec fallback racine pour
  // compatibilité avec la version Python standalone du module.
  static const String accessibilityHealth = '/accessibility/health';
  static const String accessibilityOsmTags = '/accessibility/osm-tags';
  static const String accessibilityAnalyze = '/accessibility/analyze';
  static const String accessibilityNearestNode = '/accessibility/nearest_node';
  static const String accessibilityRouteFull =
      '/accessibility/accessible_route_full';

  /// Alias racine — utilisés en fallback si /accessibility/* renvoie 404.
  static const String accessibilityHealthLegacy = '/health';
  static const String accessibilityOsmTagsLegacy = '/osm-tags';
  static const String accessibilityAnalyzeLegacy = '/analyze';
  static const String accessibilityNearestNodeLegacy = '/nearest_node';
  static const String accessibilityRouteFullLegacy = '/accessible_route_full';
}
