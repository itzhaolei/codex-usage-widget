import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../core/models.dart';
import 'codex_paths.dart';

enum AuthReadStatus { authenticated, signedOut, transientFailure, unavailable }

class AuthReadResult {
  const AuthReadResult.authenticated(AuthInfo value)
    : status = AuthReadStatus.authenticated,
      auth = value;

  const AuthReadResult.signedOut()
    : status = AuthReadStatus.signedOut,
      auth = null;

  const AuthReadResult.transientFailure()
    : status = AuthReadStatus.transientFailure,
      auth = null;

  const AuthReadResult.unavailable()
    : status = AuthReadStatus.unavailable,
      auth = null;

  final AuthReadStatus status;
  final AuthInfo? auth;
}

/// Reads the account that Codex has already authenticated on this machine.
///
/// The access token is returned in memory for the usage request, but this
/// repository never writes it back to disk.  Keeping this concern separate
/// from the API client also makes account changes easy to detect and test.
class AuthRepository {
  AuthRepository({
    String? codexHome,
    String? authPath,
    Future<String> Function(String path)? readFile,
    Future<bool> Function(String path)? fileExists,
  }) : _authPath = authPath ?? _defaultAuthPath(codexHome),
       _readFile = readFile ?? ((path) => File(path).readAsString()),
       _fileExists = fileExists ?? ((path) => File(path).exists());

  final String _authPath;
  final Future<String> Function(String path) _readFile;
  final Future<bool> Function(String path) _fileExists;

  String get authPath => _authPath;

  Future<bool> get exists => _fileExists(_authPath);

  /// Returns null when auth.json does not contain a usable account.
  Future<AuthInfo?> read() async => (await readResult()).auth;

  /// Distinguishes an explicit sign-out from a temporary read failure.
  Future<AuthReadResult> readResult() async {
    try {
      final raw = await _readFile(_authPath);
      final root = jsonDecode(raw);
      if (root is! Map) return const AuthReadResult.signedOut();
      final tokens = _map(root['tokens']);
      if (tokens == null) return const AuthReadResult.signedOut();

      final accessToken = _string(tokens['access_token']);
      if (accessToken == null) return const AuthReadResult.signedOut();
      final accountId = _string(tokens['account_id']);
      final idToken = _string(tokens['id_token']);
      final claims = decodeJwtPayload(idToken);
      final authClaims = _map(claims?['https://api.openai.com/auth']);
      final fingerprint = fingerprintFor(
        kind: accountId == null ? 'token' : 'account',
        value: accountId ?? accessToken,
      );

      return AuthReadResult.authenticated(
        AuthInfo(
          email: _string(claims?['email']),
          planType: _string(authClaims?['chatgpt_plan_type']),
          subscriptionExpiresAt: parseTimestamp(
            authClaims?['chatgpt_subscription_active_until'],
          ),
          fingerprint: fingerprint,
          accessToken: accessToken,
        ),
      );
    } on Object {
      return _classifyReadFailure();
    }
  }

  Future<AuthReadResult> _classifyReadFailure() async {
    try {
      return await _fileExists(_authPath)
          ? const AuthReadResult.transientFailure()
          : const AuthReadResult.signedOut();
    } on Object {
      return const AuthReadResult.unavailable();
    }
  }

  /// Decodes the payload of a JWT without validating the signature.
  ///
  /// Signature validation is intentionally left to the Codex backend.  The
  /// payload is used only for display metadata, while the access token is
  /// still sent to the usage endpoint for authoritative quota values.
  static Map<String, dynamic>? decodeJwtPayload(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var encoded = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      encoded += '=' * ((4 - encoded.length % 4) % 4);
      final decoded = utf8.decode(base64.decode(encoded));
      final value = jsonDecode(decoded);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on Object {
      return null;
    }
  }

  /// Returns a short, non-reversible account identifier suitable for caches.
  static String fingerprintFor({required String kind, required String value}) {
    final digest = sha256.convert(utf8.encode(value)).toString();
    return '$kind:${digest.substring(0, 16)}';
  }

  static String _defaultAuthPath(String? codexHome) {
    final home = resolveCodexHome(override: codexHome);
    return '$home${Platform.pathSeparator}auth.json';
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
