import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';

/// Interrupteur pillule jour / nuit : dégradés pêche→bleu / violet→magenta, nuages, étoiles, curseur blanc animé.
class Ma3akDayNightThemeToggle extends ConsumerStatefulWidget {
  const Ma3akDayNightThemeToggle({
    super.key,
    this.width = 104,
    this.height = 44,
  });

  final double width;
  final double height;

  @override
  ConsumerState<Ma3akDayNightThemeToggle> createState() =>
      _Ma3akDayNightThemeToggleState();
}

class _Ma3akDayNightThemeToggleState extends ConsumerState<Ma3akDayNightThemeToggle>
    with SingleTickerProviderStateMixin {
  static const _dayLeft = Color(0xFFF9D1BA);
  static const _dayRight = Color(0xFFA8D8FF);
  static const _nightLeft = Color(0xFF4B2CBE);
  static const _nightRight = Color(0xFFE85FB5);

  late AnimationController _ctrl;
  bool? _lastSyncedDark;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _syncAnimationToTheme(bool isDark, {required bool animated}) {
    final target = isDark ? 1.0 : 0.0;
    if ((_ctrl.value - target).abs() < 0.001) return;
    if (animated) {
      _ctrl.animateTo(
        target,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _ctrl.value = target;
    }
  }

  void _maybeSyncTheme(bool isDark) {
    if (_lastSyncedDark == isDark) return;
    final animate = _lastSyncedDark != null;
    _lastSyncedDark = isDark;
    if (animate) {
      _syncAnimationToTheme(isDark, animated: true);
    } else {
      _ctrl.value = isDark ? 1.0 : 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _maybeSyncTheme(isDark);

    final labels = _toggleStrings(context);
    return Semantics(
      button: true,
      label: isDark ? labels.$1 : labels.$2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(themeModeProvider.notifier).setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
          },
          borderRadius: BorderRadius.circular(widget.height / 2),
          customBorder: const StadiumBorder(),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value;
                  return _ToggleTrack(
                    width: widget.width,
                    height: widget.height,
                    t: t,
                    dayLeft: _dayLeft,
                    dayRight: _dayRight,
                    nightLeft: _nightLeft,
                    nightRight: _nightRight,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// (activer jour, activer nuit) — libellés sémantiques FR par défaut.
  (String, String) _toggleStrings(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return switch (lang) {
      'ar' => ('تفعيل الوضع النهاري', 'تفعيل الوضع الليلي'),
      'en' => ('Switch to light mode', 'Switch to dark mode'),
      _ => ('Activer le mode jour', 'Activer le mode nuit'),
    };
  }
}

class _ToggleTrack extends StatelessWidget {
  const _ToggleTrack({
    required this.width,
    required this.height,
    required this.t,
    required this.dayLeft,
    required this.dayRight,
    required this.nightLeft,
    required this.nightRight,
  });

  final double width;
  final double height;
  final double t;
  final Color dayLeft;
  final Color dayRight;
  final Color nightLeft;
  final Color nightRight;

  @override
  Widget build(BuildContext context) {
    final pad = 4.0;
    final knob = height - pad * 2;
    final maxTravel = width - pad * 2 - knob;
    final knobFromStart = maxTravel * t;

    final c0 = Color.lerp(dayLeft, nightLeft, t)!;
    final c1 = Color.lerp(dayRight, nightRight, t)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [c0, c1],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SizedBox(width: width, height: height),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ToggleDecoPainter(t: t),
            ),
          ),
          PositionedDirectional(
            start: pad + knobFromStart,
            top: pad,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nuages (jour à droite, nuit à gauche) + étoiles la nuit. Piste en LTR (maquette).
class _ToggleDecoPainter extends CustomPainter {
  _ToggleDecoPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const isRtl = false;

    final dayAlpha = (1 - t) * 0.55;
    if (dayAlpha > 0.01) {
      _drawDayClouds(canvas, w, h, isRtl, dayAlpha);
    }

    final nightAlpha = t * 0.65;
    if (nightAlpha > 0.01) {
      _drawNightDeco(canvas, w, h, isRtl, nightAlpha);
    }
  }

  void _drawDayClouds(
    Canvas canvas,
    double w,
    double h,
    bool isRtl,
    double alpha,
  ) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final cx = isRtl ? w * 0.22 : w * 0.78;
    final cy = h * 0.52;
    _blob(canvas, cx, cy, w * 0.14, h * 0.28, paint);
    _blob(canvas, cx + (isRtl ? w * 0.1 : -w * 0.1), cy + h * 0.06, w * 0.11, h * 0.22, paint);
  }

  void _drawNightDeco(
    Canvas canvas,
    double w,
    double h,
    bool isRtl,
    double alpha,
  ) {
    final cloud = Paint()
      ..color = Color.lerp(
        const Color(0xFF9B7FD9),
        const Color(0xFFE85FB5),
        0.5,
      )!.withValues(alpha: alpha * 0.5);
    final cx = isRtl ? w * 0.78 : w * 0.22;
    final cy = h * 0.5;
    _blob(canvas, cx, cy, w * 0.13, h * 0.26, cloud);
    _blob(canvas, cx + (isRtl ? -w * 0.08 : w * 0.08), cy + h * 0.05, w * 0.1, h * 0.2, cloud);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.95);
    final rnd = math.Random(42);
    for (var i = 0; i < 7; i++) {
      final sx = (isRtl ? w * 0.55 : w * 0.08) + rnd.nextDouble() * w * 0.32;
      final sy = h * 0.12 + rnd.nextDouble() * h * 0.76;
      final r = 1.2 + rnd.nextDouble() * 1.8;
      _star(canvas, Offset(sx, sy), r, starPaint);
    }
  }

  void _blob(Canvas canvas, double cx, double cy, double rw, double rh, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2), paint);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = (i * math.pi / 2) - math.pi / 4;
      final x = c.dx + math.cos(a) * r;
      final y = c.dy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final a2 = a + math.pi / 4;
      path.lineTo(c.dx + math.cos(a2) * r * 0.35, c.dy + math.sin(a2) * r * 0.35);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToggleDecoPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
