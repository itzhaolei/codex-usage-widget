import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/quota_recharge_event.dart';
import 'quota_animation.dart';
import 'quota_progress_bar.dart';

/// Quota row plus the optional palette, synchronized by a single clock.
/// The caller supplies the title/date row above this 281 × 54 group.
class QuotaProgressGroup extends StatelessWidget {
  const QuotaProgressGroup({
    super.key,
    required this.percent,
    required this.selectedColorIndex,
    required this.primary,
    this.onSelect,
    this.rechargeEvent,
    this.animationsEnabled = true,
    this.showPalette = true,
  });

  final int? percent;
  final int selectedColorIndex;
  final Color primary;
  final ValueChanged<int>? onSelect;
  final QuotaRechargeEvent? rechargeEvent;
  final bool animationsEnabled;
  final bool showPalette;

  @override
  Widget build(BuildContext context) => QuotaAnimationBuilder(
    percent: percent,
    rechargeEvent: rechargeEvent,
    animationsEnabled: animationsEnabled,
    builder: (context, frame) => RepaintBoundary(
      child: SizedBox(
        width: 281,
        height: showPalette ? 54 : 35,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                QuotaProgressBar(
                  percent: percent,
                  selectedColorIndex: selectedColorIndex,
                  frame: frame,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 38,
                  child: Text(
                    percent == null ? '—' : '${frame.percentage.round()}%',
                    key: const ValueKey('quota-percentage'),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: '.SF NS Mono',
                      fontFamilyFallback: [
                        'SF Mono',
                        'Menlo',
                        'Consolas',
                        'monospace',
                      ],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            if (showPalette) ...[
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(231, 54),
                    painter: _QuotaPalettePainter(
                      selectedIndex: selectedColorIndex.clamp(0, 4),
                      primary: primary,
                      elapsed: frame.elapsed,
                    ),
                  ),
                ),
              ),
              for (var index = 0; index < quotaProgressPalette.length; index++)
                Positioned(
                  top: 39,
                  left: index * 19,
                  width: 15,
                  height: 15,
                  child: Semantics(
                    button: true,
                    selected: selectedColorIndex == index,
                    label: ['Green', 'Teal', 'Blue', 'Purple', 'Gold'][index],
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: ValueKey('quota-palette-$index'),
                        behavior: HitTestBehavior.opaque,
                        onTap: frame.elapsed == null && onSelect != null
                            ? () => onSelect!(index)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _QuotaPalettePainter extends CustomPainter {
  const _QuotaPalettePainter({
    required this.selectedIndex,
    required this.primary,
    required this.elapsed,
  });

  final int selectedIndex;
  final Color primary;
  final double? elapsed;
  static const _paletteOrigin = 39.0;
  static const _track = QuotaTrack();

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = this.elapsed;
    for (var index = 0; index < quotaProgressPalette.length; index++) {
      if (elapsed == null || index == selectedIndex) {
        _paintSquare(canvas, index, selected: index == selectedIndex);
      }
    }
    if (elapsed == null) return;
    var queueIndex = 0;
    for (
      var colorIndex = 0;
      colorIndex < quotaProgressPalette.length;
      colorIndex++
    ) {
      if (colorIndex == selectedIndex) continue;
      final departAt = queueIndex * QuotaRechargeTiming.entrySlot;
      final arriveAt = departAt + QuotaRechargeTiming.travel;
      final exitAt = QuotaRechargeTiming.exitAt(queueIndex);
      if (elapsed < departAt) {
        _paintSquare(canvas, colorIndex, animated: true);
      } else if (elapsed < arriveAt) {
        _paintAssembly(
          canvas,
          colorIndex,
          quotaSmooth((elapsed - departAt) / QuotaRechargeTiming.travel),
          returning: false,
        );
      } else if (elapsed >= exitAt) {
        _paintAssembly(
          canvas,
          colorIndex,
          quotaSmooth((elapsed - exitAt) / QuotaRechargeTiming.returnDuration),
          returning: true,
        );
      }
      queueIndex++;
    }
  }

  void _paintSquare(
    Canvas canvas,
    int index, {
    bool selected = false,
    bool animated = false,
  }) {
    final color = quotaProgressPalette[index];
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(7.5 + index * 19, _paletteOrigin + 7.5),
        width: 12,
        height: 12,
      ),
      const Radius.circular(3),
    );
    if (selected || animated) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: selected ? .55 : .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawRRect(rect, Paint()..color = color);
    if (!animated) {
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.5 : .6
          ..color = selected
              ? primary.withValues(alpha: .95)
              : Colors.white.withValues(alpha: .18),
      );
    }
  }

  void _paintAssembly(
    Canvas canvas,
    int colorIndex,
    double progress, {
    required bool returning,
  }) {
    final home = Offset(7.5 + colorIndex * 19, _paletteOrigin + 7.5);
    final entry = _track.homePhase(colorIndex);
    final color = quotaProgressPalette[colorIndex];
    for (var index = 0; index < 36; index++) {
      final row = index ~/ 6;
      final column = index % 6;
      final homePoint = home + Offset(-5 + column * 2.0, -5 + row * 2.0);
      final lineOffset = (1 - index / 35) / 8;
      final lane = row.isEven ? -.38 : .38;
      final snakeIndex = row.isEven ? row * 6 + column : row * 6 + (5 - column);
      final rank = snakeIndex / 35;
      final delay = returning ? (1 - rank) * .22 : rank * .22;
      final delayed = quotaSmooth(
        (progress - delay) / math.max(.001, 1 - delay),
      );
      final journey = returning ? 1 - delayed : delayed;
      final position = _particlePosition(
        homePoint,
        entry,
        lineOffset,
        lane,
        journey,
        index,
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position,
          width: 1.85 + (1.35 - 1.85) * journey,
          height: 1.65,
        ),
        const Radius.circular(.45),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: .42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  Offset _particlePosition(
    Offset home,
    double entry,
    double lineOffset,
    double lane,
    double progress,
    int index,
  ) {
    const ingressEnd = .68;
    if (progress < ingressEnd) {
      final eased = quotaSmooth(progress / ingressEnd);
      final base = Offset.lerp(home, _track.point(entry).position, eased)!;
      final arc = math.sin(eased * math.pi) * (1.2 + (index * 7 % 4) * .24);
      return base - Offset(0, arc);
    }
    final eased = quotaSmooth((progress - ingressEnd) / (1 - ingressEnd));
    final state = _track.point(entry - lineOffset * eased);
    return state.position +
        Offset(-math.sin(state.angle) * lane, math.cos(state.angle) * lane);
  }

  @override
  bool shouldRepaint(covariant _QuotaPalettePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.primary != primary ||
      oldDelegate.elapsed != elapsed;
}
