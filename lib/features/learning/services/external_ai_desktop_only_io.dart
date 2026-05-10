import 'dart:io';

/// Lancement de scripts Python locaux : pertinent surtout sur Windows/macOS/Linux bureau.
bool get canAutoLaunchExternalPythonTools =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
