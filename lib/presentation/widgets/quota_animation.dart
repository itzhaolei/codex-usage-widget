import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/quota_recharge_event.dart';

const quotaProgressSize = Size(231, 35);
const quotaPaletteHeight = 15.0;
const quotaPaletteGap = 4.0;
const quotaProgressPalette = <Color>[
  Color.fromRGBO(0, 194, 41, 1),
  Color.fromRGBO(0, 163, 150, 1),
  Color.fromRGBO(31, 133, 255, 1),
  Color.fromRGBO(158, 87, 255, 1),
  Color.fromRGBO(199, 163, 89, 1),
];

/// Timings shared by the bar, percentage, orbit and returning palette particles.
abstract final class QuotaRechargeTiming {
  static const entrySlot = .25;
  static const entry = entrySlot * 4;
  static const push = 2.0;
  static const propulsionEntry = .55;
  static const propulsionExit = .5;
  static const duration = entry + push + propulsionExit;
  static const pushEnd = entry + push;
  static const travel = .125;
  static const returnDelay = .06;
  static const returnApproach = .2;
  static const returnDuration = .25;
  static const paletteEnd =
      pushEnd + returnApproach + 3 * returnDelay + returnDuration + .05;

  static double pushedFraction(double elapsed) =>
      quotaSmooth((elapsed - entry) / push);

  static double exitAt(int queueIndex) =>
      pushEnd + returnApproach + queueIndex * returnDelay;
}

double quotaUnit(double value) => value.clamp(0.0, 1.0);
double quotaSmooth(double value) {
  final unit = quotaUnit(value);
  return unit * unit * (3 - 2 * unit);
}

double quotaRandom(int seed) {
  final value = math.sin(seed * 12.9898) * 43758.5453;
  return value - value.floorToDouble();
}

double quotaPhase(double value) => value - value.floorToDouble();

@immutable
class QuotaAnimationFrame {
  const QuotaAnimationFrame({
    required this.percentage,
    required this.sparkleTime,
    this.elapsed,
    this.fromPercentage = 0,
  });

  final double percentage;
  final double sparkleTime;
  final double? elapsed;
  final double fromPercentage;

  bool get propulsionActive =>
      elapsed != null && elapsed! < QuotaRechargeTiming.duration;
  double get progress =>
      elapsed == null ? 1 : quotaUnit(elapsed! / QuotaRechargeTiming.duration);

  static double interpolatedPercentage(
    QuotaRechargeEvent event,
    double elapsed,
  ) =>
      event.fromPercentage +
      (event.toPercentage - event.fromPercentage) *
          QuotaRechargeTiming.pushedFraction(elapsed);
}

/// Shares one clock across all recharge effects. Idle sparkles repaint at the
/// steady 15 Hz; the short recharge uses display frames. Hidden windows stop
/// both clocks, including paint-only animation work.
class QuotaAnimationBuilder extends StatefulWidget {
  const QuotaAnimationBuilder({
    super.key,
    required this.percent,
    required this.builder,
    this.rechargeEvent,
    this.animationsEnabled = true,
  });

  final int? percent;
  final QuotaRechargeEvent? rechargeEvent;
  final bool animationsEnabled;
  final Widget Function(BuildContext context, QuotaAnimationFrame frame)
  builder;

  @override
  State<QuotaAnimationBuilder> createState() => _QuotaAnimationBuilderState();
}

