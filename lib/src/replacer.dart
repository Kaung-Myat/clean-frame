/// Walks the extracted template and replaces the placeholder app name, org and
/// bundle identifier with the user's values, then renames matching files and
/// directories.
library;

import 'dart:io';

const templateAppName = 'clean_frame_starter';
const templateOrg = 'com.example';
const templateBundleIdCamel = 'cleanFrameStarter'; // iOS uses camelCase

/// File extensions treated as binary and skipped during content replacement.
const _binaryExtensions = <String>{
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.svg',
  '.ico',
  '.ttf',
  '.otf',
  '.woff',
  '.woff2',
  '.eot',
  '.mp4',
  '.mp3',
  '.zip',
  '.jar',
  '.keystore',
  '.jks',
};

/// Converts `my_app_name` to `myAppName` for the iOS bundle identifier.
String toCamelCase(String input) {
  final parts = input.split('_');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

bool _isBinary(String path) {
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex == -1) return false;
  final ext = path.substring(dotIndex).toLowerCase();
  return _binaryExtensions.contains(ext);
}

/// Runs the full replacement and renaming pass over [projectDir].
Future<void> replaceInProject(
  Directory projectDir,
  String userAppName,
  String userOrg,
) async {
  _replaceContents(projectDir, userAppName, userOrg);
  _renameEntities(projectDir, userAppName);
}

void _replaceContents(
  Directory projectDir,
  String userAppName,
  String userOrg,
) {
  final userBundleCamel = toCamelCase(userAppName);

  for (final entity in projectDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (_isBinary(entity.path)) continue;

    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      // Not a readable text file; skip.
      continue;
    }

    // Order matters: most-specific strings first.
    final updated = content
        .replaceAll('$templateOrg.$templateAppName', '$userOrg.$userAppName')
        .replaceAll(templateBundleIdCamel, userBundleCamel)
        .replaceAll(templateAppName, userAppName);

    if (updated != content) {
      entity.writeAsStringSync(updated);
    }
  }
}

void _renameEntities(Directory projectDir, String userAppName) {
  // The Android Kotlin source directory is intentionally left untouched.
  final kotlinDir = '${projectDir.path}/android/app/src/main/kotlin';

  // Collect every entity, then sort by descending path depth so children are
  // renamed before their parents (bottom-up).
  final entities = projectDir.listSync(recursive: true).toList()
    ..sort((a, b) =>
        b.path.split(Platform.pathSeparator).length -
        a.path.split(Platform.pathSeparator).length);

  for (final entity in entities) {
    final path = entity.path;

    // Leave the Android Kotlin source subtree as-is.
    if (path.startsWith(kotlinDir)) continue;

    final name = path.split(Platform.pathSeparator).last;
    if (!name.contains(templateAppName)) continue;

    final parent = entity.parent.path;
    final newName = name.replaceAll(templateAppName, userAppName);
    final newPath = '$parent${Platform.pathSeparator}$newName';

    entity.renameSync(newPath);
  }
}
