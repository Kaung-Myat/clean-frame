import 'package:clean_frame/src/downloader.dart';
import 'package:test/test.dart';

void main() {
  test('latestVersionBranch picks the highest semver, not the last name', () {
    expect(
      latestVersionBranch([
        'main',
        'v1.0.0',
        'v2.0.0',
        'v2.10.0',
        'v2.3.0',
        'v2.9.0',
        'wip',
      ]),
      'v2.10.0',
    );
  });

  test('latestVersionBranch ignores a higher alphabetical non-version branch',
      () {
    expect(
      latestVersionBranch(['v2.3.0', 'zzz-latest']),
      'v2.3.0',
    );
  });

  test('releaseBranches drops non-releases and sorts by semver', () {
    expect(
      releaseBranches(['wip', 'v2.10.0', 'main', 'v2.3.0', 'v1.0.0']),
      ['v1.0.0', 'v2.3.0', 'v2.10.0'],
    );
  });

  test('unknownTemplateVersionMessage lists the releases the user can pass',
      () {
    final message = unknownTemplateVersionMessage(
      'v9.9.9',
      ['v2.2.0', 'v2.3.0'],
    );

    expect(message, contains('Unknown template version branch "v9.9.9"'));
    expect(message, contains('v2.2.0'));
    expect(message, contains('v2.3.0'));
  });

  test('latestVersionBranch rejects a list with no vX.Y.Z branch', () {
    expect(
      () => latestVersionBranch(['main', 'dev']),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('No version branches'),
        ),
      ),
    );
  });
}
