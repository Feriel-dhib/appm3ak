import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/navigation_mode_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Une seule redirection : on attend l'état d'auth résolu plutôt que de
  /// jouer un délai fixe (l'ancienne version partait sur `/welcome` à 400 ms
  /// même si `_checkAuth()` était sur le point de réussir → race condition).
  bool _redirected = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    // Filet de sécurité (réseau lent / cold start) : si rien n'est résolu au
    // bout de [splashSafetyTimeout], on assume "non connecté" et on bascule.
    _safetyTimer = Timer(AppDurations.splashSafetyTimeout, () {
      if (!mounted || _redirected) return;
      _go('/welcome');
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _go(String location) async {
    if (_redirected || !mounted) return;
    _redirected = true;
    _safetyTimer?.cancel();
    context.go(location);
  }

  /// Décide la prochaine route en fonction :
  ///  - de l'état d'auth (connecté / non),
  ///  - du flag d'onboarding du mode d'accessibilité (déjà choisi ou non).
  Future<void> _resolveAndGo(dynamic user) async {
    if (user == null) {
      await _go('/welcome');
      return;
    }
    final onboardingDone =
        await AccessibilityModeNotifier.hasCompletedOnboarding();
    if (!mounted) return;
    await _go(onboardingDone ? '/home' : '/onboarding/accessibility-mode');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.fr();
    // Réagit à l'état d'auth en temps réel : dès que _checkAuth() résout,
    // on redirige (plus de course avec un délai fixe).
    ref.listen(authStateProvider, (prev, next) {
      next.when(
        data: (user) => _resolveAndGo(user),
        loading: () {}, // attendre
        error: (_, __) => _go('/welcome'),
      );
    });
    // Cas où authStateProvider est DÉJÀ résolu quand le widget est construit
    // (rare, mais possible si on revient sur le splash après navigation).
    final initialAuth = ref.read(authStateProvider);
    initialAuth.whenOrNull(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resolveAndGo(user);
        });
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _go('/welcome');
        });
      },
    );
    // Fond clair garanti pour éviter l'écran noir sur iOS (dark mode / rendu initial)
    return Scaffold(
      backgroundColor: const Color(0xFFFBF0F3), // surface light palette rose
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: strings.appTitle,
              child: AppLogo(
                size: 96,
                borderRadius: 20,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: strings.appTitle,
              child: Text(
                strings.appTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              label: strings.splashLoading,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
