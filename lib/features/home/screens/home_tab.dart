import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/models/type_handicap.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/ai_module_providers.dart';
import '../../adaptive/screens/blind_voice_mode_screen.dart';
import '../../adaptive/screens/deaf_text_mode_screen.dart';
import '../../adaptive/screens/motor_gesture_mode_screen.dart';
import '../../eye_navigation/screens/eye_navigation_demo_screen.dart';

/// Contenu de l'onglet Accueil selon la maquette (bonjour, recherche, services, proximité, carte).
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final FlutterTts _tts = FlutterTts();
  bool _autoVoiceLaunched = false;

  bool _isMotorOrDeafProfile(String? typeHandicap) {
    final raw = typeHandicap?.toLowerCase().trim() ?? '';
    return raw.contains('moteur') ||
        raw.contains('motor') ||
        raw.contains('auditif') ||
        raw.contains('deaf') ||
        raw.contains('sourd');
  }

  bool _isBlindProfile(String? typeHandicap) {
    final raw = typeHandicap?.toLowerCase().trim() ?? '';
    return raw.contains('visuel') ||
        raw.contains('blind') ||
        raw.contains('aveugle');
  }

  void _openAdaptiveQuickMenu(BuildContext context, WidgetRef ref) {
    final repo = ref.read(aiModuleRepositoryProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.record_voice_over_outlined),
                title: const Text('Activer mode vocal'),
                subtitle: const Text('Assistant vocal pour navigation'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlindVoiceModeScreen(
                        repository: repo,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Activer mode texte'),
                subtitle: const Text('Interface visuelle simplifiée'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeafTextModeScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.gesture_outlined),
                title: const Text('Activer mode gestes'),
                subtitle: const Text(
                  'Gros boutons + balayage. Pas besoin de plugin caméra natif.',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MotorGestureModeScreen(
                        repository: repo,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Activer mode regard'),
                subtitle: const Text(
                  'Navigation par le regard — caméra avant et analyse sur votre serveur.',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EyeNavigationDemoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _maybeLaunchBlindAssist() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !user.isBeneficiary || !_isBlindProfile(user.typeHandicap)) {
      return;
    }

    if (_autoVoiceLaunched) return;
    _autoVoiceLaunched = true;
    unawaited(Future<void>.delayed(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      // Coupe la voix de l'accueil avant de pousser l'écran vocal,
      // sinon l'init TTS du nouvel écran est immédiatement interrompue
      // et l'utilisateur n'entend rien.
      try {
        await _tts.stop();
      } catch (_) {}
      if (!mounted) return;
      final repo = ref.read(aiModuleRepositoryProvider);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlindVoiceModeScreen(repository: repo),
        ),
      );
    }));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull!;
    final strings =
        AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final showAirWritingHome = user.isBeneficiary &&
        TypeHandicap.fromApiString(user.typeHandicap) == TypeHandicap.moteur;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeLaunchBlindAssist();
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header : logo, Ma3ak, cloche, profil
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Semantics(
                      label: strings.appTitle,
                      image: true,
                      child: AppLogo(
                        size: 44,
                        borderRadius: 12,
                        backgroundColor: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.appTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: primary),
                          tooltip: strings.notifications,
                          onPressed: () => context.push('/notifications'),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.person_outline, color: primary),
                      tooltip: strings.profile,
                      onPressed: () => context.push('/profile'),
                    ),
                    if (user.isBeneficiary &&
                        (_isMotorOrDeafProfile(user.typeHandicap) ||
                            _isBlindProfile(user.typeHandicap)))
                      IconButton(
                        icon: Icon(Icons.accessibility_new, color: primary),
                        tooltip: 'Modes adaptés',
                        onPressed: () => _openAdaptiveQuickMenu(context, ref),
                      ),
                  ],
                ),
              ),
            ),
            // Bonjour + question + recherche
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '${strings.hello}, ${user.displayName}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.whereToGoToday,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label:
                          '${strings.searchAccessiblePlaces}. ${strings.a11ySearchOpensTransport}',
                      excludeSemantics: true,
                      child: TextField(
                        readOnly: true,
                        onTap: () => context.push('/accessible-places'),
                        decoration: InputDecoration(
                          hintText: strings.searchAccessiblePlaces,
                          prefixIcon: Icon(Icons.search, color: primary),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Services Principaux
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Semantics(
                      excludeSemantics: true,
                      child: Icon(Icons.grid_view_rounded, color: primary, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.homePlacesServicesSection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _ServiceCard(
                    icon: Icons.location_city_outlined,
                    label: strings.communityPlaces,
                    primary: primary,
                    onTap: () => context.push('/accessible-places'),
                  ),
                  _ServiceCard(
                    icon: Icons.layers_outlined,
                    label: strings.places,
                    primary: primary,
                    onTap: () => context.go('/home?tab=3'),
                  ),
                  _ServiceCard(
                    icon: Icons.school_outlined,
                    label: strings.learningCenter,
                    primary: primary,
                    onTap: () => context.push('/learning'),
                  ),
                  _ServiceCard(
                    icon: Icons.add_location_alt_outlined,
                    label: strings.submitNewPlace,
                    primary: primary,
                    onTap: () => context.push('/submit-location'),
                  ),
                  _ServiceCard(
                    icon: Icons.navigation_outlined,
                    label: strings.accessibilityCard,
                    primary: primary,
                    onTap: () => context.push('/transport/obstacle-navigation-hub'),
                  ),
                  _ServiceCard(
                    icon: Icons.remove_red_eye_outlined,
                    label: strings.obstacleDetection,
                    primary: primary,
                    onTap: () => context.push('/transport/obstacle-detection'),
                  ),
                  _ServiceCard(
                    icon: Icons.explore_outlined,
                    label: strings.guidedObstacleNavShort,
                    primary: primary,
                    onTap: () => context.push('/transport/obstacle-navigation-hub'),
                  ),
                  if (showAirWritingHome)
                    _ServiceCard(
                      icon: Icons.draw_outlined,
                      label: strings.airWritingHomeLabel,
                      primary: primary,
                      onTap: () => context.push('/air-writing'),
                    ),
                  _ServiceCard(
                    icon: Icons.near_me_outlined,
                    label: strings.communityPlacesNearbyTab,
                    primary: primary,
                    onTap: () => context.push('/community-nearby'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // À proximité & Actif
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        strings.nearbyAndActive,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home?tab=4&communityTab=0'),
                      child: Text(
                        strings.seeAll,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _NearbyCard(
                      icon: Icons.local_taxi,
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Taxi Inclusif #402',
                      subtitle: '2 min • Rampe accessible',
                      badge: strings.available,
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () => context.push('/transport/dynamic'),
                    ),
                    const SizedBox(height: 12),
                    _NearbyCard(
                      icon: Icons.accessible,
                      iconColor: primary,
                      title: 'Ascenseur Gare Centrale',
                      subtitle: 'Tunis Marine • Entrée principale',
                      badge: strings.open,
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () => context.go('/home?tab=3'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Explorer à proximité
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Semantics(
                  header: true,
                  child: Text(
                    strings.exploreNearby,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 48, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text(
                                'Tunis, Centre Ville',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: primary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(28),
                        elevation: 4,
                        child: Semantics(
                          button: true,
                          label: strings.a11yOpenSosAlerts,
                          child: InkWell(
                            onTap: () => context.push('/sos-alerts'),
                            borderRadius: BorderRadius.circular(28),
                            excludeFromSemantics: true,
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.emergency,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: primary),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel = '$title, $subtitle, $badge';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
