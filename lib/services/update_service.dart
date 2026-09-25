import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/codex_paths.dart';

const quotaWebsite =
    'https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4';
const quotaReleases =
    'https://github.com/itzhaolei/codex-usage-widget/releases';
const _releaseApi =
    'https://api.github.com/repos/itzhaolei/codex-usage-widget/releases?per_page=30';
const _maximumDownload = 512 * 1024 * 1024;

enum UpdatePlatform { macOS, windows }

enum UpdateState {
  idle,
  checking,
  current,
  available,
  downloading,
  installing,
  restarting,
  failed,
}

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Numeric release versions only; preview tags can never become auto-updates.
class ReleaseVersion implements Comparable<ReleaseVersion> {
  const ReleaseVersion._(this.parts);
  final List<int> parts;

  static ReleaseVersion? parse(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?(?:\+\d+)?$')
        .firstMatch(value.trim());
    if (match == null) return null;
    final parts = <int>[];
    for (var i = 1; i <= 4; i++) {
      final part = int.tryParse(match.group(i) ?? '0');
      if (part == null) return null;
      parts.add(part);
    }
    return ReleaseVersion._(List.unmodifiable(parts));
  }

  @override
  int compareTo(ReleaseVersion other) {
    for (var i = 0; i < parts.length; i++) {
      final result = parts[i].compareTo(other.parts[i]);
      if (result != 0) return result;
    }
    return 0;
  }
}

class UpdateRelease {
  const UpdateRelease({
    required this.tag,
    required this.version,
    required this.assetName,
    required this.downloadUri,
    required this.size,
    required this.sha256Digest,
  });
  final String tag;
  final ReleaseVersion version;
  final String assetName;
  final Uri downloadUri;
  final int size;
  final String sha256Digest;

  /// Uses only the exact platform asset in an official, published GitHub release.
  static UpdateRelease? fromJson(Object? value, UpdatePlatform platform) {
    if (value is! Map ||
        value['draft'] == true ||
        value['prerelease'] == true) {
      return null;
    }
    final tag = value['tag_name'];
    if (tag is! String ||
        !RegExp(r'^v\d+\.\d+\.\d+(?:\.\d+)?$').hasMatch(tag)) {
      return null;
    }
    final version = ReleaseVersion.parse(tag);
    if (version == null) return null;
    final suffix = platform == UpdatePlatform.macOS
        ? 'macOS-Installer.zip'
        : 'Windows-Setup.exe';
    final expectedName = 'QuotaBubble-${tag.substring(1)}-$suffix';
    final expectedUri = Uri.parse('$quotaReleases/download/$tag/$expectedName');
    final assets = value['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map ||
          asset['name'] != expectedName ||
          asset['state'] != 'uploaded') {
        continue;
      }
      final uri = Uri.tryParse('${asset['browser_download_url']}');
      final digest = asset['digest'];
      final size = asset['size'];
      if (uri != expectedUri ||
          size is! int ||
          size <= 0 ||
          size > _maximumDownload ||
          digest is! String ||
          !RegExp(r'^sha256:[0-9a-fA-F]{64}$').hasMatch(digest)) {
        continue;
      }
      return UpdateRelease(
        tag: tag,
        version: version,
        assetName: expectedName,
        downloadUri: uri!,
        size: size,
        sha256Digest: digest.substring(7).toLowerCase(),
      );
    }
    return null;
  }
}

class UpdateHttpResponse {
  const UpdateHttpResponse(
    this.statusCode,
    this.body, {
    this.contentLength = -1,
  });
  final int statusCode;
  final Stream<List<int>> body;
  final int contentLength;
}

abstract interface class UpdateTransport {
  Future<UpdateHttpResponse> get(Uri uri);
  void close();
}

