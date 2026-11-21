import 'dart:io';

import 'package:clean_frame/src/cli_version.dart';
import 'package:test/test.dart';

void main() {
  test('cliVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true)
        .firstMatch(pubspec)
        ?.group(1);

    expect(version, cliVersion);
  });
}
