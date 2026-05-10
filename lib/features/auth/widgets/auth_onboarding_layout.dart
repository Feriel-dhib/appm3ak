import 'package:flutter/material.dart';

/// Couleur d’icônes / texte sur le bandeau dégradé (contraste Ma3ak).
Color authHeaderForeground(ThemeData theme) {
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.onSurface
      : const Color(0xFF3B2133);
}

/// Dégradé pastel + motif circulaire + carte basse aux coins supérieurs très arrondis.
class AuthOnboardingLayout extends StatelessWidget {
  const AuthOnboardingLayout({
    super.key,
    required this.cardChild,
    this.headerLeading = const [],
    this.headerTrailing = const [],
    this.headerCenter,
    this.cardTopOuterRadius = 40,
    this.headerFlex = 30,
    this.cardFlex = 70,
  });

  final Widget cardChild;
  final List<Widget> headerLeading;
  final List<Widget> headerTrailing;
  final Widget? headerCenter;
  final double cardTopOuterRadius;
  final int headerFlex;
  final int cardFlex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return ColoredBox(
      color: isDark ? cs.primaryContainer : cs.secondaryContainer.withValues(alpha: 0.35),
      child: Column(
        children: [
          Expanded(
            flex: headerFlex,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              cs.primaryContainer,
                              cs.primary.withValues(alpha: 0.95),
                              cs.secondary.withValues(alpha: 0.7),
                            ]
                          : [
                              cs.primaryContainer,
                              cs.secondaryContainer,
                              cs.secondary.withValues(alpha: 0.65),
                            ],
                    ),
                  ),
                ),
                CustomPaint(
                  painter: AuthCirclePatternPainter(
                    color: (isDark ? Colors.white : cs.onPrimaryContainer)
                        .withValues(alpha: isDark ? 0.14 : 0.22),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      if (headerLeading.isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: headerLeading,
                          ),
                        ),
                      if (headerTrailing.isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: headerTrailing,
                          ),
                        ),
                      if (headerCenter != null)
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: headerCenter!,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: cardFlex,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(cardTopOuterRadius)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: cardChild,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dégradé Ma3ak plein écran + motif circulaire (écran d’accueil, etc.).
class Ma3akAuthGradientScaffold extends StatelessWidget {
  const Ma3akAuthGradientScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      cs.primaryContainer,
                      cs.primary.withValues(alpha: 0.95),
                      cs.secondary.withValues(alpha: 0.72),
                    ]
                  : [
                      cs.primaryContainer,
                      cs.secondaryContainer,
                      cs.secondary.withValues(alpha: 0.65),
                    ],
            ),
          ),
        ),
        CustomPaint(
          painter: AuthCirclePatternPainter(
            color: (isDark ? Colors.white : cs.onPrimaryContainer)
                .withValues(alpha: isDark ? 0.14 : 0.22),
          ),
        ),
        child,
      ],
    );
  }
}

class AuthCirclePatternPainter extends CustomPainter {
  AuthCirclePatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    void rings(Offset center, int n, double step, double opacity) {
      for (var i = 1; i <= n; i++) {
        canvas.drawCircle(
          center,
          step * i,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }

    final a = color.a;
    rings(Offset(size.width * 0.86, size.height * 0.10), 10, 15, a);
    rings(Offset(size.width * 0.14, size.height * 0.88), 7, 13, a * 0.48);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bouton principal en dégradé (secondary → primary) pour les flux auth.
class AuthPrimaryGradientButton extends StatelessWidget {
  const AuthPrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.secondary,
              cs.primary,
            ],
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.38),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(borderRadius: radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : DefaultTextStyle.merge(
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                        child: child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
