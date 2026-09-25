import 'dart:convert';
import 'dart:io';

import '../core/models.dart';

const _usageUri = 'https://chatgpt.com/backend-api/wham/usage';
const _resetCreditsUri =
    'https://chatgpt.com/backend-api/wham/rate-limit-reset-credits';
const _cycleTolerance = Duration(minutes: 5);

/// Small transport boundary so parser and reconciliation tests do not need a
/// live network connection.
abstract interface class UsageTransport {
  Future<UsageResponse> get(
    Uri uri, {
    required String accessToken,
    Duration timeout = const Duration(seconds: 5),
  });

  void close();
}

class UsageResponse {
  const UsageResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;

  dynamic get json => jsonDecode(body);
}

class DartUsageTransport implements UsageTransport {
  DartUsageTransport({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<UsageResponse> get(
    Uri uri, {
    required String accessToken,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final request = await _client.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('OAI-Language', 'en');
    request.headers.set('originator', 'Codex Desktop');
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Quota-Bubble-Flutter/1.0',
    );
    final response = await request.close().timeout(timeout);
    final body = await utf8.decoder.bind(response).join().timeout(timeout);
    return UsageResponse(response.statusCode, body);
  }

  @override
  void close() => _client.close(force: true);
}

class UsagePayload {
  const UsagePayload({
    this.planType,
    this.balanceUsd,
    this.fiveHour,
    this.sevenDay,
    this.resetCredits,
  });

  final String? planType;
  final String? balanceUsd;
  final UsageWindow? fiveHour;
  final UsageWindow? sevenDay;
  final ResetCredits? resetCredits;
}

/// Fetches and parses the Codex quota endpoints.
class UsageApi {
  UsageApi({
    UsageTransport? transport,
    this._authReader,
    DateTime Function()? clock,
  }) : _transport = transport ?? DartUsageTransport(),
       _clock = clock ?? DateTime.now;

  final UsageTransport _transport;
  final Future<AuthInfo?> Function()? _authReader;
  final DateTime Function() _clock;
  _ResetCache? _resetCache;
  final _WindowReconciler _fiveHourReconciler = _WindowReconciler();
  final _WindowReconciler _sevenDayReconciler = _WindowReconciler();

  Future<QuotaSnapshot?> refresh(QuotaSnapshot? existing, AuthInfo auth) async {
    final accessToken = auth.accessToken;
    if (accessToken == null ||
        accessToken.isEmpty ||
        auth.fingerprint == null) {
      return null;
    }
    final sameAccount = existing?.accountFingerprint == auth.fingerprint;
    try {
      final response = await _transport.get(
        Uri.parse(_usageUri),
        accessToken: accessToken,
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UsageApiException(
          'usage request failed (${response.statusCode})',
        );
      }
      final usage = parseUsage(response.body);
      if (usage == null) {
        throw const UsageApiException('usage response was not recognized');
      }

      var resetCredits = usage.resetCredits;
      final needsDetails =
          resetCredits == null ||
          (resetCredits.availableCount > 0 && resetCredits.expiresAt.isEmpty);
      if (needsDetails) {
        resetCredits =
            await fetchResetCredits(auth) ??
            resetCredits ??
            (sameAccount ? existing?.resetCredits : null);
      }

      if (_authReader != null) {
        final current = await _authReader();
        if (current?.fingerprint != auth.fingerprint) return null;
      }

      final snapshot = QuotaSnapshot(
        updatedAt: _clock(),
        accountFingerprint: auth.fingerprint,
        planType: usage.planType ?? (sameAccount ? existing?.planType : null),
        balanceUsd:
            usage.balanceUsd ?? (sameAccount ? existing?.balanceUsd : null),
        // With a secondary window, primary is the 5-hour window.  A single
        // server window is the weekly limit and must clear an old 5-hour one.
        fiveHour: _mergeFiveHour(
          existing: existing?.fiveHour,
          next: usage.fiveHour,
          weeklyWindowPresent: usage.sevenDay != null,
          sameAccount: sameAccount,
        ),
        sevenDay: _sevenDayReconciler.merge(
          existing?.sevenDay,
          usage.sevenDay,
          sameAccount: sameAccount,
          now: _clock(),
        ),
        resetCredits:
            resetCredits ?? (sameAccount ? existing?.resetCredits : null),
      );
      if (snapshot.fiveHour == null &&
          snapshot.sevenDay == null &&
          snapshot.resetCredits == null &&
          snapshot.balanceUsd == null) {
        return sameAccount ? existing : null;
      }
      return snapshot;
    } on Object {
      return sameAccount ? existing?.copyWith(stale: true) : null;
    }
  }

  Future<ResetCredits?> fetchResetCredits(AuthInfo auth) async {
    final accessToken = auth.accessToken;
    final fingerprint = auth.fingerprint;
    if (accessToken == null || accessToken.isEmpty || fingerprint == null) {
      return null;
    }
    final cached = _resetCache;
    if (cached != null &&
        cached.fingerprint == fingerprint &&
        _clock().difference(cached.fetchedAt) < const Duration(seconds: 30)) {
      return cached.value;
    }
    try {
      final response = await _transport.get(
        Uri.parse(_resetCreditsUri),
        accessToken: accessToken,
        timeout: const Duration(seconds: 3),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return cached?.fingerprint == fingerprint ? cached?.value : null;
      }
      final value = parseDetailedResetCredits(response.body);
      if (value == null) {
        return cached?.fingerprint == fingerprint ? cached?.value : null;
      }
      _resetCache = _ResetCache(fingerprint, value, _clock());
      return value;
    } on Object {
      return cached?.fingerprint == fingerprint ? cached?.value : null;
    }
  }

  void close() => _transport.close();

  UsageWindow? _mergeFiveHour({
    required UsageWindow? existing,
    required UsageWindow? next,
    required bool weeklyWindowPresent,
    required bool sameAccount,
  }) {
    if (weeklyWindowPresent && next == null) {
      _fiveHourReconciler.reset();
      return null;
    }
    return _fiveHourReconciler.merge(
      existing,
      next,
      sameAccount: sameAccount,
      now: _clock(),
    );
  }

  static UsagePayload? parseUsage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final root = Map<String, dynamic>.from(decoded);
      final rateLimit = _map(root['rate_limit']);
      final primary = _parseWindow(_map(rateLimit?['primary_window']));
      final secondary = _parseWindow(_map(rateLimit?['secondary_window']));
      final credits = _map(root['credits']);
      final reset = _parseResetCredits(_map(root['rate_limit_reset_credits']));
      final payload = UsagePayload(
        planType: _planType(root),
        balanceUsd: _balance(credits?['balance']),
        fiveHour: secondary == null ? null : primary,
        sevenDay: secondary ?? primary,
        resetCredits: reset,
      );
      if (payload.fiveHour == null &&
          payload.sevenDay == null &&
          payload.resetCredits == null &&
          payload.balanceUsd == null) {
        return null;
      }
      return payload;
    } on Object {
      return null;
    }
  }

