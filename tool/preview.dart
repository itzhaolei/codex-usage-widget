// Offline visual fixture; this entrypoint is never used by release builds.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:quota_bubble/core/models.dart';
import 'package:quota_bubble/desktop_app.dart';
import 'package:quota_bubble/presentation/state/quota_controller.dart';
import 'package:quota_bubble/presentation/state/quota_recharge_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preview = PreviewController();
  await runQuotaBubble(preview: preview, replay: preview.replay);
}

class PreviewController extends QuotaController {
  PreviewController() {
    language = 'zh';
    languageOverride = 'zh';
    auth = AuthInfo(
      email: 'demo@quota-bubble.app',
      planType: 'business5x',
      subscriptionExpiresAt: DateTime.utc(2027).toLocal(),
    );
    snapshot = QuotaSnapshot(
      accountFingerprint: 'visual-preview',
      planType: 'business5x',
      balanceUsd: '12.50',
      sevenDay: UsageWindow(
        usedPercentage: 21,
        resetsAt: DateTime.utc(2026, 10, 2, 8, 30).toLocal(),
      ),
      resetCredits: ResetCredits(
        availableCount: 2,
        expiresAt: [
          DateTime.utc(2026, 9, 27, 4, 15).toLocal(),
          DateTime.utc(2026, 10, 3, 1, 45).toLocal(),
        ],
      ),
    );
    storage = const CapacityInfo(
      availableBytes: 312000000000,
      totalBytes: 512000000000,
    );
    memory = const CapacityInfo(
      availableBytes: 4509715660,
      totalBytes: 17179869184,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (windowVisible) notifyListeners();
    });
  }
  Timer? _ticker;
  int _sequence = 0;
  void replay() {
    rechargeEvent = QuotaRechargeEvent(
      id: ++_sequence,
      fromPercentage: 21,
      toPercentage: 79,
    );
    notifyListeners();
  }

  @override
  void setWindowVisible(bool value) {
    windowVisible = value;
    rechargeEvent = null;
    notifyListeners();
  }

  @override
  Future<void> setLight(bool value) async {
    light = value;
    notifyListeners();
  }

  @override
  Future<void> setPinned(bool value) async {
    pinned = value;
    notifyListeners();
  }

  @override
  Future<void> setProgressColor(int value) async {
    progressColorIndex = value;
    notifyListeners();
  }

  @override
  Future<void> setLanguage(String? value) async {
    languageOverride = value;
    language = effectiveLanguage(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
