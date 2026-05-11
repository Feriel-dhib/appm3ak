import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

class Ma3akApp extends ConsumerWidget {
  const Ma3akApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Locale pilotée par le profil utilisateur + override manuel.
    // `null` = locale système (RTL automatique en arabe). Voir [localeProvider].
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Ma3ak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => child ?? const SizedBox.shrink(),
      // ── Localisation : français, anglais, arabe ────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      locale: locale,
      // Si la locale système ne fait pas partie de `supportedLocales`,
      // on retombe sur le français (au lieu d'un anglais Material par défaut).
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return const Locale('fr');
        for (final s in supported) {
          if (s.languageCode == deviceLocale.languageCode) return s;
        }
        return const Locale('fr');
      },
    );
  }
}
