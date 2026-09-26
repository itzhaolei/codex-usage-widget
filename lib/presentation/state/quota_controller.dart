import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models.dart';
import '../../data/auth_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/snapshot_repository.dart';
import '../../data/usage_api.dart';
import '../../l10n/app_localizations.dart';
import '../../services/system_capacity_service.dart';
import 'quota_recharge_event.dart';

typedef StatusUpdate = void Function(int? remaining);

class QuotaController extends ChangeNotifier {
  QuotaController({
    AuthRepository? authRepository,
    UsageApi? usageApi,
    SettingsRepository? settingsRepository,
    SystemCapacityService? capacityService,
    SnapshotRepository? snapshotRepository,
    DateTime Function()? clock,
    String Function()? systemLanguage,
    this.onStatusUpdate,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _usageApi = usageApi ?? UsageApi(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _capacityService = capacityService ?? SystemCapacityService(),
       _snapshotRepository = snapshotRepository ?? SnapshotRepository(),
       _clock = clock ?? DateTime.now,
       _systemLanguage = systemLanguage ?? effectiveLanguage {
    now = _clock();
    language = _systemLanguage();
  }

  final AuthRepository _authRepository;
  final UsageApi _usageApi;
  final SettingsRepository _settingsRepository;
  final SystemCapacityService _capacityService;
  final SnapshotRepository _snapshotRepository;
  final DateTime Function() _clock;
  final String Function() _systemLanguage;
  final StatusUpdate? onStatusUpdate;

  QuotaSnapshot? snapshot;
  AuthInfo? auth;
  CapacityInfo? storage;
  CapacityInfo? memory;
  String language = 'en';
  String? languageOverride;
  bool light = false;
  bool pinned = true;
  int progressColorIndex = 0;
  double? left;
  double? top;
  bool windowVisible = true;
  bool loading = false;
  late DateTime now;
  QuotaRechargeEvent? rechargeEvent;

  Timer? _timer;
  DateTime? _lastRemoteRefresh;
  DateTime? _lastCapacityRefresh;
  bool _capacityLoading = false;
  bool _started = false;
  bool _disposed = false;
  bool _statusInitialized = false;
  int? _lastStatus;
  int _rechargeSequence = 0;
  DateTime? _authReadFailureSince;

  AppCopy get copy => localizedCopy(language);
  String get planText => planBadgeText(snapshot?.planType ?? auth?.planType);
  UsageWindow? get fiveHourWindow =>
      snapshot?.sevenDay == null ? null : snapshot?.fiveHour;
  UsageWindow? get weeklyWindow => snapshot?.weeklyWindow;
  int? get fiveHourRemaining => fiveHourWindow?.remainingPercentage;
  int? get weeklyRemaining => weeklyWindow?.remainingPercentage;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    final saved = await _settingsRepository.load();
    if (_disposed) return;
    light = saved.light;
    pinned = saved.pinned;
    languageOverride = saved.language;
    language = languageOverride == null
        ? _systemLanguage()
        : effectiveLanguage(languageOverride);
    progressColorIndex = saved.progressColorIndex.clamp(0, 4).toInt();
    left = saved.left;
    top = saved.top;
    final identity = await _readIdentityWithGrace();
    if (_disposed) return;
    final cached = identity?.fingerprint == null
        ? null
        : await _snapshotRepository.read(
            accountFingerprint: identity!.fingerprint,
          );
    if (_disposed) return;
    final current = await _readIdentityWithGrace();
    if (_disposed) return;
    auth = current;
    snapshot = current?.fingerprint == identity?.fingerprint ? cached : null;
    _publishStatus();
    _notifyVisible();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(refresh(force: true));
  }

  void _tick() {
    if (_disposed) return;
    if (languageOverride == null) language = _systemLanguage();
    if (windowVisible) {
      now = _clock();
      _notifyVisible();
    }
    unawaited(refresh());
  }

  Future<void> refresh({bool force = false}) async {
    if (_disposed ||
        loading ||
        (!force &&
            _lastRemoteRefresh != null &&
            _clock().difference(_lastRemoteRefresh!) <
                const Duration(seconds: 1))) {
      return;
    }
    loading = true;
    _lastRemoteRefresh = _clock();
    try {
      final identity = await _readIdentityWithGrace();
      if (_disposed) return;
      await _adoptIdentity(identity);
      if (_disposed) return;
      if (identity?.fingerprint != null) {
        final next = await _usageApi.refresh(snapshot, identity!);
        if (_disposed) return;
        // The user can switch accounts while the network request is running.
        // Check the actual auth file again before accepting or caching data.
        final current = await _readIdentityWithGrace();
        if (_disposed) return;
        await _adoptIdentity(current);
        if (_disposed) return;
        if (current?.fingerprint != identity.fingerprint) return;
        if (next != null && next.accountFingerprint == identity.fingerprint) {
          final transition = quotaRechargeTransition(snapshot, next);
          if (windowVisible && transition != null) {
            rechargeEvent = QuotaRechargeEvent(
              id: ++_rechargeSequence,
              fromPercentage: transition.fromPercentage,
              toPercentage: transition.toPercentage,
            );
          }
          snapshot = next;
          await _snapshotRepository.write(next);
          if (_disposed) return;
        }
      }
      _publishStatus();
      _notifyVisible();
      unawaited(_refreshCapacity());
    } finally {
      loading = false;
    }
  }

  Future<AuthInfo?> _readIdentityWithGrace() async {
    final result = await _authRepository.readResult();
    switch (result.status) {
      case AuthReadStatus.authenticated:
        _authReadFailureSince = null;
        return result.auth;
      case AuthReadStatus.transientFailure:
        if (auth == null) return null;
        final failedAt = _authReadFailureSince ??= _clock();
        if (_clock().difference(failedAt) < const Duration(seconds: 3)) {
          return auth;
        }
        return null;
      case AuthReadStatus.signedOut:
      case AuthReadStatus.unavailable:
        _authReadFailureSince = null;
        return null;
    }
  }

  Future<void> _adoptIdentity(AuthInfo? identity) async {
    final changed =
        identity?.fingerprint != auth?.fingerprint ||
        (snapshot != null &&
            snapshot!.accountFingerprint != identity?.fingerprint);
    auth = identity;
    if (!changed && identity?.fingerprint != null) return;
    snapshot = null;
    rechargeEvent = null;
    if (changed) {
      _publishStatus();
      _notifyVisible();
      await _snapshotRepository.clear();
    }
  }

  Future<void> _refreshCapacity({bool force = false}) async {
    if (_disposed || !windowVisible || _capacityLoading) return;
    final timestamp = _clock();
    if (!force &&
        _lastCapacityRefresh != null &&
        timestamp.difference(_lastCapacityRefresh!) <
            const Duration(seconds: 1)) {
      return;
    }
    _capacityLoading = true;
    _lastCapacityRefresh = timestamp;
    try {
      final caps = await _capacityService.read();
      if (_disposed || !windowVisible) return;
      storage = caps.storage;
      memory = caps.memory;
      _notifyVisible();
    } on Object {
      // Capacity is supplementary. Keep quota and tray refreshes running when
      // an OS capacity command fails.
    } finally {
      _capacityLoading = false;
    }
  }

  void _publishStatus() {
    if (_disposed) return;
    final remaining = fiveHourRemaining ?? weeklyRemaining;
    if (_statusInitialized && remaining == _lastStatus) return;
    _statusInitialized = true;
    _lastStatus = remaining;
    onStatusUpdate?.call(remaining);
  }

  void _notifyVisible() {
    if (!_disposed && windowVisible) notifyListeners();
  }

  void setWindowVisible(bool visible) {
    if (_disposed || windowVisible == visible) return;
    windowVisible = visible;
    rechargeEvent = null;
    if (visible) {
      now = _clock();
      _notifyVisible();
      unawaited(_refreshCapacity(force: true));
      unawaited(refresh(force: true));
    }
  }

  Future<void> setLight(bool value) async {
    light = value;
    await _saveSettings();
    _notifyVisible();
  }

  Future<void> setPinned(bool value) async {
    pinned = value;
    await _saveSettings();
    _notifyVisible();
  }

  Future<void> setLanguage(String? value) async {
    languageOverride = value;
    language = value == null ? _systemLanguage() : effectiveLanguage(value);
    await _settingsRepository.setLanguage(value);
    _notifyVisible();
  }

  Future<void> setProgressColor(int value) async {
    progressColorIndex = value.clamp(0, 4).toInt();
    await _settingsRepository.setProgressColorIndex(progressColorIndex);
    _notifyVisible();
  }

  Future<void> setPosition(double x, double y) async {
    left = x;
    top = y;
    await _settingsRepository.save(left: x, top: y);
  }

  Future<void> _saveSettings() async {
    await _settingsRepository.save(
      light: light,
      pinned: pinned,
      language: languageOverride,
      progressColorIndex: progressColorIndex,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _usageApi.close();
    super.dispose();
  }
}

class CapacityPair {
  const CapacityPair({this.storage, this.memory});
  final CapacityInfo? storage;
  final CapacityInfo? memory;
}
