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
const _releaseRedirect =
    'https://github.com/itzhaolei/codex-usage-widget/releases/latest';
const _releaseManifest =
    'https://cdn.jsdelivr.net/gh/itzhaolei/codex-usage-widget@main/public/update.json';
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
  final int? size;
  final String? sha256Digest;

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

  /// Reads the small public manifest used when the GitHub API is unavailable.
  /// The manifest is accepted only when its installer URL is the exact official
  /// release asset for the declared tag and platform.
  static UpdateRelease? fromManifest(Object? value, UpdatePlatform platform) {
    if (value is! Map) return null;
    final tag = value['tag'];
    if (tag is! String ||
        !RegExp(r'^v\d+\.\d+\.\d+(?:\.\d+)?$').hasMatch(tag)) {
      return null;
    }
    final version = ReleaseVersion.parse(tag);
    if (version == null) return null;
    final key = platform == UpdatePlatform.macOS
        ? 'macos_installer_url'
        : 'windows_installer_url';
    final expectedName =
        'QuotaBubble-${tag.substring(1)}-${platform == UpdatePlatform.macOS ? 'macOS-Installer.zip' : 'Windows-Setup.exe'}';
    final expectedUri = Uri.parse('$quotaReleases/download/$tag/$expectedName');
    final uri = Uri.tryParse('${value[key]}');
    if (uri != expectedUri) return null;

    // Older manifests only contain the two download URLs. Newer manifests
    // may add platform-specific integrity metadata without changing that
    // format. Treat malformed optional metadata as an invalid manifest rather
    // than silently weakening verification.
    final platformName = platform == UpdatePlatform.macOS ? 'macos' : 'windows';
    final rawSize = value['${platformName}_size'] ?? value['size'];
    final size = rawSize == null ? null : _manifestSize(rawSize);
    if (rawSize != null && size == null) return null;
    final rawDigest =
        value['${platformName}_sha256'] ??
        value['${platformName}_sha256_digest'] ??
        value['sha256'];
    final digest = rawDigest == null ? null : _manifestDigest(rawDigest);
    if (rawDigest != null && digest == null) return null;
    return UpdateRelease(
      tag: tag,
      version: version,
      assetName: expectedName,
      downloadUri: uri!,
      size: size,
      sha256Digest: digest,
    );
  }

  static int? _manifestSize(Object value) {
    if (value is! int || value <= 0 || value > _maximumDownload) return null;
    return value;
  }

  static String? _manifestDigest(Object value) {
    if (value is! String) return null;
    final normalized = value.startsWith('sha256:')
        ? value.substring('sha256:'.length)
        : value;
    return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized)
        ? normalized.toLowerCase()
        : null;
  }
}

class UpdateHttpResponse {
  const UpdateHttpResponse(
    this.statusCode,
    this.body, {
    this.contentLength = -1,
    this.effectiveUri,
  });
  final int statusCode;
  final Stream<List<int>> body;
  final int contentLength;
  final Uri? effectiveUri;
}

abstract interface class UpdateTransport {
  Future<UpdateHttpResponse> get(Uri uri);
  void close();
}

