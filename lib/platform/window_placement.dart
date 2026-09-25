import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';

typedef VisibleAreaReader = Future<List<Rect>> Function();

bool windowIntersectsVisibleArea({
  required Offset position,
  required Size windowSize,
  required Iterable<Rect> visibleAreas,
}) {
  final windowBounds = position & windowSize;
  if (!windowBounds.isFinite || windowBounds.isEmpty) return false;
  return visibleAreas.any(
    (area) => area.isFinite && !area.isEmpty && windowBounds.overlaps(area),
  );
}

Future<Offset?> validatedSavedWindowPosition({
  required double? left,
  required double? top,
  required Size windowSize,
  VisibleAreaReader? readVisibleAreas,
}) async {
  if (left == null || top == null || !left.isFinite || !top.isFinite) {
    return null;
  }
  final position = Offset(left, top);
  try {
    final visibleAreas = await (readVisibleAreas ?? currentVisibleAreas).call();
    return windowIntersectsVisibleArea(
          position: position,
          windowSize: windowSize,
          visibleAreas: visibleAreas,
        )
        ? position
        : null;
  } on Object {
    return null;
  }
}

Future<List<Rect>> currentVisibleAreas() async {
  final displays = await screenRetriever.getAllDisplays();
  final areas = <Rect>[];
  for (final display in displays) {
    final position = display.visiblePosition;
    final size = display.visibleSize;
    if (position == null || size == null) continue;
    final area = position & size;
    if (area.isFinite && !area.isEmpty) areas.add(area);
  }
  return areas;
}
