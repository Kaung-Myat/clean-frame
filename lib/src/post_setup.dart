/// Post-extraction setup: cleans up the temp zip, initialises git, runs
/// `flutter pub get`, and prints the success / manual-step message.
library;

import 'dart:io';

/// Deletes the downloaded zip from the temp directory.
Future<void> cleanupZip(File zipFile) async {
  if (await zipFile.exists()) {
    await zipFile.delete();
  }
}

/// Runs `git init` inside [projectDir].
Future<void> gitInit(Directory projectDir) async {
  final result = await Process.run(
    'git',
    ['init'],
    workingDirectory: projectDir.path,
  );
  if (result.exitCode != 0) {
    stderr.writeln('⚠  git init failed: ${result.stderr}');
  }
}

/// Runs `flutter pub get` inside [projectDir], streaming output to the terminal.
Future<void> flutterPubGet(Directory projectDir) async {
  final process = await Process.start(
    'flutter',
    ['pub', 'get'],
    workingDirectory: projectDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('⚠  flutter pub get exited with code $exitCode.');
  }
}

/// Prints the success block and the manual Android-rename notice.
void printSuccess(String appName, String org) {
  stdout.writeln('''

✓ Project created successfully!

  App name : $appName
  Location : ./$appName/
  Org      : $org

⚠  One manual step required:

  The Android Kotlin source directory still uses the template name.
  Rename this folder:

  FROM:  android/app/src/main/kotlin/com/example/clean_frame_starter/
  TO:    android/app/src/main/kotlin/com/example/$appName/

  Then update the package declaration inside MainActivity.kt to:
  package com.example.$appName

Happy coding!''');
}
