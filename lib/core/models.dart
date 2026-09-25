import 'dart:math' as math;
import 'dart:ui' as ui;

class UsageWindow {
  const UsageWindow({this.usedPercentage, this.resetsAt});

  final int? usedPercentage;
  final DateTime? resetsAt;

  int? get remainingPercentage => remainingPercent(usedPercentage);

  UsageWindow copyWith({int? usedPercentage, DateTime? resetsAt}) =>
      UsageWindow(
        usedPercentage: usedPercentage ?? this.usedPercentage,
        resetsAt: resetsAt ?? this.resetsAt,
      );
}

class ResetCredits {
  const ResetCredits({required this.availableCount, this.expiresAt = const []});

  final int availableCount;
  final List<DateTime> expiresAt;
}

class AuthInfo {
  const AuthInfo({
    this.email,
    this.planType,
    this.subscriptionExpiresAt,
    this.fingerprint,
    this.accessToken,
  });

  final String? email;
  final String? planType;
  final DateTime? subscriptionExpiresAt;
  final String? fingerprint;
  final String? accessToken;
}

class QuotaSnapshot {
  const QuotaSnapshot({
    this.updatedAt,
    this.accountFingerprint,
    this.planType,
    this.balanceUsd,
    this.fiveHour,
    this.sevenDay,
    this.resetCredits,
    this.stale = false,
  });

  final DateTime? updatedAt;
  final String? accountFingerprint;
  final String? planType;
  final String? balanceUsd;
  final UsageWindow? fiveHour;
  final UsageWindow? sevenDay;
  final ResetCredits? resetCredits;
  final bool stale;

  UsageWindow? get weeklyWindow => sevenDay ?? fiveHour;

  QuotaSnapshot copyWith({
    DateTime? updatedAt,
    String? accountFingerprint,
    String? planType,
    String? balanceUsd,
    UsageWindow? fiveHour,
    UsageWindow? sevenDay,
    ResetCredits? resetCredits,
    bool? stale,
  }) => QuotaSnapshot(
    updatedAt: updatedAt ?? this.updatedAt,
    accountFingerprint: accountFingerprint ?? this.accountFingerprint,
    planType: planType ?? this.planType,
    balanceUsd: balanceUsd ?? this.balanceUsd,
    fiveHour: fiveHour ?? this.fiveHour,
    sevenDay: sevenDay ?? this.sevenDay,
    resetCredits: resetCredits ?? this.resetCredits,
    stale: stale ?? this.stale,
  );
}

class ResetRow {
  const ResetRow({required this.date, required this.isExpiringSoon});

  final DateTime? date;
  final bool? isExpiringSoon;
}

class CapacityInfo {
  const CapacityInfo({required this.availableBytes, required this.totalBytes});

  final int availableBytes;
  final int totalBytes;
}

int? remainingPercent(int? used) =>
    used == null ? null : (100 - used).clamp(0, 100).toInt();

String normalizePlanType(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final value = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  if (value.contains('business') || value.contains('team')) {
    if (value.contains('20x')) return 'business20x';
    if (value.contains('5x') || value.contains('prolite')) return 'business5x';
    return 'business';
  }
  if (value.contains('20x') || value.contains('pro20')) return 'pro20x';
  if (value.contains('5x') || value.contains('pro5')) return 'pro5x';
  if (value == 'pro') return 'pro20x';
  if (value.contains('enterprise')) return 'enterprise';
  if (value.contains('edu') || value.contains('education')) return 'edu';
  return value == 'free' || value == 'plus' ? value : '';
}

String planBadgeText(String? raw) {
  switch (normalizePlanType(raw)) {
    case 'free':
      return 'Free';
    case 'plus':
      return 'Plus';
    case 'pro5x':
      return 'Pro 5x';
    case 'pro20x':
      return 'Pro 20x';
    case 'business5x':
      return 'Business 5x';
    case 'business20x':
      return 'Business 20x';
    case 'business':
      return 'Business';
    case 'enterprise':
      return 'Enterprise';
    case 'edu':
      return 'Edu';
    default:
      return '';
  }
}

DateTime? parseTimestamp(Object? value) {
  if (value is num) {
    final seconds = value > 1000000000000 ? value / 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round())
        .toLocal();
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String formatDuration(DateTime? resetAt, {required String language}) {
  if (resetAt == null) return '—';
  var seconds = resetAt.difference(DateTime.now()).inSeconds;
  if (seconds <= 0) return language == 'zh' ? '已重置' : 'Reset';
  final days = seconds ~/ 86400;
  seconds %= 86400;
  final hours = seconds ~/ 3600;
  seconds %= 3600;
  final minutes = seconds ~/ 60;
  seconds %= 60;
  final values = <String>[];
  if (days > 0) values.add('${days}d');
  if (hours > 0 || days > 0) values.add('${hours}h');
  if (minutes > 0 || hours > 0 || days > 0) values.add('${minutes}m');
  values.add('${math.max(1, seconds)}s');
  return values.join(' ');
}

String formatBalance(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final parsed = double.tryParse(value.replaceFirst(RegExp(r'^\$'), ''));
  if (parsed == null) return value;
  return parsed.round().toString();
}

String effectiveLanguage([String? override]) {
  final language = override?.trim().toLowerCase();
  if (language != null && language.isNotEmpty) {
    return language.split(RegExp('[-_]')).first;
  }
  final system = ui.PlatformDispatcher.instance.locale.languageCode;
  return supportedLanguages.contains(system) ? system : 'en';
}

const supportedLanguages = <String>[
  'en',
  'zh',
  'ja',
  'ko',
  'de',
  'fr',
  'es',
  'pt',
  'it',
  'nl',
];
