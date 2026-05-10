import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/ma3ak_day_night_toggle.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/auth_onboarding_layout.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.fromPreferredLanguage(lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final headerFg = authHeaderForeground(theme);
    final logoSize = (MediaQuery.sizeOf(context).shortestSide * 0.38)
        .clamp(120.0, 168.0);
    final logoBg = Colors.white.withValues(alpha: isDark ? 0.22 : 0.94);
    final ghostBorder = Colors.white.withValues(alpha: 0.92);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: headerFg,
      height: 1.2,
    );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: headerFg.withValues(alpha: 0.88),
      height: 1.45,
    );
    final choiceBase = theme.textTheme.bodyMedium?.copyWith(
      color: headerFg.withValues(alpha: 0.9),
      height: 1.5,
    );
    final choiceBold = choiceBase?.copyWith(
      fontWeight: FontWeight.w800,
      color: headerFg,
    );

    return Scaffold(
      body: Ma3akAuthGradientScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Ma3akDayNightThemeToggle(
                      width: (MediaQuery.sizeOf(context).shortestSide * 0.28)
                          .clamp(92.0, 112.0),
                      height: 42,
                    ),
                  ),
                ),
                Text(
                  strings.welcomeHeroTitle,
                  textAlign: TextAlign.center,
                  style: headlineStyle,
                ),
                const SizedBox(height: 14),
                Text(
                  strings.welcomeHeroHi,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.welcomeHeroLine2,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    style: choiceBase,
                    children: [
                      TextSpan(text: strings.welcomeHeroChoiceLead),
                      TextSpan(text: ' ', style: choiceBase),
                      TextSpan(text: strings.loginButton, style: choiceBold),
                      TextSpan(text: strings.welcomeHeroChoiceOr, style: choiceBase),
                      TextSpan(text: strings.registerButton, style: choiceBold),
                      TextSpan(text: strings.welcomeHeroChoiceEnd, style: choiceBase),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: Center(
                    child: Semantics(
                      label: strings.appTitle,
                      child: AppLogo(
                        size: logoSize,
                        borderRadius: logoSize * 0.22,
                        backgroundColor: logoBg,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: isDark
                      ? cs.surface.withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.98),
                  elevation: 3,
                  shadowColor: cs.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: () => context.go('/register'),
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          strings.registerButton,
                          style: TextStyle(
                            color: headerFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: ghostBorder,
                    side: BorderSide(color: ghostBorder, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    strings.loginButton,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
