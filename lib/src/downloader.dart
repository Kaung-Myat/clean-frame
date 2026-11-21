/// Handles communication with GitHub: listing branches, resolving the latest
/// branch, and downloading the template zip archive.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _owner = 'Kaung-Myat';
const _repo = 'clean-architecture-starter-kit';

const _branchesApiUrl = 'https://api.github.com/repos/$_owner/$_repo/branches';

final _versionBranch = RegExp(r'^v(\d+)\.(\d+)\.(\d+)$');

/// Fetches every branch name from the GitHub API.
///
/// The branches endpoint is paginated. Stopping at the first page would hide
/// later version branches.
Future<List<String>> fetchBranches() async {
  final names = <String>[];
  var page = 1;

  while (true) {
    final response = await http.get(
      Uri.parse('$_branchesApiUrl?per_page=100&page=$page'),
      headers: {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch branches (HTTP ${response.statusCode}). '
        'Response: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) break;

    names.addAll(
      decoded.map(
        (dynamic e) => (e as Map<String, dynamic>)['name'] as String,
      ),
    );
    if (decoded.length < 100) break;
    page++;
  }

  return names;
}

/// Lists `vX.Y.Z` template branches to stdout. Triggered by the `--list` flag.
///
/// These are GitHub **branch** names on the template repo, not Release tags.
/// Other branch names (`main`, `wip`) are omitted. Versions are printed in
/// ascending semver order.
Future<void> listBranches() async {
  final releases = releaseBranches(await fetchBranches());
  if (releases.isEmpty) {
    stdout.writeln('No template version branches found.');
    return;
  }

  stdout.writeln('Available template version branches:');
  for (final branch in releases) {
    stdout.writeln('  - $branch');
  }
}

/// Resolves the highest `vX.Y.Z` branch.
///
/// GitHub returns branches alphabetically, so the last name is not the latest
/// release (`v2.10.0` sorts before `v2.3.0`).
Future<String> resolveLatestBranch() async {
  return latestVersionBranch(await fetchBranches());
}

/// `vX.Y.Z` branch names from [branches], oldest first.
///
/// Branches that are not that shape (`main`, `wip`) are dropped.
List<String> releaseBranches(List<String> branches) {
  final versions = <_VersionBranch>[];
  for (final name in branches) {
    final parsed = _VersionBranch.tryParse(name);
    if (parsed != null) versions.add(parsed);
  }
  versions.sort();
  return versions.map((version) => version.name).toList();
}

/// Picks the highest `vMAJOR.MINOR.PATCH` name from [branches].
String latestVersionBranch(List<String> branches) {
  final releases = releaseBranches(branches);
  if (releases.isEmpty) {
    throw Exception(
      'No version branches (vX.Y.Z) found in the template repository.',
    );
  }
  return releases.last;
}

/// Error text used when `-v` names a branch that is not a template version.
String unknownTemplateVersionMessage(String requested, List<String> releases) {
  final buffer = StringBuffer(
    'Unknown template version branch "$requested".',
  );
  if (releases.isEmpty) {
    buffer.write(' No vX.Y.Z branches were found.');
    return buffer.toString();
  }

  buffer.writeln();
  buffer.writeln('Available version branches:');
  for (final version in releases) {
    buffer.writeln('  - $version');
  }
  return buffer.toString().trimRight();
}

class _VersionBranch implements Comparable<_VersionBranch> {
  const _VersionBranch(this.name, this.major, this.minor, this.patch);

  final String name;
  final int major;
  final int minor;
  final int patch;

  static _VersionBranch? tryParse(String name) {
    final match = _versionBranch.firstMatch(name);
    if (match == null) return null;
    return _VersionBranch(
      name,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(_VersionBranch other) {
    final majorDiff = major.compareTo(other.major);
    if (majorDiff != 0) return majorDiff;
    final minorDiff = minor.compareTo(other.minor);
    if (minorDiff != 0) return minorDiff;
    return patch.compareTo(other.patch);
  }
}

/// Downloads the template zip for [branch] into the system temp directory.
///
/// Returns the path to the downloaded zip file.
Future<File> downloadTemplate(String branch) async {
  final zipUrl =
      'https://github.com/$_owner/$_repo/archive/refs/heads/$branch.zip';

  final response = await http.get(Uri.parse(zipUrl));
  if (response.statusCode != 200) {
    throw Exception(
      'Failed to download template "$branch" (HTTP ${response.statusCode}).',
    );
  }

  final tempDir = Directory.systemTemp;
  final zipFile = File(
    '${tempDir.path}/clean_frame_${DateTime.now().millisecondsSinceEpoch}.zip',
  );
  await zipFile.writeAsBytes(response.bodyBytes);
  return zipFile;
}
