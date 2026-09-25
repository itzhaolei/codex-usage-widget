import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/quota_recharge_event.dart';
import 'quota_animation.dart';

/// The 231 × 35 quota canvas, including its unfilled dotted field.
/// [frame] lets a progress group synchronize palette, number and bar animation.
class QuotaProgressBar extends StatelessWidget {
  const QuotaProgressBar({
    super.key,
    required this.percent,
    this.color,
    this.selectedColorIndex = 0,
    this.rechargeEvent,
    this.animationsEnabled = true,
    this.frame,
  });

  final int? percent;
  final Color? color;
  final int selectedColorIndex;
  final QuotaRechargeEvent? rechargeEvent;
  final bool animationsEnabled;
  final QuotaAnimationFrame? frame;

  @override
  Widget build(BuildContext context) {
    final supplied = frame;
    if (supplied != null) return _canvas(supplied);
    return QuotaAnimationBuilder(
      percent: percent,
      rechargeEvent: rechargeEvent,
      animationsEnabled: animationsEnabled,
      builder: (_, value) => _canvas(value),
    );
  }

  Widget _canvas(QuotaAnimationFrame value) => RepaintBoundary(
    child: SizedBox.fromSize(
      size: quotaProgressSize,
      child: CustomPaint(
        painter: _QuotaProgressPainter(
          frame: value,
          selectedIndex: selectedColorIndex.clamp(0, 4),
          overrideColor: color,
        ),
      ),
    ),
  );
}

class _QuotaProgressPainter extends CustomPainter {
  const _QuotaProgressPainter({
    required this.frame,
    required this.selectedIndex,
    this.overrideColor,
  });

