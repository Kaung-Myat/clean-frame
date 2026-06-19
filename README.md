# clean_frame

A CLI tool to scaffold Flutter projects with Clean Architecture and Riverpod DI.

## Installation

    dart pub global activate clean_frame

## Usage

    clean_frame -n my_app
    clean_frame -n my_app -o com.yourcompany
    clean_frame -n my_app -v v1.0.0
    clean_frame -l

## Flags

| Flag | Description |
|---|---|
| `-n`, `--name` | App name in snake_case (required) |
| `-o`, `--org` | Organisation prefix (default: com.example) |
| `-v`, `--version` | Template version/branch (default: latest) |
| `-l`, `--list` | List available template versions |
| `-h`, `--help` | Show help |

## Template

[clean-architecture-starter-kit](https://github.com/Kaung-Myat/clean-architecture-starter-kit)
