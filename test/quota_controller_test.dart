import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/core/models.dart';
import 'package:quota_bubble/data/auth_repository.dart';
import 'package:quota_bubble/data/settings_repository.dart';
import 'package:quota_bubble/data/snapshot_repository.dart';
import 'package:quota_bubble/data/usage_api.dart';
import 'package:quota_bubble/presentation/state/quota_controller.dart';
import 'package:quota_bubble/presentation/state/quota_recharge_event.dart';
import 'package:quota_bubble/services/system_capacity_service.dart';

const _accountA = AuthInfo(fingerprint: 'account:a', accessToken: 'token-a');
const _accountB = AuthInfo(fingerprint: 'account:b', accessToken: 'token-b');

QuotaSnapshot _quota({
  String fingerprint = 'account:a',
  int used = 60,
  DateTime? reset,
}) => QuotaSnapshot(
  accountFingerprint: fingerprint,
  sevenDay: UsageWindow(
    usedPercentage: used,
    resetsAt: reset ?? DateTime(2026, 10, 1),
  ),
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'hidden refresh updates cache and changed status without UI work',
    () async {
      final auth = _Auth();
      final api = _Api()..next = _quota(used: 35);
      final snapshots = _Snapshots();
      final capacity = _Capacity();
      final statuses = <int?>[];
      final controller =
          QuotaController(
              authRepository: auth,
              usageApi: api,
              snapshotRepository: snapshots,
              capacityService: capacity,
              onStatusUpdate: statuses.add,
            )
            ..auth = _accountA
            ..snapshot = _quota()
            ..windowVisible = false;
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final previousTime = controller.now;

      await controller.refresh(force: true);
      await controller.refresh(force: true);
      expect(controller.weeklyRemaining, 65);
      expect(snapshots.writes.last.sevenDay!.remainingPercentage, 65);
      expect(statuses, [65]);
      expect(notifications, 0);
      expect(capacity.calls, 0);
      expect(controller.now, previousTime);
      expect(controller.rechargeEvent, isNull);
    },
  );

  test(
    'restoring shows latest cache before the next request completes',
    () async {
      final response = Completer<QuotaSnapshot?>();
      final api = _Api()..pending = response.future;
      final capacity = _Capacity();
      final timestamp = DateTime(2026, 9, 26, 12);
      final controller =
          QuotaController(
              authRepository: _Auth(),
              usageApi: api,
              snapshotRepository: _Snapshots(),
              capacityService: capacity,
              clock: () => timestamp,
            )
            ..auth = _accountA
            ..snapshot = _quota(used: 42)
            ..windowVisible = false
            ..now = DateTime(2026, 9, 25);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setWindowVisible(true);
      expect(notifications, 1);
      expect(controller.now, timestamp);
      expect(controller.weeklyRemaining, 58);
      await _flush();
      expect(api.calls, 1);
      expect(capacity.calls, 1);
      response.complete(_quota(used: 45));
      await _flush();
      expect(controller.weeklyRemaining, 55);
    },
  );

  test(
    'account switch discards the outstanding response and old animation',
    () async {
      final response = Completer<QuotaSnapshot?>();
      final auth = _Auth();
      final api = _Api()..pending = response.future;
      final snapshots = _Snapshots();
      final controller =
          QuotaController(
              authRepository: auth,
              usageApi: api,
              snapshotRepository: snapshots,
              capacityService: _Capacity(),
            )
            ..auth = _accountA
            ..snapshot = _quota()
            ..rechargeEvent = const QuotaRechargeEvent(
              id: 1,
              fromPercentage: 1,
              toPercentage: 100,
            );
      addTearDown(controller.dispose);

      final refresh = controller.refresh(force: true);
      await _flush();
      auth.current = _accountB;
      response.complete(_quota(used: 10));
      await refresh;
      expect(controller.auth!.fingerprint, 'account:b');
      expect(controller.snapshot, isNull);
      expect(controller.rechargeEvent, isNull);
      expect(snapshots.writes, isEmpty);
      expect(snapshots.clears, 1);

      api.pending = null;
      api.next = _quota(fingerprint: 'account:b', used: 21);
      await controller.refresh(force: true);
      expect(controller.weeklyRemaining, 79);
      expect(snapshots.writes.single.accountFingerprint, 'account:b');
    },
  );

  test(
    'a transient auth rewrite keeps the account for three seconds',
    () async {
      var now = DateTime(2026, 9, 26);
      final auth = _Auth();
      final controller =
          QuotaController(
              authRepository: auth,
              usageApi: _Api()..next = _quota(used: 41),
              snapshotRepository: _Snapshots(),
              capacityService: _Capacity(),
              clock: () => now,
            )
            ..auth = _accountA
            ..snapshot = _quota();
      addTearDown(controller.dispose);
      auth.result = const AuthReadResult.transientFailure();
      await controller.refresh(force: true);
      expect(controller.auth, _accountA);
      expect(controller.weeklyRemaining, 59);
      now = now.add(const Duration(seconds: 3));
      await controller.refresh(force: true);
      expect(controller.auth, isNull);
      expect(controller.snapshot, isNull);
    },
  );

  test('sign-out clears the old account without a grace period', () async {
    final auth = _Auth()..current = null;
    final api = _Api()..next = _quota(used: 41);
    final snapshots = _Snapshots();
    final controller =
        QuotaController(
            authRepository: auth,
            usageApi: api,
            snapshotRepository: snapshots,
            capacityService: _Capacity(),
          )
          ..auth = _accountA
          ..snapshot = _quota();
    addTearDown(controller.dispose);

    await controller.refresh(force: true);

    expect(controller.auth, isNull);
    expect(controller.snapshot, isNull);
    expect(api.calls, 0, reason: 'the old token must not be reused');
    expect(snapshots.clears, 1);
  });

  test('sign-out during a request discards the outstanding response', () async {
    final response = Completer<QuotaSnapshot?>();
    final auth = _Auth();
    final api = _Api()..pending = response.future;
    final snapshots = _Snapshots();
    final controller =
        QuotaController(
            authRepository: auth,
            usageApi: api,
            snapshotRepository: snapshots,
            capacityService: _Capacity(),
          )
          ..auth = _accountA
          ..snapshot = _quota();
    addTearDown(controller.dispose);

    final refresh = controller.refresh(force: true);
    await _flush();
    auth.current = null;
    response.complete(_quota(used: 10));
    await refresh;

    expect(controller.auth, isNull);
    expect(controller.snapshot, isNull);
    expect(snapshots.writes, isEmpty);
    expect(snapshots.clears, 1);
  });

  test(
    'hiding during a request suppresses capacity and rendering work',
    () async {
      final response = Completer<QuotaSnapshot?>();
      final capacity = _Capacity();
      final controller =
          QuotaController(
              authRepository: _Auth(),
              usageApi: _Api()..pending = response.future,
              snapshotRepository: _Snapshots(),
              capacityService: capacity,
            )
            ..auth = _accountA
            ..snapshot = _quota();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      final refresh = controller.refresh(force: true);
      await _flush();
      controller.setWindowVisible(false);
      response.complete(_quota(used: 0, reset: DateTime(2026, 10, 8)));
      await refresh;
      expect(notifications, 0);
      expect(capacity.calls, 0);
      expect(controller.weeklyRemaining, 100);
      expect(controller.rechargeEvent, isNull);
    },
  );

  test(
    'visible weekly reset creates one event and ordinary updates retain it',
    () async {
      final api = _Api()..next = _quota(used: 0, reset: DateTime(2026, 10, 8));
      final capacity = _Capacity();
      final controller =
          QuotaController(
              authRepository: _Auth(),
              usageApi: api,
              snapshotRepository: _Snapshots(),
              capacityService: capacity,
            )
            ..auth = _accountA
            ..snapshot = _quota();
      addTearDown(controller.dispose);

      await controller.refresh(force: true);
      final event = controller.rechargeEvent!;
      expect(event.fromPercentage, 40);
      expect(event.toPercentage, 100);
      await controller.refresh(force: true);
      expect(controller.rechargeEvent, same(event));
      expect(capacity.calls, 1);
      controller.setWindowVisible(false);
      expect(controller.rechargeEvent, isNull);
    },
  );

  test('visible refreshes update capacity once per second', () async {
    var now = DateTime(2026, 9, 26, 12);
    final capacity = _Capacity();
    final controller =
        QuotaController(
            authRepository: _Auth(),
            usageApi: _Api()..next = _quota(),
            snapshotRepository: _Snapshots(),
            capacityService: capacity,
            clock: () => now,
          )
          ..auth = _accountA
          ..snapshot = _quota();
    addTearDown(controller.dispose);

    await controller.refresh(force: true);
    expect(capacity.calls, 1);

    now = now.add(const Duration(milliseconds: 999));
    await controller.refresh(force: true);
    expect(capacity.calls, 1);

    now = now.add(const Duration(milliseconds: 1));
    await controller.refresh(force: true);
    expect(capacity.calls, 2);
  });

  test('stalled capacity does not block quota or tray refreshes', () async {
    final capacityRead = Completer<SystemCapacity>();
    final capacity = _Capacity()..pending = capacityRead.future;
    final api = _Api()..next = _quota(used: 35);
    final statuses = <int?>[];
    final controller =
        QuotaController(
            authRepository: _Auth(),
            usageApi: api,
            snapshotRepository: _Snapshots(),
            capacityService: capacity,
            onStatusUpdate: statuses.add,
          )
          ..auth = _accountA
          ..snapshot = _quota();
    addTearDown(controller.dispose);

    await controller.refresh(force: true);
    expect(controller.loading, isFalse);
    expect(controller.weeklyRemaining, 65);
    expect(statuses, [65]);

    api.next = _quota(used: 20);
    await controller.refresh(force: true);
    expect(controller.weeklyRemaining, 80);
    expect(statuses, [65, 80]);
    expect(capacity.calls, 1);

    capacityRead.complete(const SystemCapacity());
    await _flush();
  });

  test('failed capacity does not stop later quota refreshes', () async {
    final capacity = _Capacity()..error = StateError('capacity failed');
    final api = _Api()..next = _quota(used: 35);
    final controller =
        QuotaController(
            authRepository: _Auth(),
            usageApi: api,
            snapshotRepository: _Snapshots(),
            capacityService: capacity,
          )
          ..auth = _accountA
          ..snapshot = _quota();
    addTearDown(controller.dispose);

    await controller.refresh(force: true);
    await _flush();
    api.next = _quota(used: 20);
    await controller.refresh(force: true);

    expect(api.calls, 2);
    expect(controller.weeklyRemaining, 80);
  });

  testWidgets('one-second scheduler polls while hidden and prevents overlap', (
    tester,
  ) async {
    final response = Completer<QuotaSnapshot?>();
    final api = _Api()..next = _quota();
    final capacity = _Capacity();
    final start = DateTime(2026, 9, 26);
    var elapsed = Duration.zero;
    final controller = QuotaController(
      authRepository: _Auth(),
      usageApi: api,
      settingsRepository: _Settings(),
      snapshotRepository: _Snapshots(),
      capacityService: capacity,
      clock: () => start.add(elapsed),
    )..windowVisible = false;
    await controller.start();
    await tester.pump();
    expect(api.calls, 1);
    api.pending = response.future;
    elapsed += const Duration(seconds: 1);
    await tester.pump(const Duration(seconds: 1));
    expect(api.calls, 2);
    elapsed += const Duration(seconds: 5);
    await tester.pump(const Duration(seconds: 5));
    expect(api.calls, 2);
    expect(controller.loading, isTrue);
    response.complete(_quota(used: 50));
    await tester.pump();
    expect(controller.loading, isFalse);
    api.pending = null;
    elapsed += const Duration(seconds: 1);
    await tester.pump(const Duration(seconds: 1));
    expect(api.calls, 3);
    expect(capacity.calls, 0);
    expect(controller.now, start);
    controller.dispose();
  });

  testWidgets('following the system language refreshes while running', (
    tester,
  ) async {
    var language = 'en';
    final controller = QuotaController(
      authRepository: _Auth(),
      usageApi: _Api()..next = _quota(),
      settingsRepository: _Settings(),
      snapshotRepository: _Snapshots(),
      capacityService: _Capacity(),
      systemLanguage: () => language,
    );
    await controller.start();
    expect(controller.language, 'en');
    language = 'zh';
    await tester.pump(const Duration(seconds: 1));
    expect(controller.language, 'zh');
    controller.dispose();
  });

  test(
    'disposing during a request prevents late notifications and writes',
    () async {
      final response = Completer<QuotaSnapshot?>();
      final snapshots = _Snapshots();
      final controller = QuotaController(
        authRepository: _Auth(),
        usageApi: _Api()..pending = response.future,
        snapshotRepository: snapshots,
        capacityService: _Capacity(),
      )..auth = _accountA;
      final refresh = controller.refresh(force: true);
      await _flush();
      controller.dispose();
      response.complete(_quota());
      await refresh;
      expect(snapshots.writes, isEmpty);
      expect(controller.loading, isFalse);
    },
  );
}

