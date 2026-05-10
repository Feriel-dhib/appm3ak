import 'package:appm3ak/core/widgets/accessible_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AccessibleButton expose un seul libellé sémantique', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AccessibleButton(
              label: 'Continuer',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AccessibleButton)),
      matchesSemantics(
        isButton: true,
        label: 'Continuer',
      ),
    );
  });
}
