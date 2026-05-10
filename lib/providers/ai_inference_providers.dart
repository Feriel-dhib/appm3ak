import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/ai_module_exception.dart';
import '../data/models/ai/ai_predict_models.dart';
import 'ai_module_providers.dart';

final aiModelsProvider = FutureProvider<AiModelsResponse>((ref) async {
  return ref.watch(aiModuleRepositoryProvider).listModels();
});

final signTextControllerProvider =
    AsyncNotifierProvider<SignTextController, SignTextResponse?>(
      SignTextController.new,
    );

class SignTextController extends AsyncNotifier<SignTextResponse?> {
  @override
  Future<SignTextResponse?> build() async => null;

  Future<void> run(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aiModuleRepositoryProvider).signText(text),
    );
  }
}

final adaptiveDifficultyControllerProvider = AsyncNotifierProvider<
    AdaptiveDifficultyController, AdaptiveDifficultyResponse?>(
  AdaptiveDifficultyController.new,
);

class AdaptiveDifficultyController
    extends AsyncNotifier<AdaptiveDifficultyResponse?> {
  @override
  Future<AdaptiveDifficultyResponse?> build() async => null;

  Future<AdaptiveDifficultyResponse?> run(AdaptiveDifficultyRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aiModuleRepositoryProvider).adaptiveDifficulty(request),
    );
    return state.valueOrNull;
  }
}

String aiFriendlyError(Object error) {
  if (error is AiModuleException) {
    switch (error.type) {
      case AiModuleErrorType.offline:
        return 'Service IA indisponible. Vérifiez la connexion puis réessayez.';
      case AiModuleErrorType.timeout:
        return 'Service IA trop lent. Réessayez.';
      default:
        return error.message;
    }
  }
  return 'Erreur IA inattendue.';
}
