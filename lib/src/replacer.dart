/// Walks the extracted template and replaces the placeholder app name, org and
/// bundle identifier with the user's values, then renames matching files and
/// directories.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

const templateAppName = 'clean_frame_starter';
const templateOrg = 'com.example';
const templateBundleIdCamel = 'cleanFrameStarter';

/// Previous template identity still present on older published branches.
/// Replaced alongside [templateAppName] so `-v v2.3.0` keeps working.
const legacyAppName = 'riverpod_di_test';
const legacyBundleIdCamel = 'riverpodDiTest';
const legacyDisplayName = 'Riverpod Di Test';

/// Identifiers that must not remain after a successful rename.
const templateLeftoverTokens = <String>[
  templateAppName,
  templateBundleIdCamel,
  legacyAppName,
  legacyBundleIdCamel,
  legacyDisplayName,
];

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

final _packagePattern = RegExp(
  r'^\s*package\s+([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)',
  multiLine: true,
);

/// Converts `my_app_name` to `myAppName` for the Apple bundle identifier.
String toCamelCase(String input) {
  final parts = input.split('_').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return input;
  return parts.first +
      parts
          .skip(1)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join();
}

/// Converts `my_app_name` to `My App Name` for CFBundleDisplayName.
String toDisplayName(String input) {
  final parts = input.split('_').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return input;
  return parts
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

/// Replaces template identifiers in [content].
///
/// Longer, platform-specific ids are replaced before the bare app name so
/// `com.example.clean_frame_starter` does not get partially rewritten.
/// Android ids stay snake_case. Apple bundle ids use camelCase.
/// Bare `com.example` is left alone so example URLs are not rewritten.
String applyReplacements(String content, String userAppName, String userOrg) {
  final userBundleCamel = toCamelCase(userAppName);
  final userDisplayName = toDisplayName(userAppName);
  return content
      .replaceAll(
          '$templateOrg.$legacyBundleIdCamel', '$userOrg.$userBundleCamel')
      .replaceAll(
          '$templateOrg.$templateBundleIdCamel', '$userOrg.$userBundleCamel')
      .replaceAll('$templateOrg.$legacyAppName', '$userOrg.$userAppName')
      .replaceAll('$templateOrg.$templateAppName', '$userOrg.$userAppName')
      .replaceAll(legacyDisplayName, userDisplayName)
      .replaceAll(legacyBundleIdCamel, userBundleCamel)
      .replaceAll(templateBundleIdCamel, userBundleCamel)
      .replaceAll(legacyAppName, userAppName)
      .replaceAll(templateAppName, userAppName);
}

bool _isBinary(String path) {
  final ext = p.extension(path).toLowerCase();
  return _binaryExtensions.contains(ext);
}

/// Runs the full replacement and renaming pass over [projectDir].
///
/// Throws if a template identifier is still present when the pass finishes.
Future<void> replaceInProject(
  Directory projectDir,
  String userAppName,
  String userOrg,
) async {
  _replaceContents(projectDir, userAppName, userOrg);
  _relocateAndroidSources(projectDir);
  _renameEntities(projectDir, userAppName);
  assertNoTemplateLeftovers(projectDir);
}

void _replaceContents(
  Directory projectDir,
  String userAppName,
  String userOrg,
) {
  for (final entity in projectDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (_isBinary(entity.path)) continue;

    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }

    final updated = applyReplacements(content, userAppName, userOrg);
    if (updated != content) {
      entity.writeAsStringSync(updated);
    }
  }
}

/// Moves Kotlin/Java sources so their directory matches the `package` line.
///
/// The template Kotlin tree is `kotlin/com/example/riverpod_di_test/` while
/// `MainActivity.kt` declares `package com.example.clean_frame_starter`. A leaf
/// rename cannot fix the org segments, so the file is moved from the package
/// declaration after text replacement.
void _relocateAndroidSources(Directory projectDir) {
  final srcRoot = Directory(p.join(projectDir.path, 'android', 'app', 'src'));
  if (!srcRoot.existsSync()) return;

  final files =
      srcRoot.listSync(recursive: true).whereType<File>().where((file) {
    final ext = p.extension(file.path);
    return ext == '.kt' || ext == '.java';
  }).toList();

  for (final file in files) {
    final content = file.readAsStringSync();
    final match = _packagePattern.firstMatch(content);
    if (match == null) continue;

    final segments = p.split(file.path);
    final rootIndex = segments.lastIndexWhere(
      (segment) => segment == 'kotlin' || segment == 'java',
    );
    if (rootIndex == -1) continue;

    final sourceRoot = p.joinAll(segments.sublist(0, rootIndex + 1));
    final packageDir = match.group(1)!.replaceAll('.', p.separator);
    final destFile =
        File(p.join(sourceRoot, packageDir, p.basename(file.path)));
    if (p.equals(destFile.path, file.path)) continue;
    if (destFile.existsSync()) {
      throw Exception(
        'Cannot move ${file.path} to ${destFile.path}: destination already exists.',
      );
    }

    destFile.parent.createSync(recursive: true);
    file.renameSync(destFile.path);
    _deleteEmptyDirsUpTo(file.parent, Directory(sourceRoot));
  }
}

void _deleteEmptyDirsUpTo(Directory start, Directory stopAt) {
  var current = start;
  while (p.isWithin(stopAt.path, current.path)) {
    if (!current.existsSync() || current.listSync().isNotEmpty) break;
    final parent = current.parent;
    current.deleteSync();
    current = parent;
  }
}

void _renameEntities(Directory projectDir, String userAppName) {
  final entities = projectDir.listSync(recursive: true).toList()
    ..sort(
      (a, b) => p.split(b.path).length - p.split(a.path).length,
    );

  for (final entity in entities) {
    final name = p.basename(entity.path);
    final newName = applyReplacements(name, userAppName, templateOrg);
    if (newName == name) continue;

    final newPath = p.join(entity.parent.path, newName);
    entity.renameSync(newPath);
  }
}

/// Throws when [projectDir] still contains a template package identifier.
void assertNoTemplateLeftovers(Directory projectDir) {
  final hits = <String>{};

  for (final entity in projectDir.listSync(recursive: true)) {
    final relative = p.relative(entity.path, from: projectDir.path);
    if (_containsTemplateToken(p.basename(entity.path))) {
      hits.add(relative);
    }
    if (entity is! File || _isBinary(entity.path)) continue;

    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    if (_containsTemplateToken(content)) {
      hits.add(relative);
    }
  }

  if (hits.isEmpty) return;

  final listed = hits.toList()..sort();
  throw Exception(
    'Template identifiers were not fully replaced:\n'
    '${listed.map((hit) => '  - $hit').join('\n')}',
  );
}

bool _containsTemplateToken(String value) {
  for (final token in templateLeftoverTokens) {
    if (value.contains(token)) return true;
  }
  return false;
}
