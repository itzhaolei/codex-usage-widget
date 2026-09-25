import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quota_bubble/core/models.dart';
import 'package:quota_bubble/data/auth_repository.dart';
import 'package:quota_bubble/data/codex_paths.dart';
import 'package:quota_bubble/data/snapshot_repository.dart';
import 'package:quota_bubble/data/settings_repository.dart';
import 'package:quota_bubble/data/usage_api.dart';

const _accountA = AuthInfo(fingerprint: 'account:a', accessToken: 'token-a');
const _accountB = AuthInfo(fingerprint: 'account:b', accessToken: 'token-b');

String _usage({
  int used = 40,
  int reset = 1790812800,
  bool withResetCredits = true,
}) => jsonEncode({
  'rate_limit': {
    'primary_window': {'used_percent': used, 'reset_at': reset},
  },
  if (withResetCredits) 'rate_limit_reset_credits': {'available_count': 0},
});

void main() {
  test(
    'migrates legacy desktop preferences once and keeps language compatible',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final directory = await Directory.systemTemp.createTemp(
        'quota-settings-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final language = File(
        '${directory.path}${Platform.pathSeparator}usage-widget'
        '${Platform.pathSeparator}language.txt',
      );
      await language.parent.create(recursive: true);
      await language.writeAsString('zh\n');
      var reads = 0;
      final repository = SettingsRepository(
        preferences: preferences,
        codexHome: directory.path,
        legacyReader: () async {
          reads++;
          return {
            'light': true,
            'pinned': false,
            'left': 25,
            'top': 40.5,
            'progressColorIndex': 4,
          };
        },
      );
      expect(
        await repository.load(),
        const AppSettings(
          light: true,
          pinned: false,
          language: 'zh',
          left: 25,
          top: 40.5,
          progressColorIndex: 4,
        ),
      );
      expect(reads, 1);
      await preferences.setBool(SettingsRepository.lightKey, false);
      expect((await repository.load()).light, isFalse);
      expect(reads, 1);

      await repository.setLanguage('ja');
      expect(await language.readAsString(), 'ja\n');
      await repository.setLanguage(null);
      expect(await language.exists(), isFalse);
    },
  );

  test(
    'failed legacy migration is retried without overriding new values',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var reads = 0;
      final repository = SettingsRepository(
        preferences: preferences,
        codexHome: Directory.systemTemp.path,
        legacyReader: () async {
          reads++;
          if (reads == 1) throw const FileSystemException('busy');
          return {'light': true, 'progressColorIndex': 99};
        },
      );
      expect((await repository.load()).light, isFalse);
      expect((await repository.load()).light, isTrue);
      expect((await repository.load()).progressColorIndex, 4);
      expect(reads, 2);
    },
  );

  test(
    'invalid persisted languages fall back to the system language',
    () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.languageKey: 'unsupported-locale',
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = SettingsRepository(
        preferences: preferences,
        codexHome: Directory.systemTemp.path,
        legacyReader: () async => null,
      );

      expect((await repository.load()).language, isNull);
      await preferences.setString(SettingsRepository.languageKey, ' JA ');
      expect((await repository.load()).language, 'ja');
    },
  );

  test('resolves Codex home consistently on macOS and Windows', () {
    expect(
      resolveCodexHome(environment: {'HOME': '/Users/demo'}, separator: '/'),
      '/Users/demo/.codex',
    );
    expect(
      resolveCodexHome(
        environment: {'USERPROFILE': r'C:\Users\demo', 'HOME': '/other'},
        separator: r'\',
      ),
      r'C:\Users\demo\.codex',
    );
    expect(
      resolveCodexHome(environment: {'CODEX_HOME': '/custom', 'HOME': '/user'}),
      '/custom',
    );
    expect(
      resolveCodexHome(
        override: '/explicit',
        environment: {'CODEX_HOME': '/custom'},
      ),
      '/explicit',
    );
    expect(
      AuthRepository(codexHome: '/custom').authPath,
      '/custom${Platform.pathSeparator}auth.json',
    );
    expect(
      SnapshotRepository(codexHome: '/custom').path,
      '/custom${Platform.pathSeparator}codex-usage-snapshot.json',
    );
  });

  test(
    'auth metadata uses a stable account fingerprint across token refreshes',
    () async {
      final claims = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'email': 'sample@example.com',
                'https://api.openai.com/auth': {
                  'chatgpt_plan_type': 'business_5x',
                  'chatgpt_subscription_active_until': '2026-10-01T00:00:00Z',
                },
              }),
            ),
          )
          .replaceAll('=', '');
      var token = 'access-before';
      final repository = AuthRepository(
        readFile: (_) async => jsonEncode({
          'tokens': {
            'account_id': 'same-account',
            'access_token': token,
            'id_token': 'header.$claims.signature',
          },
        }),
      );
      final before = (await repository.read())!;
      token = 'access-after';
      final after = (await repository.read())!;
      expect(before.fingerprint, after.fingerprint);
      expect(before.fingerprint, isNot(contains('same-account')));
      expect(after.email, 'sample@example.com');
      expect(after.planType, 'business_5x');
      expect(after.accessToken, 'access-after');
      expect(after.subscriptionExpiresAt!.toUtc(), DateTime.utc(2026, 10));
    },
  );

  test('unreadable and malformed auth files return no account', () async {
    expect(
      await AuthRepository(
        readFile: (_) async => '{',
        fileExists: (_) async => true,
      ).read(),
      isNull,
    );
    expect(await AuthRepository(readFile: (_) async => '{}').read(), isNull);
    expect(
      await AuthRepository(
        readFile: (_) async => throw const FileSystemException(),
        fileExists: (_) async => true,
      ).read(),
      isNull,
    );
  });

  test(
    'auth reads distinguish sign-out from transient file failures',
    () async {
      final missing = await AuthRepository(
        readFile: (_) async => throw const FileSystemException('missing'),
        fileExists: (_) async => false,
      ).readResult();
      final signedOut = await AuthRepository(readFile: (_) async => '{}')
          .readResult();
      final malformed = await AuthRepository(
        readFile: (_) async => '{',
        fileExists: (_) async => true,
      ).readResult();
      final unreadable = await AuthRepository(
        readFile: (_) async => throw const FileSystemException('busy'),
        fileExists: (_) async => true,
      ).readResult();
      final unavailable = await AuthRepository(
        readFile: (_) async => throw const FileSystemException('busy'),
        fileExists: (_) async => throw const FileSystemException('unknown'),
      ).readResult();

      expect(missing.status, AuthReadStatus.signedOut);
      expect(signedOut.status, AuthReadStatus.signedOut);
      expect(malformed.status, AuthReadStatus.transientFailure);
      expect(unreadable.status, AuthReadStatus.transientFailure);
      expect(unavailable.status, AuthReadStatus.unavailable);
    },
  );

  test(
    'snapshot roundtrip is account scoped and contains no credentials',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'quota-snapshot-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = SnapshotRepository(codexHome: directory.path);
      final reset = DateTime.utc(2026, 10, 1);
      await repository.write(
        QuotaSnapshot(
          accountFingerprint: 'account:a',
          planType: 'business5x',
          sevenDay: UsageWindow(usedPercentage: 33, resetsAt: reset),
          resetCredits: ResetCredits(availableCount: 1, expiresAt: [reset]),
        ),
      );
      final value = await repository.read(accountFingerprint: 'account:a');
      expect(value!.sevenDay!.remainingPercentage, 67);
      expect(value.resetCredits!.expiresAt.single.toUtc(), reset);
      expect(await repository.read(accountFingerprint: 'account:b'), isNull);
      expect(await repository.read(), isNull);
      expect(
        await File(repository.path).readAsString(),
        isNot(contains('access_token')),
      );
      await repository.clear();
      expect(await repository.read(accountFingerprint: 'account:a'), isNull);
    },
  );

  test('API rejects successful responses after an account switch', () async {
    final api = UsageApi(
      transport: _Transport((_) => UsageResponse(200, _usage())),
      authReader: () async => _accountB,
    );
    addTearDown(api.close);
    expect(await api.refresh(null, _accountA), isNull);
  });

  test('single server window clears the old five-hour window', () async {
    final api = UsageApi(
      transport: _Transport((_) => UsageResponse(200, _usage(used: 70))),
    );
    addTearDown(api.close);
    final existing = QuotaSnapshot(
      accountFingerprint: 'account:a',
      fiveHour: const UsageWindow(usedPercentage: 20),
      sevenDay: UsageWindow(
        usedPercentage: 30,
        resetsAt: parseTimestamp(1790812800),
      ),
    );
    final next = (await api.refresh(existing, _accountA))!;
    expect(next.fiveHour, isNull);
    expect(next.sevenDay!.usedPercentage, 70);
  });

  test('same-cycle quota cannot regress and a new cycle can refill', () async {
    var used = 20;
    var reset = 1790812800;
    final api = UsageApi(
      transport: _Transport(
        (_) => UsageResponse(200, _usage(used: used, reset: reset)),
      ),
    );
    addTearDown(api.close);
    final existing = QuotaSnapshot(
      accountFingerprint: 'account:a',
      sevenDay: UsageWindow(
        usedPercentage: 60,
        resetsAt: parseTimestamp(reset),
      ),
    );
    final sameCycle = (await api.refresh(existing, _accountA))!;
    expect(sameCycle.sevenDay!.usedPercentage, 60);
    used = 0;
    reset += 7 * 24 * 60 * 60;
    final nextCycle = (await api.refresh(sameCycle, _accountA))!;
    expect(nextCycle.sevenDay!.usedPercentage, 0);
  });

  test(
    'older reset timestamp requires consistent confirmation over three seconds',
    () async {
      var now = DateTime.utc(2026, 9, 26);
      final api = UsageApi(
        transport: _Transport(
          (_) => UsageResponse(200, _usage(reset: 1790812800 - 3600)),
        ),
        clock: () => now,
      );
      addTearDown(api.close);
      final existing = QuotaSnapshot(
        accountFingerprint: 'account:a',
        sevenDay: UsageWindow(
          usedPercentage: 60,
          resetsAt: parseTimestamp(1790812800),
        ),
      );
      var next = (await api.refresh(existing, _accountA))!;
      expect(next.sevenDay!.usedPercentage, 60);
      now = now.add(const Duration(seconds: 2));
      next = (await api.refresh(next, _accountA))!;
      expect(next.sevenDay!.usedPercentage, 60);
      now = now.add(const Duration(seconds: 1));
      next = (await api.refresh(next, _accountA))!;
      expect(next.sevenDay!.usedPercentage, 40);
    },
  );

  test('reset credit cache never falls back to another account', () async {
    var failure = false;
    var calls = 0;
    final api = UsageApi(
      transport: _Transport((_) {
        calls++;
        return failure
            ? const UsageResponse(500, '{}')
            : const UsageResponse(200, '{"available_count":2}');
      }),
    );
    addTearDown(api.close);
    expect((await api.fetchResetCredits(_accountA))!.availableCount, 2);
    expect((await api.fetchResetCredits(_accountA))!.availableCount, 2);
    expect(calls, 1);
    failure = true;
    expect(await api.fetchResetCredits(_accountB), isNull);
    expect(calls, 2);
  });

  test('failed refresh preserves only the matching account snapshot', () async {
    final api = UsageApi(
      transport: _Transport((_) => const UsageResponse(503, '{}')),
    );
    addTearDown(api.close);
    const existing = QuotaSnapshot(
      accountFingerprint: 'account:a',
      sevenDay: UsageWindow(usedPercentage: 20),
    );
    expect((await api.refresh(existing, _accountA))!.stale, isTrue);
    expect(await api.refresh(existing, _accountB), isNull);
  });
}

class _Transport implements UsageTransport {
  _Transport(this.response);
  final UsageResponse Function(Uri) response;

  @override
  Future<UsageResponse> get(
    Uri uri, {
    required String accessToken,
    Duration timeout = const Duration(seconds: 5),
  }) async => response(uri);

  @override
  void close() {}
}
