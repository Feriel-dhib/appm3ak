import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models/ai/voice_intent_models.dart';
import '../data/repositories/ai_module_repository.dart';
import 'ai_module_providers.dart';

/// État global du mode vocal persistant.
///
/// Quand activé, déclenche automatiquement la lecture TTS de chaque nouvelle
/// page après navigation GoRouter.
class VoiceModeState {
  const VoiceModeState({
    required this.isActive,
    required this.currentRoute,
    this.lastReadRoute,
  });

  final bool isActive;
  final String currentRoute;
  final String? lastReadRoute;

  VoiceModeState copyWith({
    bool? isActive,
    String? currentRoute,
    String? lastReadRoute,
  }) {
    return VoiceModeState(
      isActive: isActive ?? this.isActive,
      currentRoute: currentRoute ?? this.currentRoute,
      lastReadRoute: lastReadRoute ?? this.lastReadRoute,
    );
  }
}

/// Notifier pour gérer l'état du mode vocal persistant.
class VoiceModeNotifier extends Notifier<VoiceModeState> {
  @override
  VoiceModeState build() {
    return const VoiceModeState(isActive: false, currentRoute: '');
  }

  void activateVoiceMode(String initialRoute) {
    state = VoiceModeState(
      isActive: true,
      currentRoute: initialRoute,
      lastReadRoute: initialRoute,
    );
  }

  void deactivateVoiceMode() {
    state = state.copyWith(isActive: false);
  }

  void updateCurrentRoute(String route) {
    state = state.copyWith(currentRoute: route);
  }

  void markRouteAsRead(String route) {
    state = state.copyWith(lastReadRoute: route);
  }
}

final voiceModeProvider =
    NotifierProvider<VoiceModeNotifier, VoiceModeState>(VoiceModeNotifier.new);

/// Service pour la lecture automatique des écrans.
class AutoScreenReaderService {
  AutoScreenReaderService({
    required this.repository,
    required this.tts,
  });

  final AiModuleRepository repository;
  final FlutterTts tts;

  Future<void> readScreen({
    required String title,
    required List<ScreenSummaryItem> items,
  }) async {
    String spoken = _buildLocalSummary(title, items);

    // Tentative backend (best effort).
    try {
      final response = await repository.summarizeScreen(
        ScreenSummaryRequest(title: title, items: items),
      );
      if (response.summary.trim().isNotEmpty) {
        spoken = response.summary;
      }
    } catch (_) {
      // Fallback sur résumé local.
    }

    // TTS local.
    try {
      await tts.stop();
      await tts.speak(spoken);
    } catch (_) {
      // Silence.
    }
  }

  String _buildLocalSummary(String title, List<ScreenSummaryItem> items) {
    if (items.isEmpty) {
      return '$title. Aucune action disponible.';
    }
    final lines = <String>[title];
    for (final item in items) {
      final hint = item.hint?.trim();
      if (hint != null && hint.isNotEmpty) {
        lines.add('${item.label}. $hint');
      } else {
        lines.add(item.label);
      }
    }
    return lines.join(' ');
  }
}

/// Provider pour le service de lecture automatique.
final autoScreenReaderProvider = Provider<AutoScreenReaderService>((ref) {
  final repo = ref.watch(aiModuleRepositoryProvider);
  final tts = FlutterTts();

  // Configuration TTS par défaut.
  tts.setLanguage('fr-FR');
  tts.setSpeechRate(0.45);
  tts.setVolume(1.0);
  tts.awaitSpeakCompletion(true);

  ref.onDispose(() {
    tts.stop();
  });

  return AutoScreenReaderService(repository: repo, tts: tts);
});
