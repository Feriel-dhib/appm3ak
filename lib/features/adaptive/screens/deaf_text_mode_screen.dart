import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/ai_inference_providers.dart';

class DeafTextModeScreen extends ConsumerStatefulWidget {
  const DeafTextModeScreen({super.key});

  @override
  ConsumerState<DeafTextModeScreen> createState() => _DeafTextModeScreenState();
}

class _DeafTextModeScreenState extends ConsumerState<DeafTextModeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signTextState = ref.watch(signTextControllerProvider);
    final generated = signTextState.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Mode texte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Interface visuelle active.\nAucun retour audio n’est utilisé.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: 'Texte vers signes (IA2)',
            subtitle: 'Convertir une phrase en séquence visuelle',
            icon: Icons.sign_language_outlined,
            onTap: () => _runSignText(),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Phrase à convertir',
                      hintText: 'Ex: bonjour aide urgence',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: signTextState.isLoading ? null : _runSignText,
                          icon: signTextState.isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label: const Text('Lancer IA'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: signTextState.isLoading ? null : _runSignText,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (signTextState.hasError)
                    Text(
                      aiFriendlyError(signTextState.error!),
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (generated != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        generated.visualSequence.isEmpty
                            ? 'Aucune séquence visuelle retournée.'
                            : generated.visualSequence.join('  '),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _ActionCard(
            title: 'Notifications',
            subtitle: 'Afficher toutes les alertes en texte',
            icon: Icons.notifications_active_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications visuelles actives.'),
                ),
              );
            },
          ),
          _ActionCard(
            title: 'Confirmation',
            subtitle: 'Confirmer les actions critiques par texte',
            icon: Icons.rule_folder_outlined,
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text(
                    'Toutes les actions importantes sont confirmées visuellement.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runSignText() async {
    await ref.read(signTextControllerProvider.notifier).run(_textController.text);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 92,
        child: FilledButton.tonalIcon(
          onPressed: onTap,
          icon: Icon(icon, size: 28),
          label: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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
