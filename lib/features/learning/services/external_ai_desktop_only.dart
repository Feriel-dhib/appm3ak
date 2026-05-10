import 'external_ai_desktop_only_stub.dart'
    if (dart.library.io) 'external_ai_desktop_only_io.dart' as impl;

bool get canAutoLaunchExternalPythonTools =>
    impl.canAutoLaunchExternalPythonTools;
