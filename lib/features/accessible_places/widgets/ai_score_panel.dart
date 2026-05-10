import 'package:flutter/material.dart';

import '../../../data/models/accessibility/ai_accessibility_result.dart';
import '../../../data/models/accessibility/handicap_score.dart';

/// Panneau d'affichage des scores IA d'accessibilité (par handicap).
///
/// Couvre trois états :
///  - [isLoading] = true : spinner + texte "Analyse en cours".
///  - [error] non null : message d'erreur + bouton "Réessayer".
///  - [result] non null : score global, résumé IA, grille de chips cliquables.
class AIScorePanel extends StatelessWidget {
  const AIScorePanel({
    super.key,
    this.result,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  final AIAccessibilityResult? result;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingPanel();
    if (error != null) return _ErrorPanel(message: error!, onRetry: onRetry);
    if (result == null) return const SizedBox.shrink();
    return _ResultPanel(result: result!);
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Analyse IA en cours',
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Analyse IA en cours…',
              style: TextStyle(
                color: cs.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});

  final AIAccessibilityResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label:
          'Score accessibilité IA : ${result.scoreGlobal} sur 100, confiance ${result.confiance}',
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'IA Accessibilité',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceBadge(confiance: result.confiance),
                const Spacer(),
                Text(
                  '${result.scoreGlobal}/100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result.resumeIA.isNotEmpty)
              Text(
                result.resumeIA,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 10),
            _ScoreGrid(result: result),
            if (result.sourcesUtilisees.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Sources : ${result.sourcesUtilisees.join(", ")}',
                style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confiance});

  final String confiance;

  @override
  Widget build(BuildContext context) {
    // Le backend peut renvoyer "Elevee" (sans accent) ou "Élevée" → on normalise.
    final normalized = confiance.toLowerCase();
    final isHigh = normalized.startsWith('elev') || normalized.startsWith('élev');
    final isMid = normalized.startsWith('moy');
    final (fg, bg) = isHigh
        ? (const Color(0xFF2A9F58), const Color(0xFFD9F5DE))
        : isMid
            ? (const Color(0xFFE69D2A), const Color(0xFFFFF3DC))
            : (const Color(0xFFD24C4C), const Color(0xFFFDE8E8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Confiance $confiance',
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.result});

  final AIAccessibilityResult result;

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, HandicapScore)>[
      ('Fauteuil', Icons.accessible_rounded, result.fauteuilRoulant),
      ('Surdité', Icons.hearing_rounded, result.surdite),
      ('Cécité', Icons.visibility_off_rounded, result.cecite),
      ('Mobilité', Icons.directions_walk_rounded, result.mobiliteReduite),
      ('Cognitif', Icons.psychology_rounded, result.cognitif),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (it) => _ScoreChip(
              label: it.$1,
              icon: it.$2,
              score: it.$3,
            ),
          )
          .toList(),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.icon,
    required this.score,
  });

  final String label;
  final IconData icon;
  final HandicapScore score;

  @override
  Widget build(BuildContext context) {
    final color = Color(score.colorValue);
    return Semantics(
      button: true,
      label: '$label ${score.score} sur 100, niveau ${score.niveau}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${score.score}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = Color(score.colorValue);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${score.score}/100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              score.niveau,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Détails',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A6174),
              ),
            ),
            const SizedBox(height: 8),
            if (score.details.isEmpty)
              const Text(
                'Aucun détail fourni.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8EA0AD)),
              )
            else
              ...score.details.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3A4F5E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (score.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Sources : ${score.sources.join(", ")}',
                style: const TextStyle(
                  color: Color(0xFF8EA0AD),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
