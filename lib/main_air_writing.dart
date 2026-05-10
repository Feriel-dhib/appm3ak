import 'package:flutter/material.dart';

import 'air_writing/air_writing_page.dart';

/// Point d'entree de test local du module air writing.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AirWritingTestApp());
}

class AirWritingTestApp extends StatelessWidget {
  const AirWritingTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma3ak Air Writing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const AirWritingPage(),
    );
  }
}