/// Independent unauthenticated client: never reads Codex auth or sends tokens.
class HttpUpdateTransport implements UpdateTransport {
  HttpUpdateTransport({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }
  final HttpClient _client;

  static bool allowedUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      const {
        'api.github.com',
        'github.com',
        'release-assets.githubusercontent.com',
        'objects.githubusercontent.com',
        'github-releases.githubusercontent.com',
      }.contains(uri.host);

  @override
  Future<UpdateHttpResponse> get(Uri uri) async {
    for (var redirects = 0; redirects <= 5; redirects++) {
      if (!allowedUri(uri)) {
        throw const UpdateException(
          'The update server returned an invalid download address.',
        );
      }
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, 'Quota-Bubble-Updater');
      request.headers.set(
        HttpHeaders.acceptHeader,
        uri.host == 'api.github.com'
            ? 'application/vnd.github+json'
            : 'application/octet-stream',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>().timeout(const Duration(seconds: 15));
        if (location == null) break;
        uri = uri.resolve(location);
        continue;
      }
      return UpdateHttpResponse(
        response.statusCode,
        response,
        contentLength: response.contentLength,
      );
    }
    throw const UpdateException(
      'The update server returned too many redirects.',
    );
  }

  @override
  void close() => _client.close(force: true);
}

/// All subprocesses inherit only OS paths and locale, excluding account tokens.
class UpdateCommands {
  Map<String, String> environment([Map<String, String> extra = const {}]) {
    const allowed = {
      'PATH',
      'HOME',
      'USERPROFILE',
      'LOCALAPPDATA',
      'APPDATA',
      'SYSTEMROOT',
      'WINDIR',
      'COMSPEC',
      'TEMP',
      'TMP',
      'TMPDIR',
      'LANG',
      'LC_ALL',
      'CODEX_HOME',
    };
    return {
      for (final entry in Platform.environment.entries)
        if (allowed.contains(entry.key.toUpperCase())) entry.key: entry.value,
      ...extra,
    };
  }

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String> extraEnvironment = const {},
  }) => Process.run(
    executable,
    arguments,
    includeParentEnvironment: false,
    environment: environment(extraEnvironment),
  );

  Future<void> detached(String executable, List<String> arguments) async {
    await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.detached,
      includeParentEnvironment: false,
      environment: environment(),
    );
  }
}

class UpdateService extends ChangeNotifier {
  UpdateService({
    required this.currentVersion,
    UpdatePlatform? platform,
    UpdateTransport? transport,
    UpdateCommands? commands,
    DateTime Function()? clock,
    Future<Directory> Function()? temporaryDirectory,
    Future<void> Function(Duration)? delay,
    String? executablePath,
  }) : platform =
           platform ??
           (Platform.isWindows ? UpdatePlatform.windows : UpdatePlatform.macOS),
       _transport = transport ?? HttpUpdateTransport(),
       _commands = commands ?? UpdateCommands(),
       _clock = clock ?? DateTime.now,
       _temporaryDirectory =
           temporaryDirectory ??
           (() => Directory.systemTemp.createTemp('quota-bubble-update-')),
       _delay = delay ?? Future<void>.delayed,
       _executablePath = executablePath ?? Platform.resolvedExecutable;

  final String currentVersion;
  final UpdatePlatform platform;
  final UpdateTransport _transport;
  final UpdateCommands _commands;
  final DateTime Function() _clock;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<void> Function(Duration) _delay;
  final String _executablePath;
  UpdateState state = UpdateState.idle;
  UpdateRelease? latest;
  String? error;
  double? progress;
  int receivedBytes = 0;
  DateTime? _lastCheck;
  Timer? _timer;
  bool _disposed = false;
  bool get busy => {
    UpdateState.checking,
    UpdateState.downloading,
    UpdateState.installing,
    UpdateState.restarting,
  }.contains(state);
  bool get hasUpdate {
    final current = ReleaseVersion.parse(currentVersion);
    return current != null &&
        latest != null &&
        current.compareTo(latest!.version) < 0;
  }

