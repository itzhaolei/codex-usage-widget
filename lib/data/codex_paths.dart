import 'dart:io';

/// Resolves the Codex data directory consistently for every repository.
String resolveCodexHome({
  String? override,
  Map<String, String>? environment,
  String? separator,
}) {
  final variables = environment ?? Platform.environment;
  final explicit = override ?? variables['CODEX_HOME'];
  if (explicit != null && explicit.trim().isNotEmpty) return explicit;
  final home = variables['USERPROFILE'] ?? variables['HOME'] ?? '.';
  return '$home${separator ?? Platform.pathSeparator}.codex';
}
