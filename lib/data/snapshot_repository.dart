import 'dart:convert';
import 'dart:io';

import '../core/models.dart';
import 'codex_paths.dart';

/// Persists the last successful quota response without ever storing tokens.
///
/// The snapshot is scoped to an account fingerprint.  Callers pass the
/// currently authenticated fingerprint when reading so a previous account's
/// values can never be rendered after an account switch.
class SnapshotRepository {
  SnapshotRepository({String? codexHome, String? snapshotPath})
    : _path = snapshotPath ?? _defaultPath(codexHome);

  final String _path;

  String get path => _path;

  Future<QuotaSnapshot?> read({String? accountFingerprint}) async {
    try {
      final root = jsonDecode(await File(_path).readAsString());
      if (root is! Map) return null;
      final value = Map<String, dynamic>.from(root);
      final fingerprint = _string(value['account_fingerprint']);
      if (accountFingerprint == null || fingerprint != accountFingerprint) {
        return null;
      }
      return _decode(value);
    } on Object {
      return null;
    }
  }

  Future<void> write(QuotaSnapshot snapshot) async {
    final target = File(_path);
    final temporary = File('$_path.tmp');
    try {
      await target.parent.create(recursive: true);
      await temporary.writeAsString(jsonEncode(_encode(snapshot)), flush: true);
      try {
        await temporary.rename(_path);
      } on FileSystemException {
        // Windows cannot replace an existing file through rename().  Remove
        // the old cache only after the new content has been fully written.
        await target.delete();
        await temporary.rename(_path);
      }
    } on Object {
      // A failed cache write must not make the quota window unusable.
      try {
        await temporary.delete();
      } on Object {
        // Ignore cleanup failures as well.
      }
    }
  }

  Future<void> clear() async {
    try {
      await File(_path).delete();
    } on FileSystemException {
      // Missing snapshots are already cleared.
    }
  }

  static String _defaultPath(String? codexHome) {
    final home = resolveCodexHome(override: codexHome);
    return '$home${Platform.pathSeparator}codex-usage-snapshot.json';
  }
}

QuotaSnapshot? _decode(Map<String, dynamic> value) {
  final resetCredits = _decodeResetCredits(value['reset_credits']);
  return QuotaSnapshot(
    updatedAt: parseTimestamp(value['updated_at']),
    accountFingerprint: _string(value['account_fingerprint']),
    planType: _string(value['plan_type']),
    balanceUsd: _string(value['balance_usd']),
    fiveHour: _decodeWindow(value['five_hour']),
    sevenDay: _decodeWindow(value['seven_day']),
    resetCredits: resetCredits,
  );
}

UsageWindow? _decodeWindow(Object? value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final used = map['used_percentage'];
  if (used is! num) return null;
  return UsageWindow(
    usedPercentage: used.round().clamp(0, 100).toInt(),
    resetsAt: parseTimestamp(map['resets_at']),
  );
}

ResetCredits? _decodeResetCredits(Object? value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final count = map['available_count'];
  if (count is! num) return null;
  final dates = <DateTime>[];
  final rawDates = map['expires_at'];
  if (rawDates is List) {
    for (final raw in rawDates) {
      final date = parseTimestamp(raw);
      if (date != null) dates.add(date);
    }
  }
  return ResetCredits(
    availableCount: count.round().clamp(0, 100000).toInt(),
    expiresAt: List<DateTime>.unmodifiable(dates),
  );
}

Map<String, dynamic> _encode(QuotaSnapshot snapshot) => {
  'updated_at': snapshot.updatedAt?.toUtc().toIso8601String(),
  'account_fingerprint': snapshot.accountFingerprint,
  'plan_type': snapshot.planType,
  'balance_usd': snapshot.balanceUsd,
  'five_hour': _encodeWindow(snapshot.fiveHour),
  'seven_day': _encodeWindow(snapshot.sevenDay),
  'reset_credits': _encodeResetCredits(snapshot.resetCredits),
};

Map<String, dynamic>? _encodeWindow(UsageWindow? value) {
  if (value == null) return null;
  final reset = value.resetsAt?.toUtc().millisecondsSinceEpoch;
  return {
    'used_percentage': value.usedPercentage,
    'resets_at': reset == null ? null : reset / 1000,
  };
}

Map<String, dynamic>? _encodeResetCredits(ResetCredits? value) {
  if (value == null) return null;
  return {
    'available_count': value.availableCount,
    'expires_at': value.expiresAt
        .map((date) => date.toUtc().toIso8601String())
        .toList(growable: false),
  };
}

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
