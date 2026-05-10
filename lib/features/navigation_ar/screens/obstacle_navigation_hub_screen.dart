import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';

/// Choix entre détection d’obstacles seule (YOLO) ou détection + guidage (itinéraire + caméra AR).
class ObstacleNavigationHubScreen extends ConsumerWidget {
  const ObstacleNavigationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.obstacleNavHubTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.remove_red_eye_outlined, color: theme.colorScheme.onPrimaryContainer),
              ),
              title: Text(strings.obstacleNavOptionSolo),
              subtitle: Text(strings.obstacleNavOptionSoloSubtitle),
              isThreeLine: true,
              onTap: () => context.push('/transport/obstacle-detection'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.explore_outlined, color: theme.colorScheme.onSecondaryContainer),
              ),
              title: Text(strings.obstacleNavOptionGuided),
              subtitle: Text(strings.obstacleNavOptionGuidedSubtitle),
              isThreeLine: true,
              onTap: () => context.push('/transport/obstacle-guided-ar'),
            ),
          ),
        ],
      ),
    );
  }
}
