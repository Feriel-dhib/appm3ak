import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appm3ak/features/learning/screens/learning_center_screen.dart';
import 'package:appm3ak/features/learning/services/user_history_manager.dart';

/// Point d’entrée GoRouter : fournit [UserHistoryManager] attendu par [LearningCenterScreen].
class LearningEntryScreen extends StatelessWidget {
  const LearningEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserHistoryManager>(
          create: (_) => UserHistoryManager(userId: 1),
        ),
      ],
      child: const LearningCenterScreen(),
    );
  }
}
