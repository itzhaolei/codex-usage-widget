import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/presentation/widgets/quota_hardware_symbols.dart';
import 'package:quota_bubble/presentation/widgets/quota_symbol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('packages/cupertino_icons/CupertinoIcons');
    loader.addFont(
      rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    );
    await loader.load();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets(
    'all symbols draw the same macOS artwork on both platforms at each density',
    (tester) async {
      final boundaryKey = GlobalKey();
      Future<Uint8List> render(TargetPlatform platform, double scale) async {
        debugDefaultTargetPlatformOverride = platform;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(devicePixelRatio: scale),
              child: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                    width: QuotaSymbol.names.length * 48,
                    height: 48,
                    child: Row(
                      children: [
                        for (final name in QuotaSymbol.names)
                          SizedBox(
                            width: 48,
                            child: Center(
                              child: QuotaSymbol(
                                name: name,
                                size: 20,
                                color: Colors.white,
                                semibold: true,
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
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        return tester
            .runAsync(() async {
              final image = await boundary.toImage(pixelRatio: scale);
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List();
              final width = image.width;
              // Every glyph must contain visible ink and a transparent margin. This
              // catches missing bundled fonts, empty painters and clipped glyphs.
              for (var icon = 0; icon < QuotaSymbol.names.length; icon++) {
                var ink = 0;
                var clear = 0;
                final left = (icon * 48 * scale).round();
                final right = ((icon + 1) * 48 * scale).round();
                for (var y = 0; y < image.height; y++) {
                  for (var x = left; x < right; x++) {
                    final alpha = bytes[(y * width + x) * 4 + 3];
                    if (alpha > 128) ink++;
                    if (alpha == 0) clear++;
                  }
                }
                expect(ink, greaterThan(5), reason: QuotaSymbol.names[icon]);
                expect(clear, greaterThan(5), reason: QuotaSymbol.names[icon]);
              }
              image.dispose();
              return bytes;
            })
            .then((bytes) => bytes!);
      }

      for (final scale in [1.0, 1.25, 1.5, 2.0, 3.0]) {
        final mac = await render(TargetPlatform.macOS, scale);
        final windows = await render(TargetPlatform.windows, scale);
        expect(
          listEquals(mac, windows),
          isTrue,
          reason: 'Platform changed icon artwork at ${scale}x',
        );
        expect(find.byType(Image), findsNothing);
      }
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('theme tint and header states use bundled Cupertino vectors', (
    tester,
  ) async {
    Widget symbol(String name, Color color) => MaterialApp(
      home: Center(
        child: QuotaSymbol(name: name, size: 12, color: color),
      ),
    );
    await tester.pumpWidget(symbol('sun.max.fill', Colors.white));
    expect(find.byIcon(CupertinoIcons.sun_max_fill), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.white);
    expect(tester.widget<Icon>(find.byType(Icon)).fontWeight, FontWeight.w400);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: QuotaSymbol(
            name: 'sun.max.fill',
            size: 12,
            color: Colors.white,
            semibold: true,
          ),
        ),
      ),
    );
    expect(tester.widget<Icon>(find.byType(Icon)).fontWeight, FontWeight.w600);
    await tester.pumpWidget(symbol('moon.fill', Colors.black));
    expect(find.byIcon(CupertinoIcons.moon_fill), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.black);
    await tester.pumpWidget(symbol('pin.slash.fill', Colors.green));
    expect(find.byIcon(CupertinoIcons.pin_slash_fill), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).size, 15);
    expect(tester.getSize(find.byType(QuotaSymbol)), const Size(12, 12));
    await tester.pumpWidget(symbol('pin.fill', Colors.green));
    expect(find.byIcon(CupertinoIcons.pin_fill), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).size, 15);
  });

  testWidgets('semibold changes the rendered line weight', (tester) async {
    final regularKey = GlobalKey();
    final semiboldKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            RepaintBoundary(
              key: regularKey,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: QuotaSymbol(
                    name: 'xmark',
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              key: semiboldKey,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: QuotaSymbol(
                    name: 'xmark',
                    size: 12,
                    color: Colors.white,
                    semibold: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Future<int> ink(GlobalKey key) async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      return tester
          .runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 3);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            var alpha = 0;
            for (var index = 3; index < bytes.length; index += 4) {
              alpha += bytes[index];
            }
            image.dispose();
            return alpha;
          })
          .then((value) => value!);
    }

    final regularInk = await ink(regularKey);
    final semiboldInk = await ink(semiboldKey);
    expect(semiboldInk, greaterThan(regularInk));
  });

  testWidgets('composite and custom symbols use native macOS metrics', (
    tester,
  ) async {
    expect(
      QuotaHardwareSymbol.naturalSizeFor('internaldrive'),
      const Size(14, 10),
    );
    expect(
      QuotaHardwareSymbol.naturalSizeFor('memorychip'),
      const Size(13, 10),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: QuotaSymbol(
            name: 'calendar.badge.clock',
            size: 10,
            color: Colors.white,
          ),
        ),
      ),
    );
    final stack = find.descendant(
      of: find.byType(QuotaSymbol),
      matching: find.byType(Stack),
    );
    expect(stack, findsOneWidget);
    expect(tester.getSize(stack), const Size(14, 12));
    expect(tester.takeException(), isNull);
  });
}
