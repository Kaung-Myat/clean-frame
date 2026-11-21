## 1.3.0

- Docs and `--list` / `--version` help text say version **branches** (`vX.Y.Z`), not GitHub Release tags.
- Friendly errors when `git` or `flutter` is missing from PATH.
- Temp-zip cleanup failures no longer delete a finished project directory.
- Replace legacy iOS display name `Riverpod Di Test` with a title-cased app name.
- Add `.gitignore`.

## 1.2.0

- `--list` prints only `vX.Y.Z` template version branches, oldest first.
- `--version` rejects an unknown branch and prints the versions that exist before downloading.
- `--cli-version` prints the clean_frame package version.
- The success message includes `flutter run --dart-define-from-file=env/dev.json`.

## 1.1.0

- Pick the highest `vX.Y.Z` branch when `--version` is omitted.
- Delete the project directory when download, extract, or rename fails.
- Exit with an error when `git init` or `flutter pub get` fails, instead of printing success.
- Rename Android, iOS, and macOS package ids, including the legacy `riverpodDiTest` bundle id, and move the Kotlin source tree to match the package declaration.

## 1.0.0

- Initial release.
- Scaffold Flutter Clean Architecture + Riverpod DI project from template.
- Supports --name, --org, --version, --list, --help flags.
- Automatic Level 2 rename: pubspec, Dart imports, Android IDs, iOS bundle.
- Runs git init and flutter pub get automatically after setup.