  static ResetCredits? parseDetailedResetCredits(String body) {
    try {
      final decoded = jsonDecode(body);
      final root = _map(decoded);
      final count = _integer(root?['available_count']);
      if (count == null) return null;
      final normalized = count.clamp(0, 100000).toInt();
      return ResetCredits(
        availableCount: normalized,
        expiresAt: _resetExpirations(root ?? const {}, limit: normalized),
      );
    } on Object {
      return null;
    }
  }

  static UsageWindow? mergeWindow(
    UsageWindow? existing,
    UsageWindow? next, {
    required bool sameAccount,
  }) {
    if (next == null) return sameAccount ? existing : null;
    if (!sameAccount || existing == null) return next;
    final previousReset = existing.resetsAt;
    final nextReset = next.resetsAt;
    if (previousReset != null &&
        nextReset != null &&
        (previousReset.difference(nextReset)).abs() <= _cycleTolerance &&
        existing.usedPercentage != null &&
        next.usedPercentage != null) {
      return UsageWindow(
        usedPercentage: existing.usedPercentage! > next.usedPercentage!
            ? existing.usedPercentage
            : next.usedPercentage,
        resetsAt: previousReset,
      );
    }
    return next;
  }
}

class UsageApiException implements Exception {
  const UsageApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _WindowReconciler {
  DateTime? _candidateSince;
  DateTime? _candidateReset;

  void reset() {
    _candidateSince = null;
    _candidateReset = null;
  }

  UsageWindow? merge(
    UsageWindow? existing,
    UsageWindow? next, {
    required bool sameAccount,
    required DateTime now,
  }) {
    if (!sameAccount || existing == null || next == null) {
      reset();
      return UsageApi.mergeWindow(existing, next, sameAccount: sameAccount);
    }
    final oldReset = existing.resetsAt;
    final newReset = next.resetsAt;
    if (oldReset == null ||
        newReset == null ||
        !newReset.isBefore(oldReset.subtract(_cycleTolerance))) {
      reset();
      return UsageApi.mergeWindow(existing, next, sameAccount: true);
    }
    if (_candidateReset == null ||
        (_candidateReset!.difference(newReset)).abs() > _cycleTolerance) {
      _candidateReset = newReset;
      _candidateSince = now;
      return existing;
    }
    if (_candidateSince != null &&
        now.difference(_candidateSince!) >= const Duration(seconds: 3)) {
      reset();
      return next;
    }
    return existing;
  }
}

class _ResetCache {
  const _ResetCache(this.fingerprint, this.value, this.fetchedAt);

