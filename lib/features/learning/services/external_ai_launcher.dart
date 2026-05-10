import 'external_ai_launcher_stub.dart'
    if (dart.library.io) 'external_ai_launcher_io.dart' as impl;
import 'external_ai_types.dart';

export 'external_ai_types.dart';

Future<ExternalLaunchResult> launchEyeGazeNavigationDemo() =>
    impl.launchEyeGazeNavigationDemo();

Future<ExternalLaunchResult> launchM3akSignStudio() =>
    impl.launchM3akSignStudio();
