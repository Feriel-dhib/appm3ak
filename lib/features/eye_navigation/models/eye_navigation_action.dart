/// Actions renvoyées par le backend Flask (`POST /eye-navigation`).
enum EyeNavigationAction {
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  click,
  idle,
}

/// Correspondance avec les chaînes JSON `{ "action": "..." }`.
extension EyeNavigationActionBackend on EyeNavigationAction {
  /// Valeur attendue par / envoyée par l’API (snake_case).
  String get backendValue => switch (this) {
        EyeNavigationAction.moveLeft => 'move_left',
        EyeNavigationAction.moveRight => 'move_right',
        EyeNavigationAction.moveUp => 'move_up',
        EyeNavigationAction.moveDown => 'move_down',
        EyeNavigationAction.click => 'click',
        EyeNavigationAction.idle => 'idle',
      };

  /// Vrai si l’action permet de piloter le focus / la sélection (à brancher sur votre UI).
  bool get isNavigational =>
      this != EyeNavigationAction.idle;

  /// Directions uniquement (exclut clic et idle).
  bool get isDirectional => switch (this) {
        EyeNavigationAction.moveLeft ||
        EyeNavigationAction.moveRight ||
        EyeNavigationAction.moveUp ||
        EyeNavigationAction.moveDown =>
          true,
        _ => false,
      };
}

extension EyeNavigationActionParse on String {
  EyeNavigationAction toEyeNavigationAction() {
    final n = trim().toLowerCase();
    return switch (n) {
      'move_left' => EyeNavigationAction.moveLeft,
      'move_right' => EyeNavigationAction.moveRight,
      'move_up' => EyeNavigationAction.moveUp,
      'move_down' => EyeNavigationAction.moveDown,
      'click' => EyeNavigationAction.click,
      'idle' => EyeNavigationAction.idle,
      _ => EyeNavigationAction.idle,
    };
  }
}