class _Auth extends AuthRepository {
  AuthReadResult result = const AuthReadResult.authenticated(_accountA);

  AuthInfo? get current => result.auth;

  set current(AuthInfo? value) {
    result = value == null
        ? const AuthReadResult.signedOut()
        : AuthReadResult.authenticated(value);
  }

  @override
  Future<AuthReadResult> readResult() async => result;
}

class _Api extends UsageApi {
  QuotaSnapshot? next;
  Future<QuotaSnapshot?>? pending;
  int calls = 0;

  @override
  Future<QuotaSnapshot?> refresh(QuotaSnapshot? existing, AuthInfo auth) async {
    calls++;
    return pending ?? next;
  }
}

class _Snapshots extends SnapshotRepository {
  final writes = <QuotaSnapshot>[];
  int clears = 0;

  @override
  Future<QuotaSnapshot?> read({String? accountFingerprint}) async => null;

  @override
  Future<void> write(QuotaSnapshot snapshot) async => writes.add(snapshot);

  @override
  Future<void> clear() async => clears++;
}

class _Capacity extends SystemCapacityService {
  int calls = 0;
  Future<SystemCapacity>? pending;
  Object? error;

  @override
  Future<SystemCapacity> read() async {
    calls++;
    if (error case final error?) throw error;
    if (pending case final pending?) return pending;
    return const SystemCapacity();
  }
}

class _Settings extends SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();
}
