# clean_frame

A CLI tool to scaffold Flutter projects with Clean Architecture and Riverpod DI.

## Installation

    dart pub global activate clean_frame

## Usage

    clean_frame -n my_app
    clean_frame -n my_app -o com.yourcompany
    clean_frame -n my_app -v v2.3.0
    clean_frame -l
    clean_frame --cli-version

`-l` lists version **branches** named `vX.Y.Z` on the template repo (not GitHub
Release tags). Omitting `-v` pulls the highest of those branches. After a
successful create, run the dev flavor (`DEMO_MODE` is on, so no API is required):

    cd my_app
    flutter run --dart-define-from-file=env/dev.json

## Flags

| Flag | Description |
|---|---|
| `-n`, `--name` | App name in snake_case (required) |
| `-o`, `--org` | Organisation prefix (default: com.example) |
| `-v`, `--version` | Template branch `vX.Y.Z` (default: highest) |
| `-l`, `--list` | List template version branches |
| `--cli-version` | Print the clean_frame CLI version |
| `-h`, `--help` | Show help |

## Template

[clean-architecture-starter-kit](https://github.com/Kaung-Myat/clean-architecture-starter-kit)
