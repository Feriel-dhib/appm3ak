import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accompaniment/screens/emergency_contacts_screen.dart';
import '../features/accompaniment/screens/my_accompagnants_relations_screen.dart';
import '../features/accompaniment/screens/my_handicapes_relations_screen.dart';
import '../features/accompaniment/screens/transport_requests_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/accessibility/accessibility_post_handoff.dart';
import '../features/accessibility/head_gesture_post_screen.dart';
import '../features/accessibility/vibration_coded_post_screen.dart';
import '../features/accessibility/voice_vibration_post_screen.dart';
import '../features/community/screens/chat_screen.dart';
import '../features/community/screens/community_ai_entry_screen.dart';
import '../features/community/screens/community_contacts_route_screen.dart';
import '../features/community/screens/community_live_screen.dart';
import '../features/community/screens/community_locations_screen.dart';
import '../features/community/screens/community_main_screen.dart';
import '../features/community/screens/community_nearby_places_screen.dart';
import '../features/community/screens/create_help_request_screen.dart';
import '../features/community/screens/create_post_screen.dart';
import '../features/community/screens/haptic_help_screen.dart';
import '../features/community/screens/help_request_detail_screen.dart';
import '../features/community/screens/location_detail_screen.dart';
import '../features/community/screens/messages_screen.dart';
import '../features/community/screens/post_detail_screen.dart';
import '../features/community/screens/submit_location_screen.dart';
import '../features/community/services/post_detail_assistance/post_detail_assistance_models.dart';
import '../data/models/community_action_plan_result.dart';
import '../data/models/help_request_model.dart';
import '../data/models/post_model.dart';
import '../m3ak_assist/m3ak_create_post_launch.dart';
import '../m3ak_assist/m3ak_nav_key.dart';
import '../features/notifications/screens/notifications_list_screen.dart';
import '../features/sos/screens/sos_alerts_screen.dart';
import '../features/sos/screens/sos_for_accompagnant_screen.dart';
import '../features/sos/screens/sos_medical_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/accessibility/screens/conversation_captions_screen.dart';
import '../features/accessibility/screens/reservation_screen.dart';
import '../features/accessibility/screens/reservations_history_screen.dart';
import '../features/accessible_places/screens/accessible_places_screen.dart';
import '../air_writing/air_writing_page.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/profile_tab.dart';
import '../features/vehicles/screens/my_vehicles_screen.dart';
import '../features/vehicles/screens/vehicle_form_screen.dart';
import '../features/vehicles/screens/vehicle_detail_screen.dart';
import '../features/reservations/screens/vehicle_reservation_list_screen.dart';
import '../features/reservations/screens/vehicle_reservation_form_screen.dart';
import '../features/reservations/screens/vehicle_reservation_detail_screen.dart';
import '../features/transport/screens/adapted_vehicles_screen.dart';
import '../features/transport/screens/transport_map_screen.dart';
import '../features/transport/screens/transport_request_screen.dart';
import '../features/transport/screens/transport_history_screen.dart';
import '../features/transport/screens/transport_detail_screen.dart';
import '../features/transport/screens/transport_suivi_screen.dart';
import '../features/transport/screens/transport_my_requests_screen.dart';
import '../features/transport/screens/transport_dynamic_screen.dart';
import '../features/transport/screens/transport_hub_screen.dart';
import '../features/transport/screens/driver_active_ride_screen.dart';
import '../features/navigation_ar/screens/guided_ar_navigation_screen.dart';
import '../features/navigation_ar/screens/obstacle_navigation_hub_screen.dart';
import '../core/l10n/app_strings.dart';
import '../features/detection/screens/obstacle_detection_screen.dart';
import '../features/health/models/health_chat_launch.dart';
import '../features/health/screens/health_ai_chat_screen.dart';
import '../features/learning/learning_entry_screen.dart';
import '../features/learning/screens/face_recognition_screen.dart';
import '../features/medical/screens/activity_posture_detection_screen.dart';
import '../features/medical/screens/companion_medical_records_screen.dart';
import '../features/medical/screens/medical_document_detail_screen.dart';
import '../features/medical/screens/medical_documents_scanner_screen.dart';
import '../features/medical/screens/medical_emergency_card_screen.dart';
import '../features/medical/screens/medical_qr_scan_screen.dart';
import '../features/medical/screens/medical_record_screen.dart';
import '../features/medical/screens/medical_shared_open_screen.dart';
import '../data/models/user_model.dart';
import '../providers/auth_providers.dart';

