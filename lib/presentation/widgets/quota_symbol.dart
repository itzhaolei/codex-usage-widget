import 'package:flutter/cupertino.dart';

import 'quota_hardware_symbols.dart';

/// A single macOS-style vector icon set, bundled on both desktop platforms.
/// No OS font lookup or intermediate bitmap is used, so glyphs stay consistent
/// and the Flutter renderer rasterizes them at the current display density.
class QuotaSymbol extends StatelessWidget {
  const QuotaSymbol({
    super.key,
    required this.name,
    required this.size,
    required this.color,
    this.semibold = false,
  });

  final String name;
  final double size;
  final Color color;
  final bool semibold;

  static const names = [
    'sun.max.fill',
    'moon.fill',
    'pin.fill',
    'pin.slash.fill',
    'xmark',
    'person.circle.fill',
    'calendar.badge.clock',
    'internaldrive',
    'memorychip',
    'info.circle.fill',
    'exclamationmark.triangle.fill',
    'xmark.octagon.fill',
  ];

  @override
  Widget build(BuildContext context) {
    final Widget artwork;
    if (name == 'internaldrive' || name == 'memorychip') {
      artwork = QuotaHardwareSymbol(name: name, size: size, color: color);
    } else if (name == 'calendar.badge.clock') {
      artwork = _CalendarClock(size: size, color: color);
    } else {
      final (icon, metricScale) = switch (name) {
        'sun.max.fill' => (CupertinoIcons.sun_max_fill, 16 / 12),
        'moon.fill' => (CupertinoIcons.moon_fill, 15 / 12),
        'pin.fill' => (CupertinoIcons.pin_fill, 15 / 12),
        'pin.slash.fill' => (CupertinoIcons.pin_slash_fill, 15 / 12),
        'xmark' => (CupertinoIcons.xmark, 1.0),
        'person.circle.fill' => (CupertinoIcons.person_circle_fill, 1.2),
        'info.circle.fill' => (CupertinoIcons.info_circle_fill, 1.0),
        'exclamationmark.triangle.fill' => (
          CupertinoIcons.exclamationmark_triangle_fill,
          1.0,
        ),
        'xmark.octagon.fill' => (CupertinoIcons.xmark_octagon_fill, 1.0),
        _ => throw ArgumentError.value(name, 'name', 'Unknown quota symbol'),
      };
      artwork = Icon(
        icon,
        size: size * metricScale,
        color: color,
        textDirection: TextDirection.ltr,
        applyTextScaling: false,
        fontWeight: semibold ? FontWeight.w600 : FontWeight.w400,
      );
    }
    // SF Symbols have natural ink bounds larger than their font point size.
    // Keep those macOS metrics without squeezing the artwork into a square.
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: artwork,
        ),
      ),
    );
  }
}

class _CalendarClock extends StatelessWidget {
  const _CalendarClock({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.4,
    height: size * 1.2,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: const _CalendarBadgeCutout(),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size * 1.3,
              maxWidth: size * 1.3,
              minHeight: size * 1.3,
              maxHeight: size * 1.3,
              child: Icon(
                CupertinoIcons.calendar,
                size: size * 1.3,
                color: color,
                textDirection: TextDirection.ltr,
                applyTextScaling: false,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Icon(
            CupertinoIcons.clock_fill,
            size: size * .6,
            color: color,
            textDirection: TextDirection.ltr,
            applyTextScaling: false,
          ),
        ),
      ],
    ),
  );
}

class _CalendarBadgeCutout extends CustomClipper<Path> {
  const _CalendarBadgeCutout();

  @override
  Path getClip(Size size) {
    // The macOS 10-point symbol has a 14 x 12 natural canvas. Its clock is
    // optically centered at (11, 9); the slightly larger cutout keeps the two
    // filled glyphs from darkening where they overlap.
    final unit = size.width / 14;
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(
        Rect.fromCircle(
          center: Offset(11 * unit, 9 * unit),
          radius: 3.6 * unit,
        ),
      ),
    );
  }

  @override
  bool shouldReclip(_CalendarBadgeCutout oldClipper) => false;
}
