import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ai/adapt_models.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/ai_module_providers.dart';
import 'blind_voice_mode_screen.dart';
import 'deaf_text_mode_screen.dart';
import 'motor_gesture_mode_screen.dart';

class AdaptiveModeHomeScreen extends ConsumerStatefulWidget {
  const AdaptiveModeHomeScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<AdaptiveModeHomeScreen> createState() =>
      _AdaptiveModeHomeScreenState();
}

class _AdaptiveModeHomeScreenState
    extends ConsumerState<AdaptiveModeHomeScreen> {
  AiUserType? _selectedType;
  AiInteractionMode? _mode;
  bool _loading = false;
  String? _error;

  Future<void> _selectType(AiUserType type) async {
    setState(() {
      _selectedType = type;
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(aiModuleRepositoryProvider)
          .adaptForUserType(type);
      if (!mounted) return;
      setState(() => _mode = response.mode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mode = switch (type) {
          AiUserType.blind => AiInteractionMode.voiceMode,
          AiUserType.deaf => AiInteractionMode.textMode,
          AiUserType.motor => AiInteractionMode.gestureMode,
        };
        _error = 'Service AI indisponible. Mode de secours activé.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    if (mode == null) {
      return _AdaptiveModeSelector(
        loading: _loading,
        selectedType: _selectedType,
        error: _error,
        onSelect: _selectType,
      );
    }

    final repository = ref.watch(aiModuleRepositoryProvider);
    return switch (mode) {
      AiInteractionMode.voiceMode => BlindVoiceModeScreen(
        repository: repository,
      ),
      AiInteractionMode.textMode => const DeafTextModeScreen(),
      AiInteractionMode.gestureMode => MotorGestureModeScreen(
        repository: repository,
      ),
    };
  }
}

class _AdaptiveModeSelector extends StatelessWidget {
  const _AdaptiveModeSelector({
    required this.loading,
    required this.selectedType,
    required this.error,
    required this.onSelect,
  });

  final bool loading;
  final AiUserType? selectedType;
  final String? error;
  final Future<void> Function(AiUserType type) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Interface adaptative')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choisissez votre type de handicap pour activer le mode adapté.',
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 16),
            _TypeButton(
              title: 'Déficience visuelle',
              subtitle: 'blind -> voice_mode',
              icon: Icons.visibility_off_outlined,
              selected: selectedType == AiUserType.blind,
              onPressed: loading ? null : () => onSelect(AiUserType.blind),
            ),
            _TypeButton(
              title: 'Déficience auditive',
              subtitle: 'deaf -> text_mode',
              icon: Icons.hearing_disabled_outlined,
              selected: selectedType == AiUserType.deaf,
              onPressed: loading ? null : () => onSelect(AiUserType.deaf),
            ),
            _TypeButton(
              title: 'Déficience motrice',
              subtitle: 'motor -> gesture_mode',
              icon: Icons.accessibility_new_outlined,
              selected: selectedType == AiUserType.motor,
              onPressed: loading ? null : () => onSelect(AiUserType.motor),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 96,
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            side: selected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
