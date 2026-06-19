/// Validates the app name provided by the user before any work is done.
library;

/// Dart reserved keywords that cannot be used as an app/package name.
const _reservedKeywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

final _namePattern = RegExp(r'^[a-z][a-z0-9_]*$');

/// Result of validating an app name.
class ValidationResult {
  const ValidationResult.valid()
      : isValid = true,
        error = null;

  const ValidationResult.invalid(this.error) : isValid = false;

  final bool isValid;
  final String? error;
}

/// Validates [name] against the naming rules.
///
/// Rules:
/// - must not be empty
/// - must match `^[a-z][a-z0-9_]*$`
/// - must not be a Dart reserved keyword
ValidationResult validateAppName(String name) {
  if (name.isEmpty) {
    return const ValidationResult.invalid('App name must not be empty.');
  }

  if (!_namePattern.hasMatch(name)) {
    return ValidationResult.invalid(
      'Invalid app name "$name". '
      'Use snake_case: start with a lowercase letter and use only '
      'lowercase letters, digits and underscores (e.g. my_app).',
    );
  }

  if (_reservedKeywords.contains(name)) {
    return ValidationResult.invalid(
      'App name "$name" is a Dart reserved keyword and cannot be used.',
    );
  }

  return const ValidationResult.valid();
}
