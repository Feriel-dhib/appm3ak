import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/ai/voice_intent_models.dart';
import '../../providers/voice_mode_providers.dart';

/// Widget qui écoute les changements de route GoRouter et déclenche
/// automatiquement la lecture TTS quand le mode vocal persistant est actif.
///
/// À placer dans le MaterialApp ou en wrapper du contenu principal.
class AutoVoiceNavigationListener extends ConsumerStatefulWidget {
  const AutoVoiceNavigationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoVoiceNavigationListener> createState() =>
      _AutoVoiceNavigationListenerState();
}

class _AutoVoiceNavigationListenerState
    extends ConsumerState<AutoVoiceNavigationListener> {
  String? _lastRoute;
  Timer? _readDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRouteChange();
    });
  }

  void _checkRouteChange() {
    if (!mounted) return;

    try {
      final location = GoRouterState.of(context).uri.toString();
      final voiceState = ref.read(voiceModeProvider);

      if (!voiceState.isActive) return;
      if (location == _lastRoute) return;
      if (location == voiceState.lastReadRoute) return;

      _lastRoute = location;
      ref.read(voiceModeProvider.notifier).updateCurrentRoute(location);

      // Debounce pour éviter de lire pendant les navigations rapides.
      _readDebounce?.cancel();
      _readDebounce = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _triggerAutoRead(location);
      });
    } catch (_) {
      // GoRouterState.of peut échouer si le contexte n'est pas dans l'arbre GoRouter.
    }
  }

  Future<void> _triggerAutoRead(String route) async {
    if (!mounted) return;

    // Vibration courte pour signaler le changement de page.
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}

    final voiceState = ref.read(voiceModeProvider);
    if (!voiceState.isActive) return;

    // Extraire le titre et les éléments de la page actuelle.
    final screenInfo = _extractScreenInfo(route);

    final reader = ref.read(autoScreenReaderProvider);
    await reader.readScreen(
      title: screenInfo.title,
      items: screenInfo.items,
    );

    if (mounted) {
      ref.read(voiceModeProvider.notifier).markRouteAsRead(route);
    }
  }

  _ScreenInfo _extractScreenInfo(String route) {
    // Mapping simple route → titre + éléments principaux.

    if (route.contains('/transport/request')) {
      return _ScreenInfo(
        title: 'Nouvelle demande de transport',
        items: [
          const ScreenSummaryItem(
            label: 'Formulaire de demande',
            hint:
                'Remplissez le lieu de départ, le lieu d\'arrivée, la date et l\'heure.',
          ),
          const ScreenSummaryItem(
            label: 'Bouton valider',
            hint: 'Envoyez votre demande de course adaptée.',
          ),
        ],
      );
    }

    if (route.contains('/transport/obstacle-detection')) {
      return _ScreenInfo(
        title: 'Détection d\'obstacles',
        items: [
          const ScreenSummaryItem(
            label: 'Caméra en temps réel',
            hint: 'Annonce vocale des obstacles détectés devant vous.',
          ),
          const ScreenSummaryItem(
            label: 'Bouton retour',
            hint: 'Revenir à l\'écran précédent.',
          ),
        ],
      );
    }

    if (route.contains('/transport/hub') || route.contains('tab=2')) {
      return _ScreenInfo(
        title: 'Hub Transport',
        items: [
          const ScreenSummaryItem(
            label: 'Mes demandes',
            hint: 'Voir l\'historique de vos courses.',
          ),
          const ScreenSummaryItem(
            label: 'Nouvelle demande',
            hint: 'Créer une demande de transport adapté.',
          ),
          const ScreenSummaryItem(
            label: 'Détection obstacles',
            hint: 'Ouvrir la caméra de détection d\'obstacles.',
          ),
        ],
      );
    }

    if (route.contains('/home') || route.contains('tab=0')) {
      return _ScreenInfo(
        title: 'Accueil Ma3ak',
        items: [
          const ScreenSummaryItem(
            label: 'Onglet Accueil',
            hint: 'Services rapides et raccourcis.',
          ),
          const ScreenSummaryItem(
            label: 'Onglet Santé',
            hint: 'Services médicaux et chat IA.',
          ),
          const ScreenSummaryItem(
            label: 'Onglet Transport',
            hint: 'Tous vos déplacements adaptés.',
          ),
          const ScreenSummaryItem(
            label: 'Onglet Communauté',
            hint: 'Discussions et entraide.',
          ),
        ],
      );
    }

    if (route.contains('/accessible-places')) {
      return _ScreenInfo(
        title: 'Lieux accessibles',
        items: [
          const ScreenSummaryItem(
            label: 'Carte interactive',
            hint: 'Parcourez les lieux adaptés autour de vous.',
          ),
          const ScreenSummaryItem(
            label: 'Liste des lieux',
            hint: 'Affichage en liste pour navigation facilitée.',
          ),
        ],
      );
    }

    if (route.contains('/profile')) {
      return _ScreenInfo(
        title: 'Mon profil',
        items: [
          const ScreenSummaryItem(
            label: 'Informations personnelles',
            hint: 'Nom, email, téléphone.',
          ),
          const ScreenSummaryItem(
            label: 'Paramètres',
            hint: 'Modifier vos préférences.',
          ),
          const ScreenSummaryItem(
            label: 'Déconnexion',
            hint: 'Se déconnecter de l\'application.',
          ),
        ],
      );
    }

    if (route.contains('/notifications')) {
      return _ScreenInfo(
        title: 'Notifications',
        items: [
          const ScreenSummaryItem(
            label: 'Liste des notifications',
            hint: 'Vos dernières alertes et messages.',
          ),
        ],
      );
    }

    // Fallback générique.
    return _ScreenInfo(
      title: 'Nouvelle page',
      items: [
        const ScreenSummaryItem(
          label: 'Page chargée',
          hint: 'Explorez le contenu disponible.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _readDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements de state pour déclencher la vérification.
    ref.listen(voiceModeProvider, (previous, next) {
      if (next.isActive && next.currentRoute != next.lastReadRoute) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkRouteChange();
        });
      }
    });

    return widget.child;
  }
}

class _ScreenInfo {
  const _ScreenInfo({required this.title, required this.items});

  final String title;
  final List<ScreenSummaryItem> items;
}
