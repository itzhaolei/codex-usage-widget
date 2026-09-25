import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../core/models.dart';
import '../l10n/app_localizations.dart';
import 'state/quota_controller.dart';
import 'state/quota_recharge_event.dart';
import 'widgets/header.dart';
import 'widgets/metric_card.dart';
import 'widgets/quota_progress_group.dart';
import 'widgets/quota_symbol.dart';

class QuotaWindow extends StatelessWidget {
  const QuotaWindow({
    super.key,
    required this.controller,
    required this.onClose,
    required this.version,
    this.onUpdate,
    this.hasUpdate = false,
  });

  final QuotaController controller;
  final VoidCallback onClose;
  final String version;
  final VoidCallback? onUpdate;
  final bool hasUpdate;

  static const palette = [
    Color(0xff00c229),
    Color(0xff00a396),
    Color(0xff1f85ff),
    Color(0xff9e57ff),
    Color(0xffc7a359),
  ];

  static double metricHeight(AppCopy copy, String language) =>
      MetricCard.heightForTitles([
        '${copy.balance}（${pointsUnit(language)}）',
        '${copy.availableReset}（${copy.times}）',
      ]);

  static double heightFor(QuotaController controller) {
    final count = controller.snapshot?.resetCredits?.availableCount ?? 0;
    return 287 +
        (controller.fiveHourWindow == null ? 0 : 65) +
        (count > 0 ? 18 + count * 18 : 0) +
        metricHeight(controller.copy, controller.language) -
        47;
  }