/// Independent unauthenticated client: never reads Codex auth or sends tokens.
class HttpUpdateTransport implements UpdateTransport {
  HttpUpdateTransport({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
    if (Platform.isWindows) {
      // Respect the signed-in user's configured system proxy. HttpClient's
      // environment resolver covers WinHTTP/enterprise proxy variables, and
      // authenticateProxy lets the OS negotiate credentials when challenged.
      _client.findProxy = HttpClient.findProxyFromEnvironment;
      _client.authenticateProxy = (host, port, scheme, realm) async {
        final user = Platform.environment['USERNAME'];
        final domain = Platform.environment['USERDOMAIN'];
        if (user == null || user.isEmpty) return false;
        final qualified = domain == null || domain.isEmpty
            ? user
            : '$domain\\$user';
        _client.addProxyCredentials(
          host,
          port,
          realm ?? '',
          HttpClientBasicCredentials(qualified, ''),
        );
        return true;
      };
    }
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
        'cdn.jsdelivr.net',
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
        effectiveUri: uri,
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
      final releases = await _lookupReleases();
      if (_disposed) return latest;
      final candidates = releases
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

  Future<List<UpdateRelease>> _lookupReleases() async {
    Object? lastError;
    // GitHub's API is the only source that can provide complete release
    // metadata, so retry it for transient failures. Fallback sources are each
    // queried once; repeating the whole chain can multiply a single outage
    // into a surprising number of requests.
    try {
      final releases = await _retry(_lookupApiReleases);
      if (releases.isNotEmpty) return releases;
      lastError = const UpdateException(
        'No verified installer is available. Please try again later.',
      );
    } on Object catch (error) {
      lastError = error;
    }

    for (final lookup in <Future<List<UpdateRelease>> Function()>[
      _lookupManifestRelease,
      _lookupRedirectRelease,
    ]) {
      try {
        final releases = await lookup();
        if (releases.isNotEmpty) return releases;
        lastError = const UpdateException(
          'No verified installer is available. Please try again later.',
        );
      } on Object catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? const UpdateException('Could not check for updates.');
  }

  Future<List<UpdateRelease>> _lookupApiReleases() async {
    final json = await _readJson(Uri.parse(_releaseApi));
    if (json is! List) {
      throw const UpdateException(
        'The update server returned an invalid release list.',
      );
    }
    return json
        .map((value) => UpdateRelease.fromJson(value, platform))
        .whereType<UpdateRelease>()
        .toList();
  }

  Future<List<UpdateRelease>> _lookupManifestRelease() async {
    final json = await _readJson(Uri.parse(_releaseManifest));
    final release = UpdateRelease.fromManifest(json, platform);
    return release == null ? const [] : [release];
  }

  Future<List<UpdateRelease>> _lookupRedirectRelease() async {
    final response = await _transport.get(Uri.parse(_releaseRedirect));
    if (response.statusCode != 200) {
      throw UpdateException(
        'Could not check for updates (HTTP ${response.statusCode}).',
      );
    }
    // The transport follows redirects while retaining the final URI. Drain
    // the HTML response so the underlying socket can be reused.
    await response.body.drain<void>();
    final finalUri = response.effectiveUri;
    final segments = finalUri?.pathSegments ?? const <String>[];
    final tag = segments.isNotEmpty && segments.last.startsWith('v')
        ? segments.last
        : null;
    final release = tag == null ? null : _releaseForTag(tag);
    return release == null ? const [] : [release];
  }

  UpdateRelease? _releaseForTag(String tag) {
    final version = ReleaseVersion.parse(tag);
    if (version == null) return null;
    final suffix = platform == UpdatePlatform.macOS
        ? 'macOS-Installer.zip'
        : 'Windows-Setup.exe';
    final name = 'QuotaBubble-${tag.substring(1)}-$suffix';
    return UpdateRelease(
      tag: tag,
      version: version,
      assetName: name,
      downloadUri: Uri.parse('$quotaReleases/download/$tag/$name'),
      size: null,
      sha256Digest: null,
    );
  }

  Future<Object?> _readJson(Uri uri) async {
    final response = await _transport.get(uri);
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
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const UpdateException('The update server returned invalid JSON.');
    }
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
    final expectedSize = release.size;
    final responseSize = response.contentLength;
    if (responseSize > _maximumDownload) {
      throw const UpdateException('The installer is larger than allowed.');
    }
    if (expectedSize != null &&
        responseSize >= 0 &&
        responseSize != expectedSize) {
      throw const UpdateException(
        'The installer size does not match the release.',
      );
    }
    final totalSize = expectedSize ?? (responseSize > 0 ? responseSize : null);
    progress = totalSize == null ? null : 0;
    _notify();
    final output = file.openWrite();
    try {
      await for (final bytes in response.body.timeout(
        const Duration(seconds: 30),
      )) {
        if (_disposed) throw const UpdateException('The update was cancelled.');
        receivedBytes += bytes.length;
        if (receivedBytes > _maximumDownload ||
            (expectedSize != null && receivedBytes > expectedSize)) {
          throw const UpdateException(
            'The installer exceeds its expected size.',
          );
        }
        output.add(bytes);
        if (totalSize != null) {
          final previous = ((progress ?? 0) * 100).floor();
          progress = (receivedBytes / totalSize).clamp(0.0, 1.0);
          if ((progress! * 100).floor() != previous) _notify();
        } else if (receivedBytes == bytes.length ||
            receivedBytes ~/ (256 * 1024) !=
                (receivedBytes - bytes.length) ~/ (256 * 1024)) {
          _notify();
        }
      }
      await output.flush();
    } finally {
      await output.close();
    }
    if (expectedSize != null && receivedBytes != expectedSize) {
      throw const UpdateException(
        'The download ended before the installer was complete.',
      );
    }
    if (release.sha256Digest != null) {
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != release.sha256Digest) {
        throw const UpdateException(
          'The installer checksum does not match the release.',
        );
      }
    }
    final input = await file.open();
    try {
      final header = await input.read(64);
      final valid = platform == UpdatePlatform.macOS
          ? header.length >= 4 &&
                header[0] == 0x50 &&
                header[1] == 0x4b &&
                ((header[2] == 3 && header[3] == 4) ||
                    (header[2] == 5 && header[3] == 6) ||
                    (header[2] == 7 && header[3] == 8))
          : header.length >= 64 && header[0] == 0x4d && header[1] == 0x5a;
      if (!valid) {
        throw const UpdateException(
          'The downloaded file is not a valid installer.',
        );
      }
      if (platform == UpdatePlatform.windows) {
        final offset =
            header[60] | header[61] << 8 | header[62] << 16 | header[63] << 24;
        if (offset < 64 || offset > receivedBytes - 4) {
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
