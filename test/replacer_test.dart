import 'dart:io';

import 'package:clean_frame/src/replacer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('toCamelCase turns snake_case into an Apple bundle segment', () {
    expect(toCamelCase('my_app'), 'myApp');
    expect(toCamelCase('my_app_name'), 'myAppName');
    expect(toCamelCase('app'), 'app');
  });

  test('toDisplayName turns snake_case into a spaced title', () {
    expect(toDisplayName('my_app'), 'My App');
    expect(toDisplayName('clean_frame_starter'), 'Clean Frame Starter');
  });

  test('applyReplacements rewrites android and apple ids without touching urls',
      () {
    const input = '''
name: clean_frame_starter
import 'package:clean_frame_starter/app/app.dart';
namespace = "com.example.clean_frame_starter"
applicationId = "com.example.clean_frame_starter"
PRODUCT_BUNDLE_IDENTIFIER = com.example.riverpodDiTest;
PRODUCT_BUNDLE_IDENTIFIER = com.example.riverpodDiTest.RunnerTests;
PRODUCT_BUNDLE_IDENTIFIER = com.example.cleanFrameStarter;
CFBundleDisplayName = Riverpod Di Test
package com.example.riverpod_di_test
flutter_riverpod: ^3.3.1
https://api-dev.example.com
Copyright © 2026 com.example. All rights reserved.
''';

    final updated = applyReplacements(input, 'my_app', 'com.acme');

    expect(updated, contains('name: my_app'));
    expect(updated, contains("package:my_app/app/app.dart"));
    expect(updated, contains('namespace = "com.acme.my_app"'));
    expect(updated, contains('applicationId = "com.acme.my_app"'));
    expect(updated, contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.myApp;'));
    expect(
      updated,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.myApp.RunnerTests;'),
    );
    expect(updated, contains('CFBundleDisplayName = My App'));
    expect(updated, contains('package com.acme.my_app'));
    expect(updated, contains('flutter_riverpod: ^3.3.1'));
    expect(updated, contains('https://api-dev.example.com'));
    expect(updated,
        contains('Copyright © 2026 com.example. All rights reserved.'));
    expect(updated, isNot(contains('clean_frame_starter')));
    expect(updated, isNot(contains('riverpodDiTest')));
    expect(updated, isNot(contains('riverpod_di_test')));
    expect(updated, isNot(contains('cleanFrameStarter')));
    expect(updated, isNot(contains('Riverpod Di Test')));
  });

  test('replaceInProject moves the stale kotlin tree onto the new package',
      () async {
    final root = Directory.systemTemp.createTempSync('clean_frame_replace_');
    addTearDown(() => root.deleteSync(recursive: true));

    final kotlinDir = Directory(
      p.join(
        root.path,
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'com',
        'example',
        'riverpod_di_test',
      ),
    )..createSync(recursive: true);
    File(p.join(kotlinDir.path, 'MainActivity.kt')).writeAsStringSync(
      'package com.example.clean_frame_starter\n\nclass MainActivity\n',
    );
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
      'name: clean_frame_starter\n'
      '  flutter_riverpod: ^3.3.1\n',
    );
    File(p.join(root.path, 'project.pbxproj')).writeAsStringSync(
      'PRODUCT_BUNDLE_IDENTIFIER = com.example.riverpodDiTest;\n'
      'PRODUCT_BUNDLE_IDENTIFIER = com.example.riverpodDiTest.RunnerTests;\n'
      'PRODUCT_NAME = clean_frame_starter\n',
    );
    File(p.join(root.path, 'build.gradle.kts')).writeAsStringSync(
      'namespace = "com.example.clean_frame_starter"\n'
      'applicationId = "com.example.clean_frame_starter"\n',
    );

    await replaceInProject(root, 'my_app', 'com.acme');

    final moved = File(
      p.join(
        root.path,
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'com',
        'acme',
        'my_app',
        'MainActivity.kt',
      ),
    );
    expect(moved.existsSync(), isTrue);
    expect(
      moved.readAsStringSync(),
      contains('package com.acme.my_app'),
    );
    expect(
      Directory(p.join(root.path, 'android', 'app', 'src', 'main', 'kotlin',
              'com', 'example'))
          .existsSync(),
      isFalse,
    );
    expect(
      File(p.join(root.path, 'project.pbxproj')).readAsStringSync(),
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.myApp.RunnerTests;'),
    );
    expect(
      File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
      contains('flutter_riverpod:'),
    );
  });

  test('assertNoTemplateLeftovers reports a file the rename missed', () {
    final root = Directory.systemTemp.createTempSync('clean_frame_leftover_');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'stuck.txt'))
        .writeAsStringSync('com.example.riverpodDiTest');

    expect(
      () => assertNoTemplateLeftovers(root),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('stuck.txt'),
        ),
      ),
    );
  });
}
