import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/services/update_service.dart';

List<int> _installer(UpdatePlatform platform) {
  final bytes = List<int>.filled(128, 0);
  if (platform == UpdatePlatform.macOS) {
    bytes.setRange(0, 4, [0x50, 0x4b, 3, 4]);
  } else {
    bytes.setRange(0, 2, [0x4d, 0x5a]);
    bytes[60] = 64;
    bytes.setRange(64, 68, [0x50, 0x45, 0, 0]);
  }
  return bytes;
}

Map<String, dynamic> _release({
  String tag = 'v4.0.1',
  UpdatePlatform platform = UpdatePlatform.windows,
  List<int>? bytes,
}) {
  bytes ??= _installer(platform);
  final suffix = platform == UpdatePlatform.macOS
      ? 'macOS-Installer.zip'
      : 'Windows-Setup.exe';
  final name = 'QuotaBubble-${tag.substring(1)}-$suffix';
  return {
    'tag_name': tag,
    'draft': false,
    'prerelease': false,
    'assets': [
      {
        'name': name,
        'browser_download_url': '$quotaReleases/download/$tag/$name',
        'state': 'uploaded',
        'size': bytes.length,
        'digest': 'sha256:${sha256.convert(bytes)}',
      },
    ],
  };
}

UpdateHttpResponse _json(Object json) =>
    UpdateHttpResponse(200, Stream.value(utf8.encode(jsonEncode(json))));

