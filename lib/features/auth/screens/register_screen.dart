import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/type_accompagnant.dart';
import '../../../data/models/type_handicap.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/ma3ak_day_night_toggle.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/auth_onboarding_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _besoinSpecifiqueController = TextEditingController();
  TypeHandicap? _selectedTypeHandicap;
  final _specialisationController = TextEditingController();
  TypeAccompagnant? _selectedTypeAccompagnant;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _animalAssistance = false;
  String? _errorMessage;
  UserRole _role = UserRole.handicape;
  PreferredLanguage? _preferredLanguage = PreferredLanguage.fr;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailOrPhoneController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _besoinSpecifiqueController.dispose();
    _specialisationController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) =>
      v.trim().contains('@') &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());

  String? get _emailValue {
    final v = _emailOrPhoneController.text.trim();
    if (_looksLikeEmail(v)) return v;
    return _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
  }

  String get _telephoneValue => _telephoneController.text.trim();

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    final email = _emailValue;
    final errStrings = AppStrings.fromPreferredLanguage(_preferredLanguage?.name);
    if (email == null || email.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = errStrings.emailRequiredRegister;
      });
      return;
    }
    if (_telephoneValue.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = errStrings.phoneRequiredRegister;
      });
      return;
    }
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: email,
        password: _passwordController.text,
        telephone: _telephoneValue,
        role: _role.toApiString(),
        typeHandicap: _role == UserRole.handicape
            ? _selectedTypeHandicap?.backendValue
            : null,
        besoinSpecifique: _besoinSpecifiqueController.text.trim().isEmpty
            ? null
            : _besoinSpecifiqueController.text.trim(),
        animalAssistance: _animalAssistance,
        typeAccompagnant: _role == UserRole.accompagnant
            ? _selectedTypeAccompagnant?.backendValue
            : null,
        specialisation: _specialisationController.text.trim().isEmpty
            ? null
            : _specialisationController.text.trim(),
        langue: _preferredLanguage?.name ?? 'fr',
      );
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.fromPreferredLanguage(_preferredLanguage?.name).errorGeneric;
      });
    }
  }

  void _nextStep() {
    if (_step < 3) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step++);
      }
    } else {
      if (_role == UserRole.accompagnant && _selectedTypeAccompagnant == null) {
        setState(() => _errorMessage =
            AppStrings.fromPreferredLanguage(_preferredLanguage?.name).typeAccompagnantRequiredError);
        return;
      }
      _submit();
    }
  }


  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      prefixStyle: prefixStyle,
    );
  }

  Widget _roleSelector(BuildContext context, AppStrings strings) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.iAm,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Material(
                color: _role == UserRole.handicape ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => setState(() {
                    _role = UserRole.handicape;
                    _selectedTypeAccompagnant = null;
                  }),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        strings.roleHandicap,
                        style: TextStyle(
                          color: _role == UserRole.handicape ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: _role == UserRole.accompagnant ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => setState(() {
                    _role = UserRole.accompagnant;
                    _selectedTypeAccompagnant = TypeAccompagnant.chauffeursSolidaires;
                  }),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        strings.companion,
                        style: TextStyle(
                          color: _role == UserRole.accompagnant ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.fromPreferredLanguage(_preferredLanguage?.name);
    ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerFg = authHeaderForeground(theme);
    final isDark = theme.brightness == Brightness.dark;
    final logoBg = Colors.white.withValues(alpha: isDark ? 0.22 : 0.94);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AuthOnboardingLayout(
        headerLeading: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: headerFg),
            onPressed: () {
              if (_step > 0) {
                setState(() => _step--);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
              }
            },
          ),
        ],
        headerTrailing: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4, top: 4),
            child: Ma3akDayNightThemeToggle(
              width: (MediaQuery.sizeOf(context).shortestSide * 0.24)
                  .clamp(84.0, 102.0),
              height: 38,
            ),
          ),
        ],
        headerCenter: Semantics(
          label: strings.appTitle,
          child: AppLogo(
            size: (MediaQuery.sizeOf(context).shortestSide * 0.28)
                .clamp(92.0, 118.0),
            borderRadius: 24,
            backgroundColor: logoBg,
          ),
        ),
        cardChild: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final active = i <= _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 12 : 10,
                      height: active ? 12 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? cs.primary : cs.surfaceContainerHighest,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      if (_step == 0) ...[
                        Text(
                          strings.registerPageTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.registerSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _roleSelector(context, strings),
                        const SizedBox(height: 20),
                        Text(
                          '${strings.lastName} *',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nomController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(context,
                            hintText: strings.hintLastNameExample,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? strings.fieldRequiredShort : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${strings.firstName} *',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _prenomController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(context,
                            hintText: strings.hintFirstNameExample,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? strings.fieldRequiredShort : null,
                        ),
                        if (_role == UserRole.handicape) ...[
                          const SizedBox(height: 20),
                          Text(
                            strings.handicapTypeOptional,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: DropdownButtonFormField<TypeHandicap>(
                              value: _selectedTypeHandicap,
                              dropdownColor: cs.surfaceContainerHighest,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              hint: Text(
                                AppStrings.fromPreferredLanguage(
                                        _preferredLanguage?.name)
                                    .typeHandicapHint,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                              items: TypeHandicap.values
                                  .map((TypeHandicap t) {
                                    final labelStrings =
                                        AppStrings.fromPreferredLanguage(
                                            _preferredLanguage?.name);
                                    return DropdownMenuItem<TypeHandicap>(
                                      value: t,
                                      child: Text(
                                        labelStrings.typeHandicapLabel(
                                          t.backendValue,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (TypeHandicap? v) {
                                setState(() => _selectedTypeHandicap = v);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.specificNeedsOptionalLabel,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _besoinSpecifiqueController,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _fieldDecoration(context, hintText: strings.commentPlaceholder),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _animalAssistance,
                            onChanged: (v) => setState(() => _animalAssistance = v ?? false),
                            title: Text(strings.assistanceAnimal, style: TextStyle(color: cs.onSurface)),
                            activeColor: cs.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          strings.emailOrPhoneRequired,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailOrPhoneController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(context,
                            hintText: 'votre@email.tn',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.mail_outline_rounded, color: cs.onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? strings.fieldRequiredShort : null,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, color: cs.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  strings.dataSecurityMessage,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_step == 1) ...[
                        Text(
                          strings.passwordAndRoleTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _roleSelector(context, strings),
                        const SizedBox(height: 20),
                        if (!_looksLikeEmail(_emailOrPhoneController.text.trim())) ...[
                          Text(
                            strings.emailAddressLabel,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _fieldDecoration(context,
                              hintText: strings.emailOrPhoneHint,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.mail_outline_rounded, color: cs.onSurfaceVariant, size: 22),
                              ),
                            ),
                            validator: (v) {
                              if (_looksLikeEmail(
                                  _emailOrPhoneController.text.trim())) {
                                return null;
                              }
                              if (v == null || v.trim().isEmpty) {
                                return strings.fieldRequiredShort;
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v)) {
                                return strings.invalidEmailShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          strings.phoneNumberLabel,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(
                            context,
                            hintText: '99 000 000',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.phone_outlined, color: cs.onSurfaceVariant, size: 22),
                            ),
                            prefixText: '+216 ',
                            prefixStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? strings.fieldRequiredShort : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          strings.passwordLabel,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(context,
                            hintText: strings.hintPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cs.primary,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? strings.passwordMinChars
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          strings.confirmPasswordLabel,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: TextStyle(color: cs.onSurface),
                          decoration: _fieldDecoration(context,
                            hintText: strings.confirmPasswordHint,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cs.primary,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return strings.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_step == 2) ...[
                        Text(
                          strings.languageScreenTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          strings.preferredLanguageOptional,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Radio<PreferredLanguage?>(
                              value: PreferredLanguage.fr,
                              groupValue: _preferredLanguage,
                              activeColor: cs.primary,
                              onChanged: (v) =>
                                  setState(() => _preferredLanguage = v),
                            ),
                            Text('Français', style: TextStyle(color: cs.onSurface)),
                            Radio<PreferredLanguage?>(
                              value: PreferredLanguage.en,
                              groupValue: _preferredLanguage,
                              activeColor: cs.primary,
                              onChanged: (v) =>
                                  setState(() => _preferredLanguage = v),
                            ),
                            Text(strings.englishLanguage, style: TextStyle(color: cs.onSurface)),
                            Radio<PreferredLanguage?>(
                              value: PreferredLanguage.ar,
                              groupValue: _preferredLanguage,
                              activeColor: cs.primary,
                              onChanged: (v) =>
                                  setState(() => _preferredLanguage = v),
                            ),
                            Text('العربية', style: TextStyle(color: cs.onSurface)),
                          ],
                        ),
                      ],
                      if (_step == 3) ...[
                        Text(
                          _role == UserRole.accompagnant
                              ? strings.companionTypeAndSpecialization
                              : strings.finalizeTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_role == UserRole.accompagnant) ...[
                          Text(
                            strings.typeAccompagnantRequired,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.typeAccompagnantLabel(
                                    TypeAccompagnant.chauffeursSolidaires.backendValue,
                                  ),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  strings.companionAccountIsChauffeurSolidaireOnly,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.specializationOptional,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _specialisationController,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _fieldDecoration(context, hintText: strings.hintSpecialisation),
                          ),
                        ] else
                          Text(
                            strings.verifyThenSignUp,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, height: 1.45),
                          ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      AuthPrimaryGradientButton(
                        onPressed: _isLoading ? null : _nextStep,
                        isLoading: _isLoading,
                        child: Text(
                          _step < 3 ? strings.continueBtn : strings.signUp,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            strings.registerAlready,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              strings.loginButton,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
