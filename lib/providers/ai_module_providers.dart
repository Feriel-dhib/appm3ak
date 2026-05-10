import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/api/ai_module_api_client.dart';
import '../data/models/ai/adapt_models.dart';
import '../data/models/user_model.dart';
import '../data/repositories/ai_module_repository.dart';
import '../data/services/ai_module_service.dart';

final aiModuleApiClientProvider = Provider<AiModuleApiClient>((ref) {
  return AiModuleApiClient();
});

final aiModuleSecondaryApiClientProvider = Provider<AiModuleApiClient?>((ref) {
  final secondary = AppConfig.aiModuleSecondaryBaseUrl;
  if (secondary == null || secondary.trim().isEmpty) return null;
  return AiModuleApiClient(baseUrl: secondary.trim());
});

final aiModuleRepositoryProvider = Provider<AiModuleRepository>((ref) {
  return AiModuleRepository(
    apiClient: ref.watch(aiModuleApiClientProvider),
    secondaryApiClient: ref.watch(aiModuleSecondaryApiClientProvider),
  );
});

final aiModuleServiceProvider = Provider<AiModuleService>((ref) {
  return AiModuleService(ref.watch(aiModuleRepositoryProvider));
});

final aiModuleHealthProvider = FutureProvider<bool>((ref) async {
  return ref.watch(aiModuleRepositoryProvider).isHealthy();
});

final aiInteractionModeProvider =
    FutureProvider.family<AiInteractionMode, UserModel>((ref, user) async {
      final userType = resolveAiUserType(user);
      if (userType == null) {
        return AiInteractionMode.textMode;
      }
      try {
        final response = await ref
            .watch(aiModuleRepositoryProvider)
            .adaptForUserType(userType);
        return response.mode;
      } catch (_) {
        return _fallbackMode(userType);
      }
    });

AiUserType? resolveAiUserType(UserModel user) {
  final explicit = AiUserType.fromJson(user.typeHandicap);
  if (explicit != null) return explicit;

  final specificNeed = user.besoinSpecifique?.toLowerCase() ?? '';
  if (specificNeed.contains('aveugle') ||
      specificNeed.contains('visuel') ||
      specificNeed.contains('blind')) {
    return AiUserType.blind;
  }
  if (specificNeed.contains('sourd') ||
      specificNeed.contains('auditif') ||
      specificNeed.contains('deaf')) {
    return AiUserType.deaf;
  }
  if (specificNeed.contains('moteur') ||
      specificNeed.contains('motric') ||
      specificNeed.contains('motor')) {
    return AiUserType.motor;
  }
  return null;
}

AiInteractionMode _fallbackMode(AiUserType userType) {
  return switch (userType) {
    AiUserType.blind => AiInteractionMode.voiceMode,
    AiUserType.deaf => AiInteractionMode.textMode,
    AiUserType.motor => AiInteractionMode.gestureMode,
  };
}