  @override
  Widget build(BuildContext context) {
    final light = controller.light;
    final primary = light ? Colors.black : Colors.white;
    final secondary = primary.withValues(alpha: .68);
    final copy = controller.copy;
    final resetRows = _resetRows(controller.snapshot?.resetCredits);
    final cardHeight = metricHeight(copy, controller.language);
    final nativeFont = Platform.isMacOS ? 'CupertinoSystemText' : 'Segoe UI';
    final background = Platform.isMacOS
        ? Colors.transparent
        : light
        ? const Color(0xebf3f7f8)
        : const Color(0xeb111d18);

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: light ? Brightness.light : Brightness.dark,
        fontFamily: nativeFont,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: nativeFont,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: primary,
            decoration: TextDecoration.none,
          ),
          child: SizedBox(
            width: 330,
            height: heightFor(controller),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(color: background),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QuotaHeader(
                            title: copy.title,
                            plan: controller.planText,
                            light: light,
                            pinned: controller.pinned,
                            onTheme: () => controller.setLight(!light),
                            onPin: () =>
                                controller.setPinned(!controller.pinned),
                            onClose: onClose,
                            themeTooltip: light
                                ? copy.switchToDark
                                : copy.switchToLight,
                            pinTooltip: controller.pinned
                                ? copy.unpin
                                : copy.pin,
                            closeTooltip: copy.close,
                          ),
                          if (controller.fiveHourWindow != null) ...[
                            const SizedBox(height: 11),
                            _QuotaSection(
                              title: '5h',
                              window: controller.fiveHourWindow,
                              primary: primary,
                              copy: copy,
                              language: controller.language,
                              selectedColorIndex: controller.progressColorIndex,
                              animationsEnabled: controller.windowVisible,
                            ),
                          ],
                          const SizedBox(height: 11),
                          _QuotaSection(
                            title: copy.week,
                            window: controller.weeklyWindow,
                            primary: primary,
                            copy: copy,
                            language: controller.language,
                            selectedColorIndex: controller.progressColorIndex,
                            onSelect: controller.setProgressColor,
                            rechargeEvent: controller.rechargeEvent,
                            animationsEnabled: controller.windowVisible,
                            weekday: true,
                          ),
                          if (resetRows.isNotEmpty) ...[
                            const SizedBox(height: 13),
                            ...resetRows.map(
                              (row) => _ResetLine(
                                row: row,
                                secondary: secondary,
                                language: controller.language,
                              ),
                            ),
                          ],
                          SizedBox(height: resetRows.isEmpty ? 15 : 10),
                          SizedBox(
                            width: 272,
                            height: cardHeight,
                            child: Row(
                              children: [
                                MetricCard(
                                  title:
                                      '${copy.balance}（${pointsUnit(controller.language)}）',
                                  value: formatBalance(
                                    controller.snapshot?.balanceUsd,
                                  ),
                                  secondary: secondary,
                                  height: cardHeight,
                                ),
                                const SizedBox(width: 10),
                                MetricCard(
                                  title:
                                      '${copy.availableReset}（${copy.times}）',
                                  value:
                                      '${controller.snapshot?.resetCredits?.availableCount ?? '—'}',
                                  secondary: secondary,
                                  height: cardHeight,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          _IdentityLine(
                            symbol: 'person.circle.fill',
                            text: controller.auth?.email ?? '—',
                            color: secondary,
                          ),
                          const SizedBox(height: 1),
                          _IdentityLine(
                            symbol: 'calendar.badge.clock',
                            text: _displayDate(
                              controller.auth?.subscriptionExpiresAt,
                              controller.language,
                            ),
                            color: secondary,
                          ),
                          const SizedBox(height: 1),
                          _IdentityLine(
                            symbol: 'internaldrive',
                            text: _capacity(
                              controller.storage,
                              memory: false,
                              copy: copy,
                            ),
                            color: _capacityColor(
                              controller.storage,
                              false,
                              secondary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          _IdentityLine(
                            symbol: 'memorychip',
                            text: _capacity(
                              controller.memory,
                              memory: true,
                              copy: copy,
                            ),
                            color: _capacityColor(
                              controller.memory,
                              true,
                              secondary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 4.5,
                      width: 58,
                      height: 21,
                      child: Semantics(
                        button: onUpdate != null,
                        label: copy.update,
                        child: MouseRegion(
                          cursor: onUpdate == null
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          child: GestureDetector(
                            key: const ValueKey('quota-version-update'),
                            behavior: HitTestBehavior.opaque,
                            onTap: onUpdate,
                            child: Tooltip(
                              message: copy.update,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasUpdate) ...[
                                      Container(
                                        key: const ValueKey('quota-update-dot'),
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xffff3333),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      'v$version',
                                      maxLines: 1,
                                      style: _monoStyle(
                                        size: 9,
                                        color: secondary,
                                        weight: FontWeight.w300,
                                        height: 11 / 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: light ? .56 : .14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ResetRow> _resetRows(ResetCredits? credits) {
    if (credits == null || credits.availableCount <= 0) return const [];
    return List.generate(credits.availableCount, (index) {
      final date = index < credits.expiresAt.length
          ? credits.expiresAt[index]
          : null;
      return ResetRow(
        date: date,
        isExpiringSoon: date == null
            ? null
            : date.difference(DateTime.now()) <= const Duration(days: 3),
      );
    });
  }

  Color _capacityColor(CapacityInfo? value, bool memory, Color secondary) {
    if (value == null) return secondary;
    final warning = memory
        ? value.availableBytes > 11 * 1073741824
        : value.availableBytes < 50000000000;
    return warning ? const Color(0xfff03338) : palette.first;
  }

  String _capacity(
    CapacityInfo? value, {
    required bool memory,
    required AppCopy copy,
  }) {
    final label = memory ? copy.availableMemory : copy.availableStorage;
    final separator = controller.language == 'zh' ? '：' : ': ';
    if (value == null) return '$label$separator—';
    if (memory) {
      final available = (value.availableBytes / 1073741824).toStringAsFixed(1);
      final total = (value.totalBytes / 1073741824).toStringAsFixed(1);
      return '$label$separator${available}G / ${total}G';
    }
    return '$label$separator${(value.availableBytes / 1000000000).toStringAsFixed(1)}G';
  }
}

class _QuotaSection extends StatelessWidget {
  const _QuotaSection({
    required this.title,
    required this.window,
    required this.primary,
    required this.copy,
    required this.language,
    required this.selectedColorIndex,
    this.onSelect,
    this.rechargeEvent,
    this.animationsEnabled = true,
    this.weekday = false,
  });

  final String title;
  final UsageWindow? window;
  final Color primary;
  final AppCopy copy;
  final String language;
  final int selectedColorIndex;
  final ValueChanged<int>? onSelect;
  final QuotaRechargeEvent? rechargeEvent;
  final bool animationsEnabled;
  final bool weekday;

  @override
  Widget build(BuildContext context) {
    final secondary = primary.withValues(alpha: .68);
    final dateColor = primary.withValues(alpha: .52);
    final resetAt = window?.resetsAt;
    final date = resetAt == null
        ? '—'
        : DateFormat('MM-dd HH:mm:ss').format(resetAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
          child: Row(
            children: [
              Text(
                title,
                style: _monoStyle(
                  size: 13,
                  color: primary,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              _separator(secondary, bold: true),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${copy.reset} ${_compactDuration(resetAt, copy)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _monoStyle(size: 10, color: secondary),
                ),
              ),
              const SizedBox(width: 7),
              _separator(dateColor),
              const SizedBox(width: 7),
              Text(date, style: _monoStyle(size: 8, color: dateColor)),
              if (weekday) ...[
                const SizedBox(width: 7),
                _separator(dateColor),
                const SizedBox(width: 7),
                Text(
                  _weekday(resetAt, language),
                  style: _monoStyle(size: 8, color: dateColor),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        QuotaProgressGroup(
          percent: window?.remainingPercentage,
          selectedColorIndex: selectedColorIndex,
          primary: primary,
          onSelect: onSelect,
          rechargeEvent: rechargeEvent,
          animationsEnabled: animationsEnabled,
          showPalette: weekday,
        ),
      ],
    );
  }

  Widget _separator(Color color, {bool bold = false}) => Transform.translate(
    offset: const Offset(0, -1),
    child: Text(
      '|',
      style: _monoStyle(
        size: 8,
        color: color,
        weight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}

class _ResetLine extends StatelessWidget {
  const _ResetLine({
    required this.row,
    required this.secondary,
    required this.language,
  });
  final ResetRow row;
  final Color secondary;
  final String language;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: row.isExpiringSoon == null
                ? secondary
                : row.isExpiringSoon!
                ? const Color(0xffff3b30)
                : const Color(0xff34c759),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _displayDate(row.date, language),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _monoStyle(size: 10, color: secondary),
          ),
        ),
      ],
    ),
  );
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({
    required this.symbol,
    required this.text,
    required this.color,
  });
  final String symbol;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 17,
    child: Row(
      children: [
        SizedBox(
          width: 13,
          child: QuotaSymbol(name: symbol, size: 10, color: color),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _monoStyle(size: 10, color: color),
          ),
        ),
      ],
    ),
  );
}

TextStyle _monoStyle({
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w400,
  double height = 1.15,
}) => TextStyle(
  fontFamily: quotaMonoFont,
  fontFamilyFallback: quotaMonoFallback,
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color,
  decoration: TextDecoration.none,
);

String _compactDuration(DateTime? reset, AppCopy copy) {
  if (reset == null) return '—';
  final seconds = (reset.difference(DateTime.now()).inMilliseconds / 1000)
      .ceil();
  if (seconds <= 0) return copy.alreadyReset;
  final days = seconds ~/ 86400;
  final hours = seconds % 86400 ~/ 3600;
  final minutes = seconds % 3600 ~/ 60;
  final remainder = seconds % 60;
  final parts = <String>[
    if (days > 0) '${days}d',
    if (hours > 0) '${hours}h',
    if (minutes > 0) '${minutes}m',
    if (remainder > 0 || seconds < 60) '${remainder}s',
  ];
  return parts.join(' ');
}

bool _datesInitialized = false;
void _initializeDates() {
  if (_datesInitialized) return;
  initializeDateFormatting();
  _datesInitialized = true;
}

String _weekday(DateTime? date, String language) {
  if (date == null) return '—';
  if (language == 'zh') {
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
  }
  _initializeDates();
  return DateFormat('EEE', language).format(date);
}

String _displayDate(DateTime? date, String language) {
  if (date == null) return '—';
  _initializeDates();
  return DateFormat.yMMMd(language).add_jm().format(date);
}