  void start() {
    if (_disposed || _timer != null) return;
    unawaited(check());
    _timer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => unawaited(check()),
    );
  }

  Future<UpdateRelease?> check({bool force = false}) async {
    if (_disposed || busy) return latest;
    if (!force &&
        _lastCheck != null &&
        _clock().difference(_lastCheck!) < const Duration(minutes: 30)) {
      return latest;
    }
    _lastCheck = _clock();
    _setState(UpdateState.checking);
    error = null;
    try {
      if (ReleaseVersion.parse(currentVersion) == null) {
        throw const UpdateException('The installed version is invalid.');
      }
      final releases = await _retry(() async {
        final response = await _transport.get(Uri.parse(_releaseApi));
        if (response.statusCode != 200) {
          throw UpdateException(
            'Could not check for updates (HTTP ${response.statusCode}).',
          );
        }
        final bytes = <int>[];
        await for (final chunk in response.body.timeout(
          const Duration(seconds: 20),
        )) {
          bytes.addAll(chunk);
          if (bytes.length > 4 * 1024 * 1024) {
            throw const UpdateException('The update response is too large.');
          }
        }
        final json = jsonDecode(utf8.decode(bytes));
        if (json is! List) {
          throw const UpdateException(
            'The update server returned an invalid release list.',
          );
        }
        return json;
      });
      if (_disposed) return latest;
      final candidates =
          releases
              .map((json) => UpdateRelease.fromJson(json, platform))
              .whereType<UpdateRelease>()
              .toList()
            ..sort((a, b) => b.version.compareTo(a.version));
      if (candidates.isEmpty) {
        throw const UpdateException(
          'No verified installer is available. Please try again later.',
        );
      }
      latest = candidates.first;
      _setState(hasUpdate ? UpdateState.available : UpdateState.current);
    } on Object catch (exception) {
      _fail(exception);
    }
    return latest;
  }

  /// This is only called by an explicit user action, never the periodic check.
  Future<bool> downloadAndInstall({
    required Future<void> Function() onExit,
  }) async {
    if (_disposed || busy || !hasUpdate) return false;
    final release = latest!;
    Directory? directory;
    var keepInstaller = false;
    try {
      error = null;
      progress = 0;
      _setState(UpdateState.downloading);
      directory = await _temporaryDirectory();
      final installer = File(
        '${directory.path}${Platform.pathSeparator}${release.assetName}',
      );
      await _retry(() => _download(release, installer));
      if (_disposed) return false;
      _setState(UpdateState.installing);
      if (platform == UpdatePlatform.macOS) {
        await _installMac(installer, directory, release);
      } else {
        await _commands.detached(installer.path, [
          '/VERYSILENT',
          '/SUPPRESSMSGBOXES',
          '/NORESTART',
          '/CLOSEAPPLICATIONS',
          '/RESTARTAPPLICATIONS',
        ]);
        keepInstaller = true; // Windows still reads the launched executable.
      }
      if (_disposed) return false;
      progress = 1;
      _setState(UpdateState.restarting);
      await onExit();
      return true;
    } on Object catch (exception) {
      _fail(exception);
      return false;
    } finally {
      if (directory != null && !keepInstaller) {
        try {
          await directory.delete(recursive: true);
        } on FileSystemException {
          /* Best effort. */
        }
      }
    }
  }

  Future<void> _download(UpdateRelease release, File file) async {
    receivedBytes = 0;
    progress = 0;
    _notify();
    final response = await _transport.get(release.downloadUri);
    if (response.statusCode != 200) {
      throw UpdateException('Download failed (HTTP ${response.statusCode}).');
    }
    if (response.contentLength >= 0 && response.contentLength != release.size) {
      throw const UpdateException(
        'The installer size does not match the release.',
      );
    }
    final output = file.openWrite();
    try {
      await for (final bytes in response.body.timeout(
        const Duration(seconds: 30),
      )) {
        if (_disposed) throw const UpdateException('The update was cancelled.');
        receivedBytes += bytes.length;
        if (receivedBytes > release.size) {
          throw const UpdateException(
            'The installer exceeds its expected size.',
          );
        }
        output.add(bytes);
        final previous = ((progress ?? 0) * 100).floor();
        progress = receivedBytes / release.size;
        if ((progress! * 100).floor() != previous) _notify();
      }
      await output.flush();
    } finally {
      await output.close();
    }
    if (receivedBytes != release.size) {
      throw const UpdateException(
        'The download ended before the installer was complete.',
      );
    }
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != release.sha256Digest) {
      throw const UpdateException(
        'The installer checksum does not match the release.',
      );
    }
    final input = await file.open();
    try {
      final header = await input.read(64);
      final valid = platform == UpdatePlatform.macOS
          ? header.length >= 4 &&
                header[0] == 0x50 &&
                header[1] == 0x4b &&
                header[2] == 3 &&
                header[3] == 4
          : header.length >= 64 && header[0] == 0x4d && header[1] == 0x5a;
      if (!valid) {
        throw const UpdateException(
          'The downloaded file is not a valid installer.',
        );
      }
      if (platform == UpdatePlatform.windows) {
        final offset =
            header[60] | header[61] << 8 | header[62] << 16 | header[63] << 24;
        if (offset < 64 || offset > release.size - 4) {
          throw const UpdateException(
            'The installer executable header is invalid.',
          );
        }
        await input.setPosition(offset);
        final pe = await input.read(4);
        if (!listEquals(pe, [0x50, 0x45, 0, 0])) {
          throw const UpdateException(
            'The installer executable signature is invalid.',
          );
        }
      }
    } finally {
      await input.close();
    }
  }

  Future<void> _installMac(
    File installer,
    Directory directory,
    UpdateRelease release,
  ) async {
    final listing = await _commands.run('/usr/bin/unzip', [
      '-Z1',
      installer.path,
    ]);
    if (listing.exitCode != 0) {
      throw const UpdateException('The installer archive could not be read.');
    }
    for (final path in const LineSplitter().convert('${listing.stdout}')) {
      if (path.startsWith('/') ||
          path.contains('\\') ||
          path.split('/').contains('..') ||
          !path.startsWith('Install Quota Bubble.app/')) {
        throw const UpdateException(
          'The installer archive contains an invalid path.',
        );
      }
    }
    final unpacked = Directory('${directory.path}/unpacked');
    await unpacked.create();
    final extraction = await _commands.run('/usr/bin/ditto', [
      '-x',
      '-k',
      installer.path,
      unpacked.path,
    ]);
    if (extraction.exitCode != 0) {
      throw const UpdateException(
        'The installer archive could not be extracted.',
      );
    }
    final resources =
        '${unpacked.path}/Install Quota Bubble.app/Contents/Resources';
    final script = File('$resources/install-packaged.sh');
    final unpackedPath = await unpacked.resolveSymbolicLinks();
    if (!await script.exists() ||
        !_isPathWithin(await script.resolveSymbolicLinks(), unpackedPath)) {
      throw const UpdateException(
        'The installer script is missing or invalid.',
      );
    }
    final plist = '$resources/payload/Quota Bubble.app/Contents/Info.plist';
    final identifier = await _commands.run('/usr/libexec/PlistBuddy', [
      '-c',
      'Print :CFBundleIdentifier',
      plist,
    ]);
    final version = await _commands.run('/usr/libexec/PlistBuddy', [
      '-c',
      'Print :CFBundleShortVersionString',
      plist,
    ]);
    if (identifier.exitCode != 0 ||
        '${identifier.stdout}'.trim() != 'local.codex.quota-bubble' ||
        version.exitCode != 0 ||
        '${version.stdout}'.trim() != release.tag.substring(1)) {
      throw const UpdateException(
        'The installer contains a different app or version.',
      );
    }
    final result = await _commands.run(
      '/bin/bash',
      [script.path],
      extraEnvironment: {
        'QUOTA_BUBBLE_KEEP_RUNNING': '1',
        'QUOTA_BUBBLE_SKIP_LAUNCH': '1',
        'QUOTA_BUBBLE_SKIP_DOCK': '1',
      },
    );
    if (result.exitCode != 0) {
      throw const UpdateException(
        'Installation failed. Your current app is still running.',
      );
    }
    await _commands.detached('/bin/bash', [
      '-c',
      'while /bin/kill -0 "\$1" 2>/dev/null; do /bin/sleep 0.2; done; /usr/bin/open -g "\$2"',
      'quota-bubble-restart',
      '$pid',
      '/Applications/Quota Bubble.app',
    ]);
  }

  Future<T> _retry<T>(Future<T> Function() operation) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await operation();
      } on Object {
        if (_disposed || attempt >= 2) rethrow;
        await _delay(Duration(milliseconds: attempt == 0 ? 600 : 1600));
      }
    }
  }

  Future<void> openWebsite() async {
    if (platform == UpdatePlatform.macOS) {
      final result = await _commands.run('/usr/bin/open', [quotaWebsite]);
      if (result.exitCode != 0) {
        throw const UpdateException('The website could not be opened.');
      }
    } else {
      final system = Platform.environment['SystemRoot'] ?? r'C:\Windows';
      await _commands.detached('$system\\System32\\rundll32.exe', [
        'url.dll,FileProtocolHandler',
        quotaWebsite,
      ]);
    }
  }

  Future<void> shareWebsite() =>
      Clipboard.setData(const ClipboardData(text: quotaWebsite));

  /// The confirmation dialog calls this method; background checks never do.
  Future<void> uninstall({required Future<void> Function() onExit}) async {
    if (busy || _disposed) return;
    if (platform == UpdatePlatform.macOS) {
      final script = File('${resolveCodexHome()}/usage-widget/uninstall.sh');
      if (!await script.exists()) {
        throw const UpdateException('The installed uninstaller was not found.');
      }
      final temporary = await _temporaryDirectory();
      final copied = await script.copy('${temporary.path}/uninstall.sh');
      try {
        await _commands.detached('/bin/bash', [
          '-c',
          'while /bin/kill -0 "\$1" 2>/dev/null; do /bin/sleep 0.2; done; /bin/bash "\$2"; result=\$?; /bin/rm -rf -- "\$3"; exit "\$result"',
          'quota-bubble-uninstall',
          '$pid',
          copied.path,
          temporary.path,
        ]);
      } on Object {
        await temporary.delete(recursive: true);
        rethrow;
      }
    } else {
      final uninstaller = File(
        '${File(_executablePath).parent.path}${Platform.pathSeparator}unins000.exe',
      );
      if (!await uninstaller.exists()) {
        throw const UpdateException('The installed uninstaller was not found.');
      }
      await _commands.detached(uninstaller.path, [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
      ]);
    }
    await onExit();
  }

  void _setState(UpdateState value) {
    state = value;
    _notify();
  }

  void _fail(Object exception) {
    if (_disposed) return;
    error = exception is UpdateException
        ? exception.message
        : 'The update could not be completed. Please try again.';
    _setState(UpdateState.failed);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _transport.close();
    super.dispose();
  }
}

/// Compares canonical paths without assuming the host's separator style.
/// The macOS installer is exercised by cross-platform tests on Windows too.
bool _isPathWithin(String child, String parent) {
  String normalize(String value) {
    var normalized = value.replaceAll('\\', '/');
    normalized = normalized.replaceAll(RegExp(r'/+'), '/');
    if (Platform.isWindows) normalized = normalized.toLowerCase();
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  final normalizedChild = normalize(child);
  final normalizedParent = normalize(parent);
  if (normalizedChild == normalizedParent) return false;
  final prefix = normalizedParent.endsWith('/')
      ? normalizedParent
      : '$normalizedParent/';
  return normalizedChild.startsWith(prefix);
}
