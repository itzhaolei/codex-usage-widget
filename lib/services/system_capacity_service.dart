import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/models.dart';

typedef CapacityProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments,
);

/// Runs a capacity command without allowing a stalled child process to live
/// indefinitely.
class CapacityProcessRunner {
  const CapacityProcessRunner({
    this.timeout = const Duration(seconds: 5),
    this.terminationTimeout = const Duration(seconds: 1),
    CapacityProcessStarter? startProcess,
  }) : // Keep the injectable callback name public for tests.
       // ignore: prefer_initializing_formals
       _startProcess = startProcess;

  final Duration timeout;
  final Duration terminationTimeout;
  final CapacityProcessStarter? _startProcess;

  Future<ProcessResult?> run(String executable, List<String> arguments) async {
    Process process;
    try {
      process = await (_startProcess ?? Process.start)(executable, arguments);
    } on Object {
      return null;
    }

    final stdout = process.stdout
        .expand((chunk) => chunk)
        .toList()
        .catchError((Object _) => <int>[]);
    final stderr = process.stderr
        .expand((chunk) => chunk)
        .toList()
        .catchError((Object _) => <int>[]);
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return ProcessResult(
        process.pid,
        exitCode,
        systemEncoding.decode(await stdout),
        systemEncoding.decode(await stderr),
      );
    } on TimeoutException {
      process.kill();
      try {
        await process.exitCode.timeout(terminationTimeout);
      } on Object {
        // A second termination request covers a process that did not react to
        // the first one while keeping the wait itself bounded.
        process.kill();
      }
      return null;
    } on Object {
      process.kill();
      return null;
    }
  }
}

/// The two capacity values shown by the widget.
class SystemCapacity {
  const SystemCapacity({this.storage, this.memory});

  final CapacityInfo? storage;
  final CapacityInfo? memory;

  // Aliases make the intent clear at call sites that use "disk" or "ram".
  CapacityInfo? get disk => storage;
  CapacityInfo? get ram => memory;
}

/// Reads storage and physical-memory capacity without an FFI plugin.
///
/// macOS uses the built-in `df`, `sysctl`, and `vm_stat` commands.  Windows
/// uses PowerShell's CIM providers.  Unsupported hosts return null values,
/// allowing the rest of the widget to run on development and test machines.
class SystemCapacityService {
  const SystemCapacityService({
    CapacityProcessRunner powerShellRunner = const CapacityProcessRunner(),
  }) : // Keep the injectable runner name public for tests and embedders.
       // ignore: prefer_initializing_formals
       _powerShellRunner = powerShellRunner;

  final CapacityProcessRunner _powerShellRunner;

  Future<SystemCapacity> read() async {
    if (!Platform.isMacOS && !Platform.isWindows) {
      return const SystemCapacity();
    }

    final results = await Future.wait<CapacityInfo?>([
      readStorage(),
      readMemory(),
    ]);
    return SystemCapacity(storage: results[0], memory: results[1]);
  }

  Future<CapacityInfo?> readStorage() {
    if (Platform.isMacOS) return _readMacStorage();
    if (Platform.isWindows) return _readWindowsStorage();
    return Future<CapacityInfo?>.value();
  }

  Future<CapacityInfo?> readMemory() {
    if (Platform.isMacOS) return _readMacMemory();
    if (Platform.isWindows) return _readWindowsMemory();
    return Future<CapacityInfo?>.value();
  }

  Future<CapacityInfo?> storage() => readStorage();

  Future<CapacityInfo?> memory() => readMemory();

