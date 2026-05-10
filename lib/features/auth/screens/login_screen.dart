import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/ma3ak_day_night_toggle.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/auth_onboarding_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) =>
      v.trim().contains('@') &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    final input = _emailController.text.trim();
    final email = _looksLikeEmail(input) ? input : null;
    final strings = AppStrings.fromPreferredLanguage(
      Localizations.localeOf(context).languageCode,
    );
    if (email == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = strings.loginRequiresValidEmail;
      });
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).login(
            email: email,
            password: _passwordController.text,
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
        final errorStr = e.toString().replaceFirst('Exception: ', '');
        _errorMessage = errorStr.isNotEmpty
            ? errorStr
            : strings.errorInvalidCredentials;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    final strings = AppStrings.fromPreferredLanguage(
      Localizations.localeOf(context).languageCode,
    );
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    setState(() {
      _isLoading = false;
      _errorMessage = strings.googleSignInPendingConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (user != null) context.go('/home');
        },
        error: (err, stack) {
          if (!mounted) return;
          setState(() => _isLoading = false);
        },
      );
    });

    final lang = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.fromPreferredLanguage(lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final logoBg = Colors.white.withValues(alpha: isDark ? 0.22 : 0.94);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          AuthOnboardingLayout(
            headerCenter: Semantics(
              label: strings.appTitle,
              child: AppLogo(
                size: (MediaQuery.sizeOf(context).shortestSide * 0.34)
                    .clamp(108.0, 136.0),
                borderRadius: 28,
                backgroundColor: logoBg,
              ),
            ),
            headerTrailing: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4, top: 4),
                child: Ma3akDayNightThemeToggle(
                  width: (MediaQuery.sizeOf(context).shortestSide * 0.26)
                      .clamp(88.0, 108.0),
                  height: 40,
                ),
              ),
            ],
            cardChild: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.welcomeBack,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.welcomeBackSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        strings.emailOrPhone,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: strings.hintEmailOrPhone,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.mic_none_rounded, color: cs.primary),
                            onPressed: () {},
                            tooltip: strings.voiceInput,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? strings.fieldRequiredShort
                                : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        strings.password,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: strings.hintPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: cs.primary,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? strings.fieldRequiredShort
                                : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: cs.primary,
                          ),
                          Expanded(
                            child: Text(
                              strings.rememberMe,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              strings.forgotPassword,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AuthPrimaryGradientButton(
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(strings.loginButton),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                size: 20, color: cs.onPrimary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.35))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              strings.or,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.35))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(
                            color: cs.outline.withValues(alpha: 0.55),
                          ),
                          foregroundColor: cs.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata_rounded,
                                size: 28, color: cs.primary),
                            const SizedBox(width: 10),
                            Text(
                              strings.signInWithGoogle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            strings.noAccount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(
                              strings.signUp,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: 16,
            bottom: 24,
            child: SafeArea(
              child: Semantics(
                button: true,
                label: strings.accessibilityOptions,
                child: FloatingActionButton.small(
                  onPressed: () {},
                  backgroundColor: cs.surface,
                  foregroundColor: cs.primary,
                  heroTag: 'accessibility',
                  child: const Icon(Icons.accessibility_new_rounded, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
