import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/ma3ak_device_context.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Ma3akDeviceContext.init();
  runApp(
    const ProviderScope(
      child: Ma3akApp(),
    ),
  );
}
