import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/presentation/state/quota_recharge_event.dart';
import 'package:quota_bubble/presentation/widgets/quota_animation.dart';
import 'package:quota_bubble/presentation/widgets/quota_progress_bar.dart';
import 'package:quota_bubble/presentation/widgets/quota_progress_group.dart';

void main() {
  const recharge = QuotaRechargeEvent(
    id: 1,
    fromPercentage: 12,
    toPercentage: 100,
  );

  test(
    'recharge holds entry, eases for two seconds, then holds full quota',
    () {
      expect(QuotaAnimationFrame.interpolatedPercentage(recharge, 0), 12);
      expect(QuotaAnimationFrame.interpolatedPercentage(recharge, 1), 12);
      expect(QuotaAnimationFrame.interpolatedPercentage(recharge, 2), 56);
      expect(QuotaAnimationFrame.interpolatedPercentage(recharge, 3), 100);
      expect(QuotaAnimationFrame.interpolatedPercentage(recharge, 3.5), 100);
      expect(QuotaRechargeTiming.exitAt(0), 3.2);
      expect(QuotaRechargeTiming.exitAt(3), closeTo(3.38, .0001));
    },
  );

  testWidgets('palette size and selection match native controls', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: QuotaProgressGroup(
            percent: 65,
            selectedColorIndex: 0,
            primary: Colors.white,
            animationsEnabled: false,
            onSelect: (value) => selected = value,
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(QuotaProgressGroup)),
      const Size(281, 54),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('quota-palette-3'))),
      const Size(15, 15),
    );
    await tester.tap(find.byKey(const ValueKey('quota-palette-3')));
    expect(selected, 3);
    expect(find.text('65%'), findsOneWidget);
  });

  testWidgets(
    'number shares recharge timing and palette is locked until return',
    (tester) async {
      int selections = 0;
      Widget group(QuotaRechargeEvent? event) => MaterialApp(
        home: Center(
          child: QuotaProgressGroup(
            percent: 100,
            selectedColorIndex: 0,
            primary: Colors.white,
            rechargeEvent: event,
            onSelect: (_) => selections++,
          ),
        ),
      );
      await tester.pumpWidget(group(null));
      await tester.pumpWidget(group(recharge));
      await tester.pump();
      expect(find.text('12%'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('12%'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('56%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quota-palette-2')));
      expect(selections, 0);
      await tester.pump(const Duration(milliseconds: 1800));
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quota-palette-2')));
      expect(selections, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('hidden clock stops and does not replay a background recharge', (
    tester,
  ) async {
    var builds = 0;
    QuotaAnimationFrame? last;
    Widget scene(bool visible) => MaterialApp(
      home: TickerMode(
        enabled: visible,
        child: QuotaAnimationBuilder(
          percent: 100,
          rechargeEvent: recharge,
          builder: (_, frame) {
            builds++;
            last = frame;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(scene(false));
    final hiddenBuilds = builds;
    await tester.pump(const Duration(seconds: 2));
    expect(builds, hiddenBuilds);
    expect(last!.elapsed, isNull);
    await tester.pumpWidget(scene(true));
    expect(last!.elapsed, isNull);
    expect(last!.percentage, 100);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty quota retains staggered dots without a solid track', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: const QuotaProgressBar(
              percent: 0,
              frame: QuotaAnimationFrame(percentage: 0, sparkleTime: 0),
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 4);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(double x, double y) => data.getUint8(
        ((y * 4).floor() * image.width + (x * 4).floor()) * 4 + 3,
      );
      expect(alpha(1.5, 1.5), greaterThan(200));
      expect(alpha(1.5, 4.5), 0);
      expect(alpha(3, 4.5), greaterThan(200));
      expect(alpha(12, 12), 0);
      image.dispose();
    });
  });
}
