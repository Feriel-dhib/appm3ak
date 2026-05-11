import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../../core/widgets/ma3ak_bottom_nav_item.dart';
import '../../accessibility/auto_voice_navigation_listener.dart';
import '../../accessibility/screens/accessibility_lieux_hub_screen.dart';
import '../../community/screens/community_main_screen.dart';
import '../../health/screens/health_tab.dart';
import '../../transport/screens/transport_hub_screen.dart';
import 'home_companion_tab.dart';
import 'home_tab.dart';

/// Shell principal après connexion : **5 onglets** (Accueil, Santé, Transport, Milieux, Communauté) ;
/// **chauffeur solidaire** : Accueil, Transport, Communauté uniquement (Santé masquée).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.initialCommunityTabIndex = 0,
  });

  final int initialIndex;
  /// Onglet interne du hub Communauté (0 = posts, 1 = lieux, 2 = aide).
  final int initialCommunityTabIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

int _resolveShellTabIndex(UserModel user, int routerTab) {
  if (!user.isChauffeurSolidaire) {
    return routerTab.clamp(0, 4);
  }
  final t = routerTab.clamp(0, 5);
  // Chauffeur : indices shell 0=accueil, 1=transport, 2=profil — pas d’onglet Santé.
  return switch (t) {
    0 => 0,
    1 => 1, // lien « Santé » ou ancien tab1 → transport
    2 => 1,
    3 => 2,
    4 => 2,
    _ => 0,
  };
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _hasCheckedFirstLogin = false;
  bool _appliedInitialRoute = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      final u = ref.read(authStateProvider).valueOrNull;
      if (u != null) {
        setState(
          () => _currentIndex = _resolveShellTabIndex(u, widget.initialIndex),
        );
      }
    }
  }

  Future<void> _checkFirstLoginAndShowVehicleDialog(UserModel user) async {
    if (_hasCheckedFirstLogin) return;
    _hasCheckedFirstLogin = true;

    // Vérifier si l'utilisateur est un chauffeur solidaire
    if (!user.isChauffeurSolidaire) {
      return;
    }

    // Vérifier si c'est le premier login (pas de véhicules)
    try {
      final vehiclesAsync = ref.read(myVehiclesProvider(user.id));
      await vehiclesAsync.when(
        data: (vehicles) async {
          if (vehicles.isEmpty && mounted) {
            // Vérifier si on a déjà demandé (éviter de redemander à chaque fois)
            final prefs = await SharedPreferences.getInstance();
            final key = 'vehicle_dialog_shown_${user.id}';
            final alreadyShown = prefs.getBool(key) ?? false;

            if (!alreadyShown && mounted) {
              await prefs.setBool(key, true);
              _showVehicleCreationDialog(user);
            }
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _showVehicleCreationDialog(UserModel user) async {
    if (!mounted) return;

    final strings = AppStrings.fromPreferredLanguage(
      user.preferredLanguage?.name,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(strings.addVehicle),
        content: Text(
          strings.isAr
              ? 'كمرافق سائق متضامن، يرجى إضافة مركبتك لتتمكن من تقديم خدمات النقل.'
              : 'En tant que chauffeur solidaire, veuillez ajouter votre véhicule pour pouvoir proposer des services de transport.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.ignore),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/vehicles/new');
            },
            child: Text(strings.addVehicle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/welcome');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Vérifier le premier login pour les chauffeurs solidaires
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkFirstLoginAndShowVehicleDialog(user);
        });

        if (!_appliedInitialRoute) {
          _appliedInitialRoute = true;
          final resolved = _resolveShellTabIndex(user, widget.initialIndex);
          if (resolved != _currentIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentIndex = resolved);
            });
          }
        }

        final strings = AppStrings.fromPreferredLanguage(
          user.preferredLanguage?.name,
        );
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final chauffeurShell = user.isChauffeurSolidaire;

        Widget body;
        if (chauffeurShell) {
          switch (_currentIndex.clamp(0, 2)) {
            case 0:
              body = const HomeCompanionTab();
              break;
            case 1:
              body = const TransportHubScreen();
              break;
            case 2:
              body = CommunityMainScreen(
                initialTabIndex: widget.initialCommunityTabIndex,
              );
              break;
            default:
              body = const HomeCompanionTab();
          }
        } else {
          switch (_currentIndex.clamp(0, 4)) {
            case 0:
              body = user.isBeneficiary
                  ? const HomeTab()
                  : const HomeCompanionTab();
              break;
            case 1:
              body = const HealthTab();
              break;
            case 2:
              if (user.isBeneficiary || user.isCompanion) {
                body = const TransportHubScreen();
              } else {
                body = _PlaceholderTab(
                  title: strings.transport,
                  comingSoon: strings.placeholderSoon,
                );
              }
              break;
            case 3:
              body = const AccessibilityLieuxHubScreen();
              break;
            case 4:
              body = CommunityMainScreen(
                initialTabIndex: widget.initialCommunityTabIndex,
              );
              break;
            default:
              body = const HomeTab();
          }
        }

        final navItems = chauffeurShell
            ? <Widget>[
                Ma3akBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: strings.home,
                  selected: _currentIndex == 0,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.directions_bus_outlined,
                  activeIcon: Icons.directions_bus,
                  label: strings.transport,
                  selected: _currentIndex == 1,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_2,
                  label: strings.community,
                  selected: _currentIndex == 2,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ]
            : <Widget>[
                Ma3akBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: strings.home,
                  selected: _currentIndex == 0,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services,
                  label: strings.health,
                  selected: _currentIndex == 1,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.directions_bus_outlined,
                  activeIcon: Icons.directions_bus,
                  label: strings.transport,
                  selected: _currentIndex == 2,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.place_outlined,
                  activeIcon: Icons.place,
                  label: strings.navLieux,
                  selected: _currentIndex == 3,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                Ma3akBottomNavItem(
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_2,
                  label: strings.community,
                  selected: _currentIndex == 4,
                  primary: primary,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ];

        return Scaffold(
          body: AutoVoiceNavigationListener(
            child: Semantics(container: true, child: body),
          ),
          bottomNavigationBar: Semantics(
            container: true,
            explicitChildNodes: true,
            label: strings.mainNavigationLandmark,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: navItems
                        .map((item) => Expanded(child: item))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(AppStrings.fr().errorGeneric),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/welcome'),
                child: Text(AppStrings.fr().login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.comingSoon});

  final String title;
  final String comingSoon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title — $comingSoon',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