  final QuotaAnimationFrame frame;
  final int selectedIndex;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final percentage = frame.percentage.clamp(0.0, 100.0);
    // Match the macOS system red used by the established design.
    final color = percentage <= 20
        ? const Color(0xffff3b30)
        : overrideColor ?? quotaProgressPalette[selectedIndex];
    final filled = size.width * percentage / 100;
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, filled, size.height), paint);

    if (filled < size.width) {
      for (var x = math.max(0.0, filled + 1); x <= size.width; x += 3) {
        for (var y = 1.0; y <= size.height; y += 3) {
          final offset = (y / 3).toInt().isEven ? 0.0 : 1.5;
          canvas.drawOval(Rect.fromLTWH(x + offset, y, 1, 1), paint);
        }
      }
    }
    paint.color = color.withValues(alpha: .48);
    for (var index = 1; index < 5; index++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * index / 5, 0, .6, size.height),
        paint,
      );
    }

    if (filled > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, filled, size.height));
      _paintSparkles(
        canvas,
        Size(filled, size.height),
        selectedIndex == 0 && percentage > 20,
      );
      canvas.restore();
    }
    if (frame.propulsionActive) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      _paintPropulsion(canvas, size);
      canvas.restore();
    }
    final elapsed = frame.elapsed;
    if (elapsed != null) _paintOrbit(canvas, size, elapsed);
  }

  void _paintSparkles(Canvas canvas, Size size, bool emphasized) {
    final time = frame.sparkleTime;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var index = 0; index < (emphasized ? 58 : 46); index++) {
      final speed = .006 + quotaRandom(index * 17 + 3) * .014;
      final xUnit = quotaPhase(quotaRandom(index * 19 + 5) + time * speed);
      final baseY = .12 + quotaRandom(index * 23 + 7) * .76;
      final drift =
          math.sin(time * (.7 + quotaRandom(index * 29 + 11)) + index) * 1.2;
      final y = size.height * baseY + drift;
      final pulse =
          (math.sin(
                time * (1.4 + quotaRandom(index * 31 + 13) * 2.2) + index * 1.7,
              ) +
              1) /
          2;
      final opacity =
          (emphasized ? .16 : .08) +
          math.pow(pulse, 3) * (emphasized ? .78 : .62);
      final diameter =
          (emphasized ? .75 : .55) +
          quotaRandom(index * 37 + 17) * (emphasized ? 1.35 : 1.15);
      paint.color = Colors.white.withValues(alpha: opacity.toDouble());
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * xUnit - diameter / 2,
          y - diameter / 2,
          diameter,
          diameter,
        ),
        paint,
      );
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasized ? .7 : .55;
    for (var index = 0; index < (emphasized ? 11 : 8); index++) {
      final speed = .004 + quotaRandom(index * 41 + 19) * .008;
      final xUnit = quotaPhase(quotaRandom(index * 43 + 23) + time * speed);
      final y = size.height * (.2 + quotaRandom(index * 47 + 29) * .6);
      final pulse =
          (math.sin(
                time * (1.1 + quotaRandom(index * 53 + 31) * 1.5) + index * 2.3,
              ) +
              1) /
          2;
      final radius = 1.2 + pulse * 1.25;
      final x = size.width * xUnit;
      paint.color = Colors.white.withValues(
        alpha: (emphasized ? .2 : .12) + pulse * (emphasized ? .72 : .58),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - radius, y)
          ..lineTo(x + radius, y)
          ..moveTo(x, y - radius)
          ..lineTo(x, y + radius),
        paint,
      );
    }
  }

  void _paintPropulsion(Canvas canvas, Size size) {
    const gold = Color.fromRGBO(255, 148, 5, 1);
    final progress = frame.progress;
    final centerY = size.height / 2;
    final length = math.min(145.0, size.width * .62);
    final head = _headX(size.width, length);
    final tailStart = head - length;
    final drawStart = math.max(0.0, tailStart);
    final drawEnd = math.min(size.width, head);
    if (drawEnd <= drawStart) return;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < 8; index++) {
      final depth = index / 7;
      final amplitude = 2.2 + quotaRandom(index * 17 + 3) * 7;
      final cycles = .7 + quotaRandom(index * 19 + 5) * 1.25;
      final speed = .55 + quotaRandom(index * 23 + 7) * 1.5;
      final phase =
          progress * speed * 2 * math.pi +
          quotaRandom(index * 29 + 11) * 2 * math.pi;
      final baseOffset =
          (quotaRandom(index * 31 + 13) - .5) * size.height * .42;
      paint.strokeWidth = .45 + (1 - depth) * .75;
      Offset? previous;
      for (var x = drawStart; x <= drawEnd; x += 3) {
        final unit = quotaUnit((x - tailStart) / length);
        final convergence = math.pow(math.max(0.0, 1 - unit), .72);
        final wave = math.sin(unit * cycles * 2 * math.pi + phase);
        final secondary =
            math.sin(unit * cycles * .47 * 2 * math.pi - phase * .42) * .34;
        final point = Offset(
          x,
          centerY + (baseOffset + (wave + secondary) * amplitude) * convergence,
        );
        if (previous != null) {
          final tail = math.pow(unit, 1.45);
          paint.color = gold.withValues(
            alpha: ((.08 + tail * .72) * (.48 + (1 - depth) * .52)).toDouble(),
          );
          canvas.drawLine(previous, point, paint);
        }
        previous = point;
      }
    }
    paint.style = PaintingStyle.fill;
    for (var index = 0; index < 52; index++) {
      final velocity = .06 + quotaRandom(index * 41 + 19) * .16;
      final unit = quotaPhase(
        quotaRandom(index * 37 + 17) + progress * velocity,
      );
      final x = tailStart + unit * length;
      if (x < 0 || x > size.width) continue;
      final y = quotaRandom(index * 43 + 23) * size.height;
      final diameter = .45 + quotaRandom(index * 47 + 29) * 1.05;
      paint.color = gold.withValues(
        alpha: (.05 + math.pow(unit, 1.8) * .55).toDouble(),
      );
      canvas.drawOval(Rect.fromLTWH(x, y, diameter, diameter), paint);
    }
    final glowWidth = math.min(11.0, length);
    final glow = Rect.fromLTWH(
      head - glowWidth,
      centerY - size.height * .38,
      glowWidth,
      size.height * .76,
    );
    paint.color = Colors.white;
    paint.shader = LinearGradient(
      colors: [
        Colors.transparent,
        gold.withValues(alpha: .08),
        gold.withValues(alpha: .42),
      ],
    ).createShader(glow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glow, Radius.circular(size.height * .38)),
      paint,
    );
    final coreWidth = math.min(3.6, length);
    final core = Rect.fromLTWH(
      head - coreWidth,
      centerY - size.height * .2,
      coreWidth,
      size.height * .4,
    );
    paint.shader = LinearGradient(
      colors: [gold.withValues(alpha: .16), gold.withValues(alpha: .95)],
    ).createShader(core);
    canvas.drawRRect(
      RRect.fromRectAndRadius(core, Radius.circular(size.height * .2)),
      paint,
    );
  }

  double _headX(double width, double length) {
    final elapsed = frame.elapsed ?? 0;
    const entryStart =
        QuotaRechargeTiming.entry - QuotaRechargeTiming.propulsionEntry;
    if (elapsed < entryStart) return -length * .08;
    if (elapsed < QuotaRechargeTiming.entry) {
      final eased = quotaSmooth(
        (elapsed - entryStart) / QuotaRechargeTiming.propulsionEntry,
      );
      return -length * .08 +
          (width * frame.fromPercentage / 100 + length * .08) * eased;
    }
    if (elapsed <= QuotaRechargeTiming.pushEnd) {
      return width * frame.percentage / 100;
    }
    return width +
        length *
            quotaSmooth(
              (elapsed - QuotaRechargeTiming.pushEnd) /
                  QuotaRechargeTiming.propulsionExit,
            );
  }

  void _paintOrbit(Canvas canvas, Size size, double elapsed) {
    final track = QuotaTrack(size: size);
    var queueIndex = 0;
    for (
      var colorIndex = 0;
      colorIndex < quotaProgressPalette.length;
      colorIndex++
    ) {
      if (colorIndex == selectedIndex) continue;
      final arriveAt =
          queueIndex * QuotaRechargeTiming.entrySlot +
          QuotaRechargeTiming.travel;
      final exitAt = QuotaRechargeTiming.exitAt(queueIndex);
      if (elapsed >= arriveAt && elapsed < exitAt) {
        final phase = track.phaseAt(colorIndex, queueIndex, elapsed);
        final path = Path();
        for (var sample = 0; sample <= 14; sample++) {
          final offset = (14 - sample) / 14 / 8;
          final point = track.point(phase - offset).position;
          if (sample == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        final color = quotaProgressPalette[colorIndex];
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2
          ..color = color.withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawPath(path, paint);
        paint
          ..color = color
          ..maskFilter = null;
        canvas.drawPath(path, paint);
      }
      queueIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant _QuotaProgressPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.overrideColor != overrideColor;
}
