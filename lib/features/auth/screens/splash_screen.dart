import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Délai minimal pour afficher le splash sans bloquer (réduit pour limiter l'attente)
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/welcome');
        }
      },
      loading: () {
        context.go('/welcome');
      },
      error: (_, __) {
        context.go('/welcome');
      },
    );
    // Sécurité : si après 2 s on est encore sur le splash (redirect échoué), forcer l’accueil auth
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.fr();
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
