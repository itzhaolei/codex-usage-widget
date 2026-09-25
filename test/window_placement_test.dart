import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/platform/window_placement.dart';

void main() {
  const windowSize = Size(330, 287);

  test(
    'restores a saved position intersecting any display work area',
    () async {
      final position = await validatedSavedWindowPosition(
        left: -320,
        top: 40,
        windowSize: windowSize,
        readVisibleAreas: () async => const [
          Rect.fromLTWH(0, 24, 1440, 876),
          Rect.fromLTWH(-1920, 0, 1920, 1080),
        ],
      );

      expect(position, const Offset(-320, 40));
    },
  );

  test('rejects a saved position after its display is disconnected', () async {
    final position = await validatedSavedWindowPosition(
      left: 1800,
      top: 200,
      windowSize: windowSize,
      readVisibleAreas: () async => const [Rect.fromLTWH(0, 24, 1440, 876)],
    );

    expect(position, isNull);
  });

  test('requires a positive-area intersection with a visible work area', () {
    expect(
      windowIntersectsVisibleArea(
        position: const Offset(1440, 100),
        windowSize: windowSize,
        visibleAreas: const [Rect.fromLTWH(0, 24, 1440, 876)],
      ),
      isFalse,
    );
    expect(
      windowIntersectsVisibleArea(
        position: const Offset(1439, 100),
        windowSize: windowSize,
        visibleAreas: const [Rect.fromLTWH(0, 24, 1440, 876)],
      ),
      isTrue,
    );
  });

  test('rejects invalid coordinates and display lookup failures', () async {
    expect(
      await validatedSavedWindowPosition(
        left: double.nan,
        top: 20,
        windowSize: windowSize,
        readVisibleAreas: () async => const [Rect.fromLTWH(0, 0, 1440, 900)],
      ),
      isNull,
    );
    expect(
      await validatedSavedWindowPosition(
        left: 20,
        top: 20,
        windowSize: windowSize,
        readVisibleAreas: () async => throw StateError('display unavailable'),
      ),
      isNull,
    );
  });
}