void main() {
  test('numeric version comparison handles multi-digit components and build metadata', () {
    expect(
      ReleaseVersion.parse('v4.10.0')!
          .compareTo(ReleaseVersion.parse('4.9.99')!),
      greaterThan(0),
    );
    expect(
      ReleaseVersion.parse('4.0.0+10')!
          .compareTo(ReleaseVersion.parse('4.0.0')!),
      0,
    );
    expect(
      ReleaseVersion.parse('4.0.0.1')!
          .compareTo(ReleaseVersion.parse('4.0.0')!),
      greaterThan(0),
    );
    for (final value in [
      '4',
      'v4.0',
      '4.0.1-rc.1',
      '4.0.0; echo bad',
      'x4.0.0',
    ]) {
      expect(ReleaseVersion.parse(value), isNull);
    }
  });

  test(
    'selects exact official uploaded asset and rejects unverified metadata',
    () {
      final release = _release();
      expect(
        UpdateRelease.fromJson(release, UpdatePlatform.windows)!.tag,
        'v4.0.1',
      );
      expect(UpdateRelease.fromJson(release, UpdatePlatform.macOS), isNull);
      expect(
        UpdateRelease.fromJson({
          ...release,
          'draft': true,
        }, UpdatePlatform.windows),
        isNull,
      );
      expect(
        UpdateRelease.fromJson({
          ...release,
          'prerelease': true,
        }, UpdatePlatform.windows),
        isNull,
      );
      final asset = Map<String, dynamic>.from(
        (release['assets'] as List).single as Map,
      );
      for (final override in [
        {'name': 'other-Windows-Setup.exe'},
        {'browser_download_url': 'https://example.org/installer.exe'},
        {'browser_download_url': '${asset['browser_download_url']}?token=bad'},
        {'digest': null},
        {'digest': 'sha256:1234'},
        {'state': 'new'},
        {'size': 0},
      ]) {
        expect(
          UpdateRelease.fromJson({
            ...release,
            'assets': [
              {...asset, ...override},
            ],
          }, UpdatePlatform.windows),
          isNull,
        );
      }
    },
  );

  test('download redirect allowlist rejects insecure hosts and user info', () {
    expect(
      HttpUpdateTransport.allowedUri(
        Uri.parse(
          'https://release-assets.githubusercontent.com/github-production-release-asset/file',
        ),
      ),
      isTrue,
    );
    for (final value in [
      'http://github.com/a',
      'https://github.com.evil.org/a',
      'https://user:secret@github.com/a',
      'https://github.com:444/a',
      'file:///tmp/a',
    ]) {
      expect(HttpUpdateTransport.allowedUri(Uri.parse(value)), isFalse);
    }
  });

  test(
    'checks every 30 minutes and preserves a known update on transient failure',
    () async {
      var now = DateTime(2026, 9, 26);
      var fail = false;
      final transport = _Transport(
        (_) async => fail
            ? UpdateHttpResponse(503, const Stream.empty())
            : _json([_release()]),
      );
      final service = UpdateService(
        currentVersion: '4.0.0',
        platform: UpdatePlatform.windows,
        transport: transport,
        clock: () => now,
        delay: (_) async {},
      );
      addTearDown(service.dispose);
      await service.check();
      expect(service.hasUpdate, isTrue);
      expect(service.state, UpdateState.available);
      expect(transport.calls, 1);
      now = now.add(const Duration(minutes: 29));
      await service.check();
      expect(transport.calls, 1);
      now = now.add(const Duration(minutes: 1));
      fail = true;
      await service.check();
      expect(transport.calls, 4);
      expect(service.state, UpdateState.failed);
      expect(service.hasUpdate, isTrue);
      expect(service.error, contains('HTTP 503'));
    },
  );

  test('concurrent checks share the existing operation without overlapping requests', () async {
    final pending = Completer<UpdateHttpResponse>();
    final transport = _Transport((_) => pending.future);
    final service = UpdateService(
      currentVersion: '4.0.0',
      platform: UpdatePlatform.windows,
      transport: transport,
    );
    addTearDown(service.dispose);
    final checking = service.check();
    await service.check(force: true);
    expect(transport.calls, 1);
    pending.complete(_json([_release()]));
    await checking;
    expect(service.hasUpdate, isTrue);
  });

  test(
    'selects the newest complete release without downgrading current version',
    () async {
      final service = UpdateService(
        currentVersion: '4.0.2',
        platform: UpdatePlatform.windows,
        transport: _Transport(
          (_) async => _json([
            _release(tag: 'v4.0.1'),
            _release(tag: 'v4.0.2'),
            _release(tag: 'v3.9.99'),
          ]),
        ),
      );
      addTearDown(service.dispose);
      await service.check();
      expect(service.latest!.tag, 'v4.0.2');
      expect(service.hasUpdate, isFalse);
      expect(service.state, UpdateState.current);
      var exited = false;
      expect(
        await service.downloadAndInstall(onExit: () async => exited = true),
        isFalse,
      );
      expect(exited, isFalse);
    },
  );

  test(
    'Windows verifies bytes before launching the silent installer and exiting',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'quota-update-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final bytes = _installer(UpdatePlatform.windows);
      final commands = _Commands();
      final service = UpdateService(
        currentVersion: '4.0.0',
        platform: UpdatePlatform.windows,
        commands: commands,
        temporaryDirectory: () async => directory,
        transport: _Transport(
          (uri) async => uri.host == 'api.github.com'
              ? _json([_release(bytes: bytes)])
              : UpdateHttpResponse(
                  200,
                  Stream.fromIterable([
                    bytes.sublist(0, 64),
                    bytes.sublist(64),
                  ]),
                  contentLength: bytes.length,
                ),
        ),
      );
      addTearDown(service.dispose);
      await service.check();
      expect(
        commands.calls,
        isEmpty,
        reason: 'checking never launches installers',
      );
      var exited = false;
      expect(
        await service.downloadAndInstall(onExit: () async => exited = true),
        isTrue,
      );
      expect(service.state, UpdateState.restarting);
      expect(service.progress, 1);
      expect(exited, isTrue);
      expect(
        commands.calls.single.$1,
        endsWith('QuotaBubble-4.0.1-Windows-Setup.exe'),
      );
      expect(commands.calls.single.$2, contains('/VERYSILENT'));
      expect(
        await directory.exists(),
        isTrue,
        reason: 'running Windows installer must remain on disk',
      );
    },
  );

  for (final failure in ['truncated', 'checksum', 'magic', 'launch']) {
    test('$failure failure never reports update success or exits', () async {
      final directory = await Directory.systemTemp.createTemp(
        'quota-update-failure-test-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final original = _installer(UpdatePlatform.windows);
      final metadataBytes = failure == 'magic'
          ? List<int>.filled(128, 12)
          : original;
      final payload = switch (failure) {
        'truncated' => original.sublist(0, 65),
        'checksum' => [...original.take(127), 42],
        'magic' => metadataBytes,
        _ => original,
      };
      final commands = _Commands()..failLaunch = failure == 'launch';
      final service = UpdateService(
        currentVersion: '4.0.0',
        platform: UpdatePlatform.windows,
        commands: commands,
        temporaryDirectory: () async => directory,
        delay: (_) async {},
        transport: _Transport(
          (uri) async => uri.host == 'api.github.com'
              ? _json([_release(bytes: metadataBytes)])
              : UpdateHttpResponse(200, Stream.value(payload)),
        ),
      );
      addTearDown(service.dispose);
      await service.check();
      var exited = false;
      expect(
        await service.downloadAndInstall(onExit: () async => exited = true),
        isFalse,
      );
      expect(exited, isFalse);
      expect(service.state, UpdateState.failed);
      expect(service.error, isNotEmpty);
      if (failure != 'launch') expect(commands.calls, isEmpty);
      expect(await directory.exists(), isFalse);
    });
  }

  test('macOS validates bundle identity and version before executing the script', () async {
    final directory = await Directory.systemTemp.createTemp(
      'quota-update-mac-test-',
    );
    final bytes = _installer(UpdatePlatform.macOS);
    final commands = _Commands()
      ..runHook = (executable, arguments) async {
        if (executable == '/usr/bin/unzip') {
          return ProcessResult(
            0,
            0,
            'Install Quota Bubble.app/Contents/Resources/install-packaged.sh\n',
            '',
          );
        }
        if (executable == '/usr/bin/ditto') {
          final script = File(
            '${arguments.last}/Install Quota Bubble.app/Contents/Resources/install-packaged.sh',
          );
          await script.parent.create(recursive: true);
          await script.writeAsString('#!/bin/bash\n');
        }
        if (executable == '/usr/libexec/PlistBuddy') {
          return ProcessResult(
            0,
            0,
            arguments[1].contains('Identifier')
                ? 'local.codex.quota-bubble\n'
                : '4.0.1\n',
            '',
          );
        }
        return ProcessResult(0, 0, '', '');
      };
    final service = UpdateService(
      currentVersion: '4.0.0',
      platform: UpdatePlatform.macOS,
      commands: commands,
      temporaryDirectory: () async => directory,
      transport: _Transport(
        (uri) async => uri.host == 'api.github.com'
            ? _json([_release(platform: UpdatePlatform.macOS, bytes: bytes)])
            : UpdateHttpResponse(200, Stream.value(bytes)),
      ),
    );
    addTearDown(service.dispose);
    await service.check();
    var exited = false;
    expect(
      await service.downloadAndInstall(onExit: () async => exited = true),
      isTrue,
    );
    expect(exited, isTrue);
    expect(
      commands.calls.where((call) => call.$1 == '/bin/bash'),
      hasLength(2),
    );
    expect(commands.extraEnvironment['QUOTA_BUBBLE_KEEP_RUNNING'], '1');
    expect(commands.calls.last.$2, contains('/Applications/Quota Bubble.app'));
    expect(await directory.exists(), isFalse);
  });

  test(
    'malicious macOS archive paths are rejected before extraction',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'quota-update-path-test-',
      );
      final bytes = _installer(UpdatePlatform.macOS);
      final commands = _Commands()
        ..runHook = (_, _) async => ProcessResult(0, 0, '../outside.sh\n', '');
      final service = UpdateService(
        currentVersion: '4.0.0',
        platform: UpdatePlatform.macOS,
        commands: commands,
        temporaryDirectory: () async => directory,
        transport: _Transport(
          (uri) async => uri.host == 'api.github.com'
              ? _json([_release(platform: UpdatePlatform.macOS, bytes: bytes)])
              : UpdateHttpResponse(200, Stream.value(bytes)),
        ),
      );
      addTearDown(service.dispose);
      await service.check();
      expect(
        await service.downloadAndInstall(
          onExit: () async => fail('must not exit'),
        ),
        isFalse,
      );
      expect(commands.calls.single.$1, '/usr/bin/unzip');
      expect(service.error, contains('invalid path'));
      expect(await directory.exists(), isFalse);
    },
  );

  test(
    'installer subprocess environment omits inherited tokens and credentials',
    () {
      final environment = UpdateCommands().environment();
      for (final key in [
        'OPENAI_API_KEY',
        'GH_TOKEN',
        'GITHUB_TOKEN',
        'CODEX_ACCESS_TOKEN',
        'AWS_SECRET_ACCESS_KEY',
      ]) {
        expect(environment.containsKey(key), isFalse);
      }
    },
  );
}

class _Transport implements UpdateTransport {
  _Transport(this.response);
  final Future<UpdateHttpResponse> Function(Uri) response;
  int calls = 0;
  @override
  Future<UpdateHttpResponse> get(Uri uri) {
    calls++;
    return response(uri);
  }

  @override
  void close() {}
}

class _Commands extends UpdateCommands {
  final calls = <(String, List<String>)>[];
  Map<String, String> extraEnvironment = {};
  bool failLaunch = false;
  Future<ProcessResult> Function(String, List<String>)? runHook;
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String> extraEnvironment = const {},
  }) async {
    calls.add((executable, arguments));
    this.extraEnvironment.addAll(extraEnvironment);
    return await runHook?.call(executable, arguments) ??
        ProcessResult(0, 0, '', '');
  }

  @override
  Future<void> detached(String executable, List<String> arguments) async {
    calls.add((executable, arguments));
    if (failLaunch) {
      throw const ProcessException('installer', [], 'Launch failed');
    }
  }
}
