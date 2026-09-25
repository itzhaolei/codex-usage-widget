import 'package:flutter/material.dart';

/// Shared vector artwork for the two hardware symbols absent from Cupertino.
///
/// [size] is a font point size. At 10 points, the natural canvases are 14 × 10
/// for `internaldrive` and 13 × 10 for `memorychip`, including optical padding.
/// A parent with a fixed icon slot should use an [OverflowBox] to retain these
/// natural bounds instead of compressing the artwork to a square.
class QuotaHardwareSymbol extends StatelessWidget {
  const QuotaHardwareSymbol({
    super.key,
    required this.name,
    required this.size,
    required this.color,
  }) : assert(name == 'internaldrive' || name == 'memorychip'),
       assert(size > 0);

  final String name;
  final double size;
  final Color color;

  static const referencePointSize = 10.0;
  static const internalDriveViewBox = Rect.fromLTWH(0, 0, 14, 10);
  static const memoryChipViewBox = Rect.fromLTWH(0, 0, 13, 10);

  static bool supports(String name) =>
      name == 'internaldrive' || name == 'memorychip';

  static Rect viewBoxFor(String name) {
    assert(supports(name));
    return name == 'internaldrive' ? internalDriveViewBox : memoryChipViewBox;
  }

  static Size naturalSizeFor(String name, {double size = referencePointSize}) =>
      viewBoxFor(name).size * (size / referencePointSize);

  @override
  Widget build(BuildContext context) {
    final bounds = naturalSizeFor(name, size: size);
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: CustomPaint(
        painter: _HardwareSymbolPainter(name: name, color: color),
      ),
    );
  }
}

class _HardwareSymbolPainter extends CustomPainter {
  const _HardwareSymbolPainter({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final viewBox = QuotaHardwareSymbol.viewBoxFor(name);
    final factor = (size.width / viewBox.width).clamp(
      0.0,
      size.height / viewBox.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - viewBox.width * factor) / 2,
      (size.height - viewBox.height * factor) / 2,
    );
    canvas.scale(factor);
    if (name == 'internaldrive') {
      _paintDrive(canvas);
    } else {
      _paintMemory(canvas);
    }
    canvas.restore();
  }

  Paint _stroke(double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _paintDrive(Canvas canvas) {
    final outline = Path()
      ..moveTo(4.19, 1.44)
      ..lineTo(8.90, 1.44)
      ..cubicTo(9.38, 1.44, 9.60, 1.67, 9.80, 2.15)
      ..lineTo(11.43, 6.43)
      ..cubicTo(11.64, 6.96, 11.66, 7.25, 11.66, 7.61)
      ..cubicTo(11.66, 8.49, 11.12, 8.93, 10.30, 8.93)
      ..lineTo(3.06, 8.93)
      ..cubicTo(2.13, 8.93, 1.65, 8.53, 1.65, 7.67)
      ..cubicTo(1.65, 7.24, 1.68, 6.99, 1.87, 6.46)
      ..lineTo(3.44, 2.12)
      ..cubicTo(3.60, 1.69, 3.80, 1.44, 4.19, 1.44)
      ..close();
    canvas.drawPath(outline, _stroke(.80));
    canvas.drawLine(
      const Offset(2.37, 5.33),
      const Offset(10.99, 5.33),
      _stroke(.78),
    );
    final slots = Path();
    for (var index = 0; index < 5; index++) {
      final x = 5.66 + index;
      slots
        ..moveTo(x, 6.65)
        ..lineTo(x, 7.61);
    }
    canvas.drawPath(slots, _stroke(.64));
  }

  void _paintMemory(Canvas canvas) {
    final pins = Path();
    for (var index = 0; index < 5; index++) {
      final x = 3.15 + index * 1.45;
      pins
        ..moveTo(x, 1.01)
        ..lineTo(x, 2.21)
        ..moveTo(x, 7.90)
        ..lineTo(x, 8.86);
    }
    canvas.drawPath(pins, _stroke(.76));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(1.75, 2.17, 10.54, 7.91),
        const Radius.circular(.67),
      ),
      _stroke(.86),
    );
  }

  @override
  bool shouldRepaint(covariant _HardwareSymbolPainter oldDelegate) =>
      name != oldDelegate.name || color != oldDelegate.color;
}
