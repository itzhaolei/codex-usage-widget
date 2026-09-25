import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/services/system_capacity_service.dart';

void main() {
  test('timed process runner terminates a stalled child process', () async {
    final process = _HangingProcess();
    final runner = CapacityProcessRunner(
      timeout: const Duration(milliseconds: 10),
      terminationTimeout: const Duration(milliseconds: 10),
      startProcess: (_, _) async => process,
    );

    expect(await runner.run('powershell.exe', const []), isNull);
    expect(process.killCalls, 1);
    expect(await process.exitCode, -1);
  });
}

class _HangingProcess implements Process {
  final Completer<int> _exitCode = Completer<int>();
  int killCalls = 0;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  int get pid => 42;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killCalls++;
    if (!_exitCode.isCompleted) _exitCode.complete(-1);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
