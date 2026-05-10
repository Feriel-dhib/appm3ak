// Tests automatiques des nœuds Semantics (complément aux essais manuels
// TalkBack sur Android et VoiceOver sur iOS).
//
// Manuel : Réglages > Accessibilité > TalkBack ou VoiceOver, puis parcourir
// l’app au focus (balayage / glisser) et vérifier libellés et ordre logique.

import 'package:appm3ak/core/widgets/ma3ak_bottom_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ma3akBottomNavItem expose un bouton avec libellé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Ma3akBottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Accueil',
              selected: false,
              primary: Colors.deepPurple,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Ma3akBottomNavItem)),
      matchesSemantics(
        isButton: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: false,
        label: 'Accueil',
        tooltip: 'Accueil',
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('Ma3akBottomNavItem reflète l’état sélectionné', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Ma3akBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Accueil',
            selected: true,
            primary: Colors.deepPurple,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Ma3akBottomNavItem)),
      matchesSemantics(
        isButton: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        label: 'Accueil',
        tooltip: 'Accueil',
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });
}
