/// Post-extraction setup: cleans up the temp zip, initialises git, runs
/// `flutter pub get`, and prints the success message.
library;

import 'dart:io';

/// Deletes the downloaded zip from the temp directory.
Future<void> cleanupZip(File zipFile) async {
  if (await zipFile.exists()) {
    await zipFile.delete();
  }
}

/// Runs `git init` inside [projectDir].
///
/// Returns `false` when git is missing or exits non-zero. The caller must not
/// report success.
Future<bool> gitInit(Directory projectDir) async {
  try {
    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: projectDir.path,
    );
    if (result.exitCode != 0) {
      stderr.writeln('git init failed: ${result.stderr}');
      return false;
    }
    return true;
  } on ProcessException catch (error) {
    stderr.writeln(
      'git is not available on PATH. Install git, then run '
      '`git init` inside the project.\n${error.message}',
    );
    return false;
  }
}

/// Runs `flutter pub get` inside [projectDir], streaming output to the terminal.
///
/// Returns `false` when Flutter is missing or exits non-zero. The caller must
/// not report success.
Future<bool> flutterPubGet(Directory projectDir) async {
  try {
    final process = await Process.start(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('flutter pub get exited with code $exitCode.');
      return false;
    }
    return true;
  } on ProcessException catch (error) {
    stderr.writeln(
      'flutter is not available on PATH. Install Flutter, then run '
      '`flutter pub get` inside the project.\n${error.message}',
    );
    return false;
  }
}

/// Deletes a half-created project directory left behind by a failed scaffold.
Future<void> deleteIncompleteProject(Directory projectDir) async {
  if (await projectDir.exists()) {
    await projectDir.delete(recursive: true);
  }
}

/// Prints the success block after package rename has finished.
void printSuccess(String appName, String org) {
  stdout.writeln('''

✓ Project created successfully!

  App name : $appName
  Location : ./$appName/
  Org      : $org

Run it with the dev flavor. DEMO_MODE is on, so no API is required:

  cd $appName
  flutter run --dart-define-from-file=env/dev.json

Happy coding!''');
}
