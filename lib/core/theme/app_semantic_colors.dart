import 'package:flutter/material.dart';

/// Couleurs sémantiques exposées via `ThemeExtension`.
///
/// Au lieu d'écrire `Colors.red` en dur dans un écran (qui ignore le thème
/// clair/sombre et le `ColorScheme`), utilisez :
///
/// ```dart
/// final semantic = Theme.of(context).extension<AppSemanticColors>()!;
/// Icon(Icons.error, color: semantic.danger);
/// ```
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
  });

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;

  final Color success;
  final Color onSuccess;
  final Color successContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;

  /// Couleurs sémantiques pour le thème clair — calées sur la palette rose/violet.
  static const AppSemanticColors light = AppSemanticColors(
    danger: Color(0xFFB71C1C),
    onDanger: Colors.white,
    dangerContainer: Color(0xFFFFE5E5),
    success: Color(0xFF1B5E20),
    onSuccess: Colors.white,
    successContainer: Color(0xFFE3F4E4),
    warning: Color(0xFFE65100),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFF1E0),
    info: Color(0xFF0D47A1),
    onInfo: Colors.white,
    infoContainer: Color(0xFFE3EDFF),
  );

  /// Couleurs sémantiques pour le thème sombre — adaptées à la palette nuit violette.
  static const AppSemanticColors dark = AppSemanticColors(
    danger: Color(0xFFFF8A8A),
    onDanger: Color(0xFF410002),
    dangerContainer: Color(0xFF5C1A1A),
    success: Color(0xFF7BD389),
    onSuccess: Color(0xFF003912),
    successContainer: Color(0xFF1F4D2A),
    warning: Color(0xFFFFB875),
    onWarning: Color(0xFF381C00),
    warningContainer: Color(0xFF5C3A1A),
    info: Color(0xFF9BC3FF),
    onInfo: Color(0xFF002A60),
    infoContainer: Color(0xFF1A3A6B),
  );

  @override
  AppSemanticColors copyWith({
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
  }) {
    return AppSemanticColors(
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

/// Sucre syntaxique pour récupérer rapidement les couleurs sémantiques.
extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
