import 'package:appm3ak/data/models/sos_alert_model.dart';
import 'package:appm3ak/features/sos/screens/sos_for_accompagnant_screen.dart';
import 'package:appm3ak/providers/sos_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('affiche la liste SOS accompagnant', (tester) async {
    final sample = <SosAlertModel>[
      const SosAlertModel(
        id: '1',
        latitude: 36.8,
        longitude: 10.18,
        statut: 'EN_ATTENTE',
        alertSource: 'MANUAL',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sosAlertsForAccompagnantProvider.overrideWith(
            (_) async => sample,
          ),
        ],
        child: const MaterialApp(
          home: SosForAccompagnantScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('SOS recus (accompagnant)'), findsOneWidget);
    expect(find.textContaining('36.80000, 10.18000'), findsOneWidget);
    expect(find.textContaining('Statut: EN_ATTENTE'), findsOneWidget);
  });
}