bool _isBlindBeneficiary(UserModel? user) {
  if (user == null || !user.isBeneficiary) return false;
  final raw = user.typeHandicap?.toLowerCase().trim() ?? '';
  return raw.contains('visuel') ||
      raw.contains('malvoy') ||
      raw.contains('blind') ||
      raw.contains('aveugle');
}

/// Paramètres optionnels sur `/create-post?…` (lieu pré-lié, retour Communauté).
class _CreatePostDeepLink {
  const _CreatePostDeepLink({
    required this.lat,
    required this.lng,
    required this.prefillPlace,
    required this.goCommunityHub,
    required this.placeSeed,
    required this.queryHint,
  });

  factory _CreatePostDeepLink.from(GoRouterState state) {
    final q = state.uri.queryParameters;
    final lat = double.tryParse(q['lat'] ?? '');
    final lng = double.tryParse(q['lng'] ?? '');
    final prefill =
        q['bindLocation'] == '1' && lat != null && lng != null;
    final goHub = q['returnTo'] == 'community-hub';
    final name = q['placeName']?.trim();
    final city = q['placeCity']?.trim();
    String? seed;
    if (name != null && name.isNotEmpty) {
      seed = city != null && city.isNotEmpty ? '$name ($city) : ' : '$name : ';
    }
    final h1 = q['accessibilityContentHint']?.trim();
    final h2 = q['contentHint']?.trim();
    final qh = (h1 != null && h1.isNotEmpty)
        ? h1
        : (h2 != null && h2.isNotEmpty ? h2 : null);
    return _CreatePostDeepLink(
      lat: lat,
      lng: lng,
      prefillPlace: prefill,
      goCommunityHub: goHub,
      placeSeed: seed,
      queryHint: qh,
    );
  }

  final double? lat;
  final double? lng;
  final bool prefillPlace;
  final bool goCommunityHub;
  final String? placeSeed;
  final String? queryHint;
}