  Future<CapacityInfo?> _readMacStorage() async {
    final result = await _run('df', const ['-kP', '/']);
    if (result == null || result.exitCode != 0) return null;

    // POSIX output has one header followed by one data row.  `-P` keeps the
    // data row on one line even when the filesystem name contains spaces.
    final lines = result.stdout.toString().trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) return null;
    final fields = lines[1].trim().split(RegExp(r'\s+'));
    if (fields.length < 5) return null;
    final totalBlocks = int.tryParse(fields[1]);
    final availableBlocks = int.tryParse(fields[3]);
    if (totalBlocks == null ||
        availableBlocks == null ||
        totalBlocks < 0 ||
        availableBlocks < 0) {
      return null;
    }
    return CapacityInfo(
      availableBytes: _saturatingBytes(availableBlocks, 1024),
      totalBytes: _saturatingBytes(totalBlocks, 1024),
    );
  }

  Future<CapacityInfo?> _readMacMemory() async {
    final totalResult = await _run('sysctl', const ['-n', 'hw.memsize']);
    final total = _parseFirstInteger(totalResult?.stdout);
    if (total == null || total <= 0) return null;

    final pageSizeResult = await _run('sysctl', const ['-n', 'hw.pagesize']);
    final pageSize = _parseFirstInteger(pageSizeResult?.stdout) ?? 4096;
    if (pageSize <= 0) return null;

    final vmStat = await _run('vm_stat', const []);
    final availablePages = _parseMacAvailablePages(vmStat?.stdout);
    if (availablePages == null) return null;
    final available = _multiplySafely(availablePages, pageSize);
    return CapacityInfo(
      availableBytes: available.clamp(0, total).toInt(),
      totalBytes: total,
    );
  }

  Future<CapacityInfo?> _readWindowsStorage() async {
    final output = await _runPowerShell(
      r'''$d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"; if ($d) { Write-Output "$($d.FreeSpace) $($d.Size)" }''',
    );
    final values = _parseIntegers(output);
    if (values.length < 2 || values[0] < 0 || values[1] <= 0) return null;
    return CapacityInfo(availableBytes: values[0], totalBytes: values[1]);
  }

  Future<CapacityInfo?> _readWindowsMemory() async {
    final output = await _runPowerShell(
      r'''$m = Get-CimInstance Win32_OperatingSystem; if ($m) { Write-Output "$([int64]$m.FreePhysicalMemory * 1024) $([int64]$m.TotalVisibleMemorySize * 1024)" }''',
    );
    final values = _parseIntegers(output);
    if (values.length < 2 || values[0] < 0 || values[1] <= 0) return null;
    return CapacityInfo(availableBytes: values[0], totalBytes: values[1]);
  }

  Future<ProcessResult?> _run(String executable, List<String> arguments) async {
    try {
      return await Process.run(executable, arguments);
    } on Object {
      return null;
    }
  }

  Future<String?> _runPowerShell(String command) async {
    for (final executable in <String>['powershell.exe', 'powershell', 'pwsh']) {
      final result = await _powerShellRunner.run(executable, <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        command,
      ]);
      if (result != null && result.exitCode == 0) {
        return result.stdout.toString();
      }
    }
    return null;
  }

  static int? _parseFirstInteger(Object? output) {
    final values = _parseIntegers(output);
    return values.isEmpty ? null : values.first;
  }

  static List<int> _parseIntegers(Object? output) {
    if (output == null) return const <int>[];
    final text = output.toString();
    return RegExp(r'\d+')
        .allMatches(text)
        .map((match) {
          return int.tryParse(match.group(0)!);
        })
        .whereType<int>()
        .toList(growable: false);
  }

  static int? _parseMacAvailablePages(Object? output) {
    if (output == null) return null;
    var pages = 0;
    var found = false;
    for (final line in const LineSplitter().convert(output.toString())) {
      final match = RegExp(r'^Pages\s+([^:]+):\s*(\d+)')
          .firstMatch(line.trim());
      if (match == null) continue;
      final name = match.group(1)!.toLowerCase();
      if (!name.contains('free') &&
          !name.contains('inactive') &&
          !name.contains('speculative')) {
        continue;
      }
      final value = int.tryParse(match.group(2)!);
      if (value != null) {
        pages += value;
        found = true;
      }
    }
    return found ? pages : null;
  }

  static int _saturatingBytes(int value, int multiplier) =>
      _multiplySafely(value, multiplier);

  static int _multiplySafely(int value, int multiplier) {
    if (value <= 0 || multiplier <= 0) return 0;
    final maxInt = 0x7fffffffffffffff;
    if (value > maxInt ~/ multiplier) return maxInt;
    return value * multiplier;
  }
}
