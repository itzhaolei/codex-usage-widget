import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/core/models.dart';
import 'package:quota_bubble/presentation/quota_window.dart';
import 'package:quota_bubble/presentation/state/quota_controller.dart';
import 'package:quota_bubble/presentation/widgets/header.dart';
import 'package:quota_bubble/presentation/widgets/metric_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Ahem makes every glyph one em wide. Load the host desktop fonts so
    // these compact-layout checks exercise the same metrics as the app.
    final fonts = Platform.isMacOS
        ? {
            quotaMonoFont: '/System/Library/Fonts/SFNSMono.ttf',
            'CupertinoSystemText': '/System/Library/Fonts/SFNS.ttf',
          }
        : {
            quotaMonoFont: r'C:\Windows\Fonts\consola.ttf',
            'Segoe UI': r'C:\Windows\Fonts\segoeui.ttf',
          };
    for (final entry in fonts.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
  });

  testWidgets(
    'desktop layout fits all languages with regular, undecorated body text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final language in supportedLanguages) {
        for (final light in [false, true]) {
          final controller = QuotaController()
            ..language = language
            ..light = light
            ..windowVisible = false
            ..auth = const AuthInfo(email: 'sample@example.com')
            ..snapshot = QuotaSnapshot(
              planType: 'business20x',
              balanceUsd: '235',
              fiveHour: UsageWindow(
                usedPercentage: 32,
                resetsAt: DateTime(2099, 9, 26, 17, 42, 12),
              ),
              sevenDay: UsageWindow(
                usedPercentage: 63,
                resetsAt: DateTime(2099, 9, 30, 15, 42, 12),
              ),
              resetCredits: ResetCredits(
                availableCount: 2,
                expiresAt: [DateTime(2099, 10, 1), DateTime(2099, 10, 8)],
              ),
            );
          final height = QuotaWindow.heightFor(controller);
          tester.view.physicalSize = Size(330, height);
          await tester.pumpWidget(
            MaterialApp(
              home: QuotaWindow(
                controller: controller,
                onClose: () {},
                version: '3.1.29',
              ),
            ),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: '$language light=$light must fit a 330-point window',
          );
          expect(tester.getSize(find.byType(QuotaHeader)), const Size(306, 28));
          for (final card in find.byType(MetricCard).evaluate()) {
            final widget = card.widget as MetricCard;
            expect(
              tester.getSize(find.byWidget(widget)),
              Size(131, QuotaWindow.metricHeight(controller.copy, language)),
            );
          }
          final identity = tester.widget<Text>(find.text('sample@example.com'));
          expect(identity.style!.fontWeight, FontWeight.w400);
          expect(identity.style!.decoration, TextDecoration.none);
          final date = tester.getRect(find.text('09-30 15:42:12'));
          final week = tester.getRect(find.text(controller.copy.week));
          expect((date.center.dy - week.center.dy).abs(), lessThan(1));

          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        }
      }
    },
  );
}
