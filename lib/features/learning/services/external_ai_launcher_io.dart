import 'dart:io';

import 'external_ai_types.dart';

String _sep() => Platform.pathSeparator;

String _join(String a, String b, [String? c, String? d]) {
  var s = '$a${_sep()}$b';
  if (c != null) s = '$s${_sep()}$c';
  if (d != null) s = '$s${_sep()}$d';
  return s;
}

Future<ExternalLaunchResult> launchEyeGazeNavigationDemo() async {
  final root = _iaAccessibiliteRoot();
  final script = _join(root, 'eye_gaze_navigation_demo.py');
  if (!File(script).existsSync()) {
    return ExternalLaunchResult(
      ok: false,
      message:
          'Script introuvable : $script\nPlacez le dossier ia_accessibilite dans votre dossier utilisateur '
          '(ex. C:\\Users\\VotreNom\\ia_accessibilite) ou modifiez les chemins dans le code.',
    );
  }
  final run = _resolvePythonRun(root, venvFolder: 'venv');
  return _startDetached(
    executable: run.exe,
    arguments: run.argsFollowedBy([script]),
    workingDirectory: root,
    label: 'Navigation par le regard',
  );
}

Future<ExternalLaunchResult> launchM3akSignStudio() async {
  final root = _m3akSignRoot();
  final script = _join(root, 'main.py');
  if (!File(script).existsSync()) {
    return ExternalLaunchResult(
      ok: false,
      message:
          'Script introuvable : $script\nPlacez le dossier m3ak-sign dans votre dossier utilisateur.',
    );
  }
  final run = _resolvePythonRun(root, venvFolder: 'm3ak_env');
  return _startDetached(
    executable: run.exe,
    arguments: run.argsFollowedBy([script]),
    workingDirectory: root,
    label: 'M3AK Sign (audio → signes)',
  );
}

class _PythonRun {
  _PythonRun(this.exe, this._prefix);
  final String exe;
  final List<String> _prefix;

  List<String> argsFollowedBy(List<String> tail) => [..._prefix, ...tail];
}

String _userHome() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
  }
  return Platform.environment['HOME'] ?? '';
}

String _iaAccessibiliteRoot() => _join(_userHome(), 'ia_accessibilite');

String _m3akSignRoot() => _join(_userHome(), 'm3ak-sign');

_PythonRun _resolvePythonRun(String projectRoot, {required String venvFolder}) {
  if (Platform.isWindows) {
    final venvPy = _join(projectRoot, venvFolder, 'Scripts', 'python.exe');
    if (File(venvPy).existsSync()) {
      return _PythonRun(venvPy, const []);
    }
    return _PythonRun('py', const ['-3']);
  }
  final venvPy = _join(projectRoot, venvFolder, 'bin', 'python3');
  if (File(venvPy).existsSync()) {
    return _PythonRun(venvPy, const []);
  }
  return _PythonRun('python3', const []);
}

Future<ExternalLaunchResult> _startDetached({
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
  required String label,
}) async {
  if (workingDirectory.isEmpty || !Directory(workingDirectory).existsSync()) {
    return ExternalLaunchResult(
      ok: false,
      message: 'Dossier projet introuvable : $workingDirectory',
    );
  }

  try {
    await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.detached,
    );
    return ExternalLaunchResult(
      ok: true,
      message:
          '$label : processus lancé. Une fenêtre (terminal ou application) devrait s’ouvrir sur votre PC.',
    );
  } catch (e) {
    return ExternalLaunchResult(
      ok: false,
      message:
          'Impossible de lancer automatiquement. Copiez la commande ci-dessous dans PowerShell ou CMD. Détail : $e',
    );
  }
}