PostType? _createPostMergedInitialType(
  GoRouterState state,
  PostType? fromParent,
  _CreatePostDeepLink deep,
) {
  if (fromParent != null) return fromParent;
  final parsed = PostType.fromString(state.uri.queryParameters['postType']);
  if (parsed != null) return parsed;
  if (deep.placeSeed != null) return PostType.temoignage;
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: m3akRootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/sante', redirect: (_, __) => '/home?tab=1'),
      GoRoute(
        path: '/home',
        builder: (c, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          final communityTab =
              int.tryParse(state.uri.queryParameters['communityTab'] ?? '') ?? 0;
          return MainShell(
            initialIndex: tab.clamp(0, 4),
            initialCommunityTabIndex: communityTab.clamp(0, 2),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileTab(showLeadingBack: true),
      ),
      GoRoute(
        path: '/community',
        builder: (_, __) => const CommunityMainScreen(),
      ),
      GoRoute(
        path: '/community-locations',
        builder: (_, __) => const CommunityLocationsScreen(),
      ),
      GoRoute(
        path: '/community-nearby',
        builder: (_, __) =>
            const CommunityNearbyPlacesScreen(embedded: false),
      ),
      GoRoute(
        path: '/community-contacts',
        builder: (_, __) => const CommunityContactsRouteScreen(),
      ),
      GoRoute(
        path: '/community-ai-entry',
        builder: (_, __) => const CommunityAiEntryScreen(),
      ),
      GoRoute(
        path: '/location-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LocationDetailScreen(locationId: id);
        },
      ),
      GoRoute(
        path: '/submit-location',
        builder: (_, __) => const SubmitLocationScreen(),
      ),
      GoRoute(
        path: '/community-posts',
        redirect: (_, state) {
          final q = state.uri.queryParameters;
          final buf = StringBuffer('/home?tab=4&communityTab=0');
          for (final e in q.entries) {
            if (e.key == 'tab' || e.key == 'communityTab') continue;
            buf
              ..write('&')
              ..write(e.key)
              ..write('=')
              ..write(Uri.encodeComponent(e.value));
          }
          return buf.toString();
        },
      ),
      GoRoute(
        path: '/community-live',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          final postId = q['postId'];
          final isHost = q['host'] == '1';
          return CommunityLiveScreen(postId: postId, isHost: isHost);
        },
      ),
      GoRoute(
        path: '/messages',
        builder: (_, __) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final name = state.uri.queryParameters['name'];
          return ChatScreen(userId: userId, userName: name);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (_, state) {
          final deep = _CreatePostDeepLink.from(state);
          final hintParam =
              state.uri.queryParameters['accessibilityContentHint']?.trim();
          final hint = (hintParam != null && hintParam.isNotEmpty)
              ? hintParam
              : deep.queryHint;
          final extra = state.extra;
          if (extra is M3akCreatePostLaunch) {
            return CreatePostScreen(
              initialContent: extra.initialContent,
              autoOpenCamera: extra.autoOpenCamera,
              autoPublishAfterCamera: extra.autoPublishAfterCamera,
              accessibilityAnnounceGalleryVolumeOrCameraFallback:
                  extra.accessibilityAnnounceGalleryVolumeOrCameraFallback,
              contentHintOverride: hint,
              prefillPlaceCoordinates: deep.prefillPlace,
              initialLatitude: deep.lat,
              initialLongitude: deep.lng,
              goToCommunityHubAfterSubmit: deep.goCommunityHub,
              initialPostType: _createPostMergedInitialType(state, null, deep),
            );
          }
          if (extra is AccessibilityPostHandoff) {
            return CreatePostScreen(
              initialAccessibilityHandoff: extra,
              contentHintOverride: hint,
              prefillPlaceCoordinates: deep.prefillPlace,
              initialLatitude: deep.lat,
              initialLongitude: deep.lng,
              goToCommunityHubAfterSubmit: deep.goCommunityHub,
              initialPostType: _createPostMergedInitialType(
                state,
                extra.suggestedPostType,
                deep,
              ),
            );
          }
          if (extra is CommunityActionPlanResult) {
            return CreatePostScreen(
              initialAiPlan: extra,
              contentHintOverride: hint,
              prefillPlaceCoordinates: deep.prefillPlace,
              initialLatitude: deep.lat,
              initialLongitude: deep.lng,
              goToCommunityHubAfterSubmit: deep.goCommunityHub,
              initialPostType: _createPostMergedInitialType(state, null, deep),
            );
          }
          final initial = extra is String ? extra : null;
          final mergedInitial = (initial?.trim().isNotEmpty ?? false)
              ? initial!.trim()
              : deep.placeSeed;
          return CreatePostScreen(
            initialContent: mergedInitial,
            contentHintOverride: hint,
            prefillPlaceCoordinates: deep.prefillPlace,
            initialLatitude: deep.lat,
            initialLongitude: deep.lng,
            goToCommunityHubAfterSubmit: deep.goCommunityHub,
            initialPostType: _createPostMergedInitialType(state, null, deep),
          );
        },
      ),
      GoRoute(
        path: '/create-post-head-gesture',
        builder: (_, __) => const HeadGesturePostScreen(),
      ),
      GoRoute(
        path: '/create-post-vibration',
        builder: (_, __) => const VibrationCodedPostScreen(),
      ),
      GoRoute(
        path: '/create-post-voice-vibration',
        builder: (_, __) => const VoiceVibrationPostScreen(),
      ),
      GoRoute(
        path: '/post-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final q = state.uri.queryParameters;
          final autoReadPost = q['autoReadPost'] == '1';
          final autoReadComments = q['autoReadComments'] == '1';
          final autoReadSummary = q['autoReadSummary'] == '1';
          final mode = q['mode'];
          final audioSelectionMode =
              (mode == 'readPost' || mode == 'readComments' || mode == 'voiceComment')
                  ? mode
                  : null;
          return PostDetailScreen(
            postId: id,
            autoReadPost: autoReadPost,
            autoReadComments: autoReadComments,
            autoReadSummary: autoReadSummary,
            audioSelectionMode: audioSelectionMode,
          );
        },
      ),
      GoRoute(
        path: '/community/post-detail/:postId',
        redirect: (_, state) {
          final id = state.pathParameters['postId'] ?? '';
          return '/post-detail/$id';
        },
      ),
      GoRoute(
        path: '/help-request-detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is HelpRequestModel) {
            return HelpRequestDetailScreen(request: extra);
          }
          return Scaffold(
            appBar: AppBar(title: Text(AppStrings.fr().helpRequestDetailTitle)),
            body: Center(child: Text(AppStrings.fr().errorGeneric)),
          );
        },
      ),
      GoRoute(
        path: '/create-help-request',
        builder: (_, state) {
          final extra = state.extra;
          return CreateHelpRequestScreen(
            initialPrefill:
                extra is HelpRequestFromPostPrefill ? extra : null,
            initialAiPlan:
                extra is CommunityActionPlanResult ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/help-requests',
        redirect: (_, __) => '/home?tab=4&communityTab=2',
      ),
      GoRoute(
        path: '/haptic-help',
        builder: (_, __) => const HapticHelpScreen(),
      ),
      GoRoute(path: '/profile-edit', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/accompagnants',
        builder: (_, __) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/relations/accompagnants',
        builder: (_, __) => const MyAccompagnantsRelationsScreen(),
      ),
      GoRoute(
        path: '/relations/handicapes',
        builder: (_, __) => const MyHandicapesRelationsScreen(),
      ),
      GoRoute(
        path: '/beneficiaires',
        builder: (_, __) => const TransportRequestsScreen(),
      ),
      GoRoute(path: '/sos-alerts', builder: (_, __) => const SosAlertsScreen()),
      GoRoute(
        path: '/sos-alerts/accompagnant',
        builder: (_, __) => const SosForAccompagnantScreen(),
      ),
      GoRoute(
        path: '/sos-medical',
        builder: (_, __) => const SosMedicalScreen(),
      ),
      GoRoute(
        path: '/medical-record',
        builder: (_, __) => const MedicalRecordScreen(),
      ),
      GoRoute(
        path: '/medical-emergency-card',
        builder: (_, __) => const MedicalEmergencyCardScreen(),
      ),
      GoRoute(
        path: '/medical-scan-qr',
        builder: (_, __) => const MedicalQrScanScreen(),
      ),
      GoRoute(
        path: '/medical-documents',
        builder: (_, __) => const MedicalDocumentsScannerScreen(),
      ),
      GoRoute(
        path: '/medical-document/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return MedicalDocumentDetailScreen(documentId: id);
        },
      ),
      GoRoute(
        path: '/medical-linked-records',
        builder: (_, __) => const CompanionMedicalRecordsScreen(),
      ),
      GoRoute(
        path: '/open/meddoc/:token',
        builder: (_, state) {
          final token = state.pathParameters['token']!;
          return MedicalSharedOpenScreen(token: token);
        },
      ),
      GoRoute(
        path: '/activity-posture-detection',
        builder: (_, __) => const ActivityPostureDetectionScreen(),
      ),
      GoRoute(
        path: '/health-chat',
        builder: (context, state) {
          final extra = state.extra;
          String? initial;
          if (extra is HealthChatLaunch) {
            initial = extra.initialMessage;
          } else if (extra is String) {
            initial = extra;
          }
          return Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authStateProvider);
              return auth.when(
                data: (user) {
                  if (user == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) context.go('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final strings = AppStrings.fromPreferredLanguage(
                    user.preferredLanguage?.name,
                  );
                  final launchUser = extra is HealthChatLaunch
                      ? extra.user
                      : null;
                  return HealthAiChatScreen(
                    strings: strings,
                    initialUserMessage: initial,
                    userProfile: launchUser ?? user,
                  );
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Scaffold(
                  body: Center(child: Text(AppStrings.fr().errorGeneric)),
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsListScreen(),
      ),
      GoRoute(path: '/vehicles', builder: (_, __) => const MyVehiclesScreen()),
      GoRoute(
        path: '/vehicles/new',
        builder: (_, __) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return VehicleFormScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/transport/hub',
        builder: (_, __) => const TransportHubScreen(),
      ),
      GoRoute(
        path: '/transport/obstacle-navigation-hub',
        builder: (_, __) => Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authStateProvider).valueOrNull;
            if (!_isBlindBeneficiary(user)) {
              return Scaffold(
                appBar: AppBar(title: const Text('Accès restreint')),
                body: const Center(
                  child: Text(
                    'Le guidage obstacles est réservé aux bénéficiaires mal-voyants.',
                  ),
                ),
              );
            }
            return const ObstacleNavigationHubScreen();
          },
        ),
      ),
      GoRoute(
        path: '/transport/obstacle-detection',
        builder: (_, __) => Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authStateProvider).valueOrNull;
            if (!_isBlindBeneficiary(user)) {
              return Scaffold(
                appBar: AppBar(title: const Text('Accès restreint')),
                body: const Center(
                  child: Text(
                    'La détection d’obstacles est réservée aux bénéficiaires mal-voyants.',
                  ),
                ),
              );
            }
            return const ObstacleDetectionScreen();
          },
        ),
      ),
      GoRoute(
        path: '/transport/obstacle-guided-ar',
        builder: (_, __) => Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authStateProvider).valueOrNull;
            if (!_isBlindBeneficiary(user)) {
              return Scaffold(
                appBar: AppBar(title: const Text('Accès restreint')),
                body: const Center(
                  child: Text(
                    'Le guidage obstacles est réservé aux bénéficiaires mal-voyants.',
                  ),
                ),
              );
            }
            return const GuidedArNavigationScreen();
          },
        ),
      ),
      GoRoute(
        path: '/transport/dynamic',
        builder: (_, __) => const TransportDynamicScreen(),
      ),
      GoRoute(
        path: '/transport/map',
        builder: (_, __) => const TransportMapScreen(),
      ),
      GoRoute(
        path: '/transport/vehicles',
        builder: (_, __) => const AdaptedVehiclesScreen(),
      ),
      GoRoute(
        path: '/transport/request',
        builder: (_, __) => const TransportRequestScreen(),
      ),
      GoRoute(
        path: '/transport/history',
        builder: (_, __) => const TransportHistoryScreen(),
      ),
      GoRoute(
        path: '/transport/my-requests',
        builder: (_, __) => const TransportMyRequestsScreen(),
      ),
      GoRoute(
        path: '/transport/:id/suivi',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          final token = state.uri.queryParameters['token'];
          return TransportSuiviScreen(transportId: id, shareToken: token);
        },
      ),
      GoRoute(
        path: '/transport/chauffeur/:rideId',
        builder: (_, state) {
          final rideId = state.pathParameters['rideId']!;
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).valueOrNull;
              if (user == null || !user.isChauffeurSolidaire) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Accès restreint')),
                  body: const Center(
                    child: Text('Réservé aux chauffeurs solidaires.'),
                  ),
                );
              }
              return DriverActiveRideScreen(rideId: rideId);
            },
          );
        },
      ),
      GoRoute(
        path: '/transport/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return TransportDetailScreen(transportId: id);
        },
      ),
      GoRoute(
        path: '/vehicle-reservations',
        builder: (_, __) => const VehicleReservationListScreen(),
      ),
      GoRoute(
        path: '/vehicle-reservations/new',
        builder: (_, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return VehicleReservationFormScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/vehicle-reservations/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return VehicleReservationDetailScreen(reservationId: id);
        },
      ),
      GoRoute(
        path: '/learning',
        builder: (_, __) => const LearningEntryScreen(),
      ),
      GoRoute(
        path: '/learning/ia1-companion',
        builder: (_, __) => const FaceRecognitionScreen(),
      ),
      GoRoute(path: '/air-writing', builder: (_, __) => const AirWritingPage()),
      GoRoute(
        path: '/accessibility/conversation-captions',
        builder: (_, __) => const ConversationCaptionsScreen(),
      ),
      GoRoute(
        path: '/accessible-places',
        builder: (_, __) => const AccessiblePlacesScreen(),
      ),
      GoRoute(
        path: '/reservations-history',
        builder: (_, __) => const ReservationsHistoryScreen(embedded: false),
      ),
      GoRoute(
        path: '/reserve-access',
        builder: (_, state) {
          final placeName = state.extra as String? ?? '';
          return ReservationScreen(placeName: placeName);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page non trouvée: ${state.uri}'))),
  );
});
