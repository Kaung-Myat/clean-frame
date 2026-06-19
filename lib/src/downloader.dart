/// Handles communication with GitHub: listing branches, resolving the latest
/// branch, and downloading the template zip archive.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _owner = 'Kaung-Myat';
const _repo = 'clean-architecture-starter-kit';

const _branchesApiUrl = 'https://api.github.com/repos/$_owner/$_repo/branches';

/// Fetches the list of branch names from the GitHub API.
Future<List<String>> fetchBranches() async {
  final response = await http.get(
    Uri.parse(_branchesApiUrl),
    headers: {'Accept': 'application/vnd.github+json'},
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to fetch branches (HTTP ${response.statusCode}). '
      'Response: ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body) as List<dynamic>;
  return decoded
      .map((dynamic e) => (e as Map<String, dynamic>)['name'] as String)
      .toList();
}

/// Lists available branches to stdout. Triggered by the `--list` flag.
Future<void> listBranches() async {
  final branches = await fetchBranches();
  if (branches.isEmpty) {
    stdout.writeln('No branches found.');
    return;
  }

  stdout.writeln('Available template versions:');
  for (final branch in branches) {
    stdout.writeln('  - $branch');
  }
}

/// Resolves the latest branch by taking the last branch in the list.
Future<String> resolveLatestBranch() async {
  final branches = await fetchBranches();
  if (branches.isEmpty) {
    throw Exception('No branches available in the template repository.');
  }
  return branches.last;
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
