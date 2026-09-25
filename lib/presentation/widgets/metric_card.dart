import 'package:flutter/material.dart';

import 'glass_card.dart';

const quotaMonoFont = '.SF NS Mono';
const quotaMonoFallback = ['SF Mono', 'Menlo', 'Consolas', 'monospace'];

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.secondary,
    this.height = 47,
  });

  static const width = 131.0;
  static const titleStyle = TextStyle(
    fontFamily: quotaMonoFont,
    fontFamilyFallback: quotaMonoFallback,
    fontSize: 9,
    height: 11 / 9,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );

  final String title;
  final String value;
  final Color secondary;
  final double height;

  /// Both cards get a second title line when either
  /// localized label is wider than its 123-point title area.
  static double heightForTitles(Iterable<String> titles) {
    for (final title in titles) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: titleStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final needsTwoLines = painter.width.ceil() > width - 8;
      painter.dispose();
      if (needsTwoLines) return 59;
    }
    return 47;
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return GlassCard(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 5),
      child: Column(
        children: [
          SizedBox(
            width: width - 8,
            height: height > 47 ? 22 : 11,
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
              style: titleStyle.copyWith(color: secondary),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: quotaMonoFont,
              fontFamilyFallback: quotaMonoFallback,
              fontSize: 13,
              height: 16 / 13,
              color: light ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