  final String fingerprint;
  final ResetCredits value;
  final DateTime fetchedAt;
}

UsageWindow? _parseWindow(Map<String, dynamic>? value) {
  final used = _number(value?['used_percent']);
  if (used == null) return null;
  return UsageWindow(
    usedPercentage: used.round().clamp(0, 100).toInt(),
    resetsAt: parseTimestamp(value?['reset_at'] ?? value?['resets_at']),
  );
}

ResetCredits? _parseResetCredits(Map<String, dynamic>? value) {
  final count = _integer(value?['available_count']);
  if (count == null) return null;
  final normalized = count.clamp(0, 100000).toInt();
  return ResetCredits(
    availableCount: normalized,
    expiresAt: _resetExpirations(value ?? const {}, limit: normalized),
  );
}

List<DateTime> _resetExpirations(
  Map<String, dynamic> value, {
  required int limit,
}) {
  final dates = <DateTime>[];
  _collectExpirations(value, dates);
  dates.sort();
  return dates.take(limit).toList(growable: false);
}

void _collectExpirations(Object? value, List<DateTime> output) {
  if (value is List) {
    for (final item in value) {
      _collectExpirations(item, output);
    }
    return;
  }
  final object = _map(value);
  if (object == null) return;
  const expirationKeys = [
    'expires_at',
    'expire_at',
    'expiration_at',
    'expiresAt',
    'expires_on',
    'valid_until',
    'validUntil',
  ];
  for (final key in expirationKeys) {
    final date = parseTimestamp(object[key]);
    if (date == null) continue;
    final copies =
        (_integer(object['count']) ??
                _integer(object['quantity']) ??
                _integer(object['available_count']) ??
                _integer(object['availableCount']) ??
                1)
            .clamp(1, 50);
    output.addAll(List<DateTime>.filled(copies.toInt(), date));
    break;
  }
  const nestedKeys = [
    'credits',
    'items',
    'grants',
    'available',
    'reset_credits',
    'rate_limit_reset_credits',
    'reset_credit_grants',
  ];
  for (final key in nestedKeys) {
    _collectExpirations(object[key], output);
  }
}

String? _planType(Map<String, dynamic> root) {
  final plan = _map(root['plan']);
  final subscription = _map(root['subscription']);
  final account = _map(root['account']);
  final candidates = <Object?>[
    root['plan_type'],
    root['plan'],
    plan?['type'],
    plan?['id'],
    plan?['name'],
    plan?['tier'],
    subscription?['plan'],
    subscription?['plan_type'],
    subscription?['plan_id'],
    subscription?['tier'],
    account?['plan'],
    account?['plan_type'],
    account?['plan_id'],
    account?['tier'],
  ];
  final values = candidates
      .whereType<String>()
      .map(normalizePlanType)
      .where((value) => value.isNotEmpty)
      .toSet();
  const priority = [
    'business20x',
    'business5x',
    'pro20x',
    'pro5x',
    'business',
    'enterprise',
    'edu',
    'plus',
    'free',
  ];
  for (final value in priority) {
    if (values.contains(value)) return value;
  }
  return null;
}

String? _balance(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) return value.toString();
  return null;
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

num? _number(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

int? _integer(Object? value) => _number(value)?.round();