class _QuotaAnimationBuilderState extends State<QuotaAnimationBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recharge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3680),
  )..addListener(_onRechargeTick);
  Timer? _sparkles;
  QuotaRechargeEvent? _event;
  Object? _seenEvent;
  bool _canAnimate = false;
  double _time = 0;
  double? _elapsed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(QuotaAnimationBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  void _configure() {
    _canAnimate =
        widget.animationsEnabled && TickerMode.valuesOf(context).enabled;
    _sampleTime();
    final next = widget.rechargeEvent;
    if (!_canAnimate) {
      _sparkles?.cancel();
      _sparkles = null;
      _recharge.stop();
      _elapsed = null;
      _event = null;
      _seenEvent = next?.id;
      return;
    }
    if (next == null && _event != null) {
      _event = null;
      _elapsed = null;
      _recharge.stop();
    }
    if (next != null && next.id != _seenEvent) {
      _seenEvent = next.id;
      _event = next;
      _elapsed = 0;
      _sparkles?.cancel();
      _sparkles = null;
      _recharge.forward(from: 0);
    } else if (!_recharge.isAnimating) {
      _startSparkles();
    }
  }

  void _sampleTime() {
    // Swift's timeIntervalSinceReferenceDate starts on 2001-01-01 UTC.
    _time = DateTime.now().microsecondsSinceEpoch / 1000000 - 978307200;
  }

  void _startSparkles() {
    _sparkles ??= Timer.periodic(const Duration(microseconds: 66667), (_) {
      if (!mounted || !_canAnimate) return;
      setState(_sampleTime);
    });
  }

  void _onRechargeTick() {
    if (!mounted || !_canAnimate) return;
    setState(() {
      _sampleTime();
      _elapsed = _recharge.value * QuotaRechargeTiming.paletteEnd;
      if (_recharge.value >= 1) {
        _elapsed = null;
        _event = null;
        _startSparkles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final elapsed = _elapsed;
    final percentage = event != null && elapsed != null
        ? QuotaAnimationFrame.interpolatedPercentage(event, elapsed)
        : (widget.percent ?? 0).toDouble();
    return widget.builder(
      context,
      QuotaAnimationFrame(
        percentage: percentage.clamp(0, 100),
        sparkleTime: (_time * 15).floorToDouble() / 15,
        elapsed: elapsed,
        fromPercentage: (event?.fromPercentage ?? 0).toDouble(),
      ),
    );
  }

  @override
  void dispose() {
    _sparkles?.cancel();
    _recharge.dispose();
    super.dispose();
  }
}

/// Exact rectangular perimeter used by palette assembly and orbit.
class QuotaTrack {
  const QuotaTrack({this.size = quotaProgressSize});
  final Size size;
  double get width => size.width - 2;
  double get height => size.height - 2;
  double get perimeter => 2 * (width + height);

  double homePhase(int colorIndex) {
    final x = (7.5 + colorIndex * 19).clamp(1.0, size.width - 1);
    return (width + height + (size.width - 1 - x)) / perimeter;
  }

  double orbitPhase(int colorIndex, int queueIndex, double elapsed) {
    final departAt = queueIndex * QuotaRechargeTiming.entrySlot;
    final arriveAt = departAt + QuotaRechargeTiming.travel;
    final positionedAt = departAt + QuotaRechargeTiming.entrySlot;
    final prepared = .125 + queueIndex * .25;
    if (elapsed >= QuotaRechargeTiming.entry) {
      return prepared + (elapsed - QuotaRechargeTiming.entry) * 1.45;
    }
    if (elapsed >= positionedAt) return prepared;
    final start = homePhase(colorIndex);
    var delta = quotaPhase(prepared) - quotaPhase(start);
    if (delta > 0) delta -= 1;
    return start +
        delta * quotaSmooth((elapsed - arriveAt) / (positionedAt - arriveAt));
  }

  double phaseAt(int colorIndex, int queueIndex, double elapsed) {
    if (elapsed < QuotaRechargeTiming.pushEnd) {
      return orbitPhase(colorIndex, queueIndex, elapsed);
    }
    final start = quotaPhase(
      orbitPhase(colorIndex, queueIndex, QuotaRechargeTiming.pushEnd),
    );
    var delta = homePhase(colorIndex) - start;
    if (delta > .5) delta -= 1;
    if (delta < -.5) delta += 1;
    return start +
        delta *
            quotaSmooth(
              (elapsed - QuotaRechargeTiming.pushEnd) /
                  QuotaRechargeTiming.returnApproach,
            );
  }

  ({Offset position, double angle}) point(double phase) {
    final distance = quotaPhase(phase) * perimeter;
    if (distance <= width) {
      return (position: Offset(1 + distance, 1), angle: 0);
    }
    if (distance <= width + height) {
      return (
        position: Offset(size.width - 1, 1 + distance - width),
        angle: math.pi / 2,
      );
    }
    if (distance <= width * 2 + height) {
      return (
        position: Offset(
          size.width - 1 - (distance - width - height),
          size.height - 1,
        ),
        angle: math.pi,
      );
    }
    return (
      position: Offset(1, size.height - 1 - (distance - width * 2 - height)),
      angle: math.pi * 1.5,
    );
  }
}
