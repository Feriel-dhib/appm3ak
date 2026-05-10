import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/global_gaze_service.dart';

/// Provider du service global de regard (singleton).
final globalGazeServiceProvider =
    ChangeNotifierProvider<GlobalGazeService>((ref) {
  final service = GlobalGazeService();
  ref.onDispose(service.dispose);
  return service;
});

/// Overlay racine optionnel pour l'eye-gaze global.
/// Désactivé pour le moment.
class GlobalGazeOverlay extends ConsumerWidget {
  const GlobalGazeOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
