/// clean_frame — CLI entry point.
///
/// Parses arguments and orchestrates: validation, download, extraction,
/// replacement and post-setup.
library;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:clean_frame/src/downloader.dart';
import 'package:clean_frame/src/post_setup.dart';
import 'package:clean_frame/src/replacer.dart';
import 'package:clean_frame/src/validator.dart';

ArgParser _buildParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'App name (snake_case).')
    ..addOption('org',
        abbr: 'o', defaultsTo: 'com.example', help: 'Organisation prefix.')
    ..addOption('version',
        abbr: 'v', help: 'Template branch to pull (default: latest).')
    ..addFlag('list',
        abbr: 'l', negatable: false, help: 'List available template versions.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage.');
}

void _printUsage(ArgParser parser) {
  stdout
      .writeln('clean_frame — scaffold a Flutter Clean Architecture project.');
  stdout.writeln('');
  stdout.writeln('Usage: clean_frame -n <app_name> [options]');
  stdout.writeln('');
  stdout.writeln(parser.usage);
}

Future<void> main(List<String> arguments) async {
  final parser = _buildParser();

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    _printUsage(parser);
    exit(1);
  }

  if (args.flag('help')) {
    _printUsage(parser);
    return;
  }

  if (args.flag('list')) {
    try {
      await listBranches();
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
    return;
  }

  final name = args.option('name');
  if (name == null) {
    stderr.writeln('Error: --name (-n) is required.\n');
    _printUsage(parser);
    exit(1);
  }

  final validation = validateAppName(name);
  if (!validation.isValid) {
    stderr.writeln('Error: ${validation.error}');
    exit(1);
  }

  final org = args.option('org') ?? 'com.example';

  // Resolve the template version.
  String version;
  try {
    version = args.option('version') ?? await resolveLatestBranch();
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
  stdout.writeln('Using template version: $version');

  // Ensure the target folder does not already exist.
  final targetDir = Directory(name);
  if (targetDir.existsSync()) {
    stderr.writeln('Error: directory "./$name/" already exists.');
    exit(1);
  }

  File? zipFile;
  try {
    stdout.writeln('→ Downloading template $version...');
    zipFile = await downloadTemplate(version);

    stdout.writeln('→ Extracting...');
    final projectDir = await _extractTemplate(zipFile, targetDir);

    stdout.writeln('→ Renaming project to $name...');
    await replaceInProject(projectDir, name, org);

    await cleanupZip(zipFile);

    stdout.writeln('→ Initialising git...');
    await gitInit(projectDir);

    stdout.writeln('→ Running flutter pub get...');
    await flutterPubGet(projectDir);

    printSuccess(name, org);
  } catch (e) {
    stderr.writeln('Error: $e');
    if (zipFile != null) {
      await cleanupZip(zipFile);
    }
    exit(1);
  }
}

/// Extracts [zipFile] and moves the single top-level folder to [targetDir].
///
/// GitHub zips contain a single root folder named `<repo>-<branch>`; its
/// contents become the project at [targetDir].
Future<Directory> _extractTemplate(File zipFile, Directory targetDir) async {
  final bytes = await zipFile.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  // Extract into a temp staging directory first.
  final staging = Directory(
    '${Directory.systemTemp.path}/clean_frame_extract_'
    '${DateTime.now().millisecondsSinceEpoch}',
  )..createSync(recursive: true);

  for (final entry in archive) {
    final outPath = '${staging.path}/${entry.name}';
    if (entry.isFile) {
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(entry.content as List<int>);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
  }

  // The archive has a single root folder; move it to the target location.
  final roots = staging.listSync().whereType<Directory>().toList();
  if (roots.isEmpty) {
    throw Exception('Downloaded archive was empty.');
  }
  final root = roots.first;

  // Use copy + delete instead of rename: rename() fails with
  // "Invalid cross-device link" (errno 18) when /tmp and the destination are
  // on different filesystem mount points.
  await _copyDirectory(root, targetDir);
  await root.delete(recursive: true);
  staging.deleteSync(recursive: true);

  return targetDir;
}

/// Recursively copies [source] into [dest], creating directories as needed.
Future<void> _copyDirectory(Directory source, Directory dest) async {
  await dest.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    final destPath = p.join(dest.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destPath));
    } else if (entity is File) {
      await entity.copy(destPath);
    }
  }
}
