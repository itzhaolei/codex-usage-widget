import 'package:flutter/material.dart';

import 'quota_symbol.dart';

class QuotaHeader extends StatelessWidget {
  const QuotaHeader({
    super.key,
    required this.title,
    required this.plan,
    required this.light,
    required this.pinned,
    required this.onTheme,
    required this.onPin,
    required this.onClose,
    this.themeTooltip,
    this.pinTooltip,
    this.closeTooltip,
  });

  final String title;
  final String plan;
  final bool light;
  final bool pinned;
  final VoidCallback onTheme;
  final VoidCallback onPin;
  final VoidCallback onClose;
  final String? themeTooltip;
  final String? pinTooltip;
  final String? closeTooltip;

  @override
  Widget build(BuildContext context) {
    final primary = light ? Colors.black : Colors.white;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                      color: primary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (plan.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  _PlanBadge(plan: plan),
                ],
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 111,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: .16)),
            ),
            child: Row(
              children: [
                _button(
                  onTheme,
                  symbol: light ? 'moon.fill' : 'sun.max.fill',
                  color: primary.withValues(alpha: .76),
                  tooltip: themeTooltip,
                ),
                _divider(primary),
                _button(
                  onPin,
                  symbol: pinned ? 'pin.fill' : 'pin.slash.fill',
                  color: pinned
                      ? const Color(0xff34c759)
                      : primary.withValues(alpha: .76),
                  tooltip: pinTooltip,
                ),
                _divider(primary),
                _button(
                  onClose,
                  symbol: 'xmark',
                  color: primary.withValues(alpha: .76),
                  tooltip: closeTooltip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color primary) =>
      Container(width: 1, height: 16, color: primary.withValues(alpha: .16));

  Widget _button(
    VoidCallback action, {
    required String symbol,
    required Color color,
    String? tooltip,
  }) {
    final button = SizedBox(
      width: 36,
      height: 28,
      child: IconButton(
        onPressed: action,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 28),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
        ),
        iconSize: 12,
        color: color,
        icon: QuotaSymbol(name: symbol, size: 12, color: color, semibold: true),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final String plan;

  @override
  Widget build(BuildContext context) {
    final normalized = plan.toLowerCase();
    final List<Color>? gradient;
    final List<double>? stops;
    if (normalized == 'business 5x') {
      gradient = const [
        Color.fromRGBO(41, 117, 245, 1),
        Color.fromRGBO(51, 173, 255, 1),
        Color.fromRGBO(135, 84, 242, 1),
        Color.fromRGBO(255, 110, 51, 1),
      ];
      stops = const [0, .28, .58, 1];
    } else if (normalized == 'business 20x') {
      gradient = const [
        Color.fromRGBO(41, 117, 245, 1),
        Color.fromRGBO(64, 148, 255, 1),
        Color.fromRGBO(138, 79, 245, 1),
        Color.fromRGBO(214, 64, 219, 1),
      ];
      stops = const [0, .25, .62, 1];
    } else {
      gradient = null;
      stops = null;
    }
    final Color color;
    if (normalized == 'plus') {
      color = const Color(0xff00b814);
    } else if (normalized.startsWith('pro')) {
      color = const Color(0xffff9500);
    } else if (normalized == 'free') {
      color = const Color(0xff8e8e93);
    } else {
      color = const Color(0xff007aff);
    }
    return IntrinsicWidth(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gradient == null ? color : null,
                gradient: gradient == null
                    ? null
                    : LinearGradient(colors: gradient, stops: stops),
              ),
              child: Text(
                plan,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: .22),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: .08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
