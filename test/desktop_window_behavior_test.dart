import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/desktop_app.dart';

void main() {
  test('Windows main window remains visible in the taskbar', () {
    final options = quotaWindowOptions(height: 287, isMacOS: false);

    expect(options.skipTaskbar, isFalse);
    expect(options.alwaysOnTop, isTrue);
  });

  test('macOS pin changes use the native window-level bridge', () async {
    final nativeValues = <bool>[];
    final windowManagerValues = <bool>[];

    await setPinnedWindowLevel(
      true,
      isMacOS: true,
      macOSSetter: (value) async => nativeValues.add(value),
      windowManagerSetter: (value) async => windowManagerValues.add(value),
    );
    await setPinnedWindowLevel(
      false,
      isMacOS: true,
      macOSSetter: (value) async => nativeValues.add(value),
      windowManagerSetter: (value) async => windowManagerValues.add(value),
    );

    expect(nativeValues, [true, false]);
    expect(windowManagerValues, isEmpty);
  });

  test('Windows pin changes keep using window_manager', () async {
    final nativeValues = <bool>[];
    final windowManagerValues = <bool>[];

    await setPinnedWindowLevel(
      true,
      isMacOS: false,
      macOSSetter: (value) async => nativeValues.add(value),
      windowManagerSetter: (value) async => windowManagerValues.add(value),
    );

    expect(nativeValues, isEmpty);
    expect(windowManagerValues, [true]);
  });
}
