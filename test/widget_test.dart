import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appm3ak/app.dart';

void main() {
  testWidgets('Ma3ak app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Ma3akApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
