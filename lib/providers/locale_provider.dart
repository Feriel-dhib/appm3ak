import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import 'auth_providers.dart';

const String _kLocaleOverrideKey = 'm3ak_locale_override';

/// Override manuel de la locale, persisté via `SharedPreferences`.
///
/// Permet à l'utilisateur de forcer une langue depuis l'écran Profil sans
/// avoir à mettre à jour son profil côté backend. `null` = pas d'override.
final localeOverrideProvider =
    StateNotifierProvider<LocaleOverrideNotifier, Locale?>(
  (ref) => LocaleOverrideNotifier(),
);

class LocaleOverrideNotifier extends StateNotifier<Locale?> {
  LocaleOverrideNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleOverrideKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  /// Force la locale pour toute l'app. Passe `null` pour revenir au comportement
  /// piloté par le profil utilisateur / le système.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocaleOverrideKey);
    } else {
      await prefs.setString(_kLocaleOverrideKey, locale.languageCode);
    }
  }
}

/// Locale effective de l'app : override manuel > préférence utilisateur > système (`null`).
///
/// **Important** : retourner `null` est volontaire. `MaterialApp.locale = null`
/// laisse Flutter résoudre la locale via `supportedLocales` + locale système,
/// ce qui est le comportement correct par défaut (RTL fonctionnel pour l'arabe).
final localeProvider = Provider<Locale?>((ref) {
  final override = ref.watch(localeOverrideProvider);
  if (override != null) return override;

  final auth = ref.watch(authStateProvider);
  final user = auth.value;
  final pref = user?.preferredLanguage;
  switch (pref) {
    case PreferredLanguage.ar:
      return const Locale('ar');
    case PreferredLanguage.fr:
      return const Locale('fr');
    case PreferredLanguage.en:
      return const Locale('en');
    case null:
      return null;
  }
});
