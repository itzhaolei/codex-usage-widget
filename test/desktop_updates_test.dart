import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/desktop_app.dart';
import 'package:quota_bubble/presentation/quota_window.dart';
import 'package:quota_bubble/presentation/state/quota_controller.dart';
import 'package:quota_bubble/services/update_service.dart';

void main() {
  testWidgets(
    'version label opens updates and reflects the available-update dot',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(330, 287);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = QuotaController()..windowVisible = false;
      addTearDown(controller.dispose);
      var opens = 0;
      Widget scene(bool hasUpdate) => MaterialApp(
        home: QuotaWindow(
          controller: controller,
          onClose: () {},
          version: '4.0.0',
          hasUpdate: hasUpdate,
          onUpdate: () => opens++,
        ),
      );
      await tester.pumpWidget(scene(false));
      expect(find.byKey(const ValueKey('quota-update-dot')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quota-version-update')));
      expect(opens, 1);
      await tester.pumpWidget(scene(true));
      expect(find.byKey(const ValueKey('quota-update-dot')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('quota-update-dot'))),
        const Size(4, 4),
      );
    },
  );

  testWidgets('preview never starts updater checks and disposes its service', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(330, 287);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final platformCalls = <MethodCall>[];
    const channels = [
      MethodChannel('tray_manager'),
      MethodChannel('window_manager'),
      MethodChannel('quota_bubble/desktop'),
    ];
    for (final channel in channels) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        platformCalls.add(call);
        if (call.method == 'isMinimized') return false;
        return null;
      });
    }
    addTearDown(() {
      for (final channel in channels) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    });
    final controller = QuotaController()..windowVisible = false;
    final updates = _Updates();
    await tester.pumpWidget(
      QuotaBubbleApp(preview: controller, updateService: updates),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(updates.starts, 0);
    expect(updates.checks, 0);
    final version = tester.widget<QuotaWindow>(find.byType(QuotaWindow));
    expect(version.onUpdate, isNull);
    final menu = platformCalls
        .where((call) => call.method == 'setContextMenu')
        .last
        .arguments
        .toString();
    expect(menu, isNot(contains('uninstall')));
    expect(menu, isNot(contains('update')));
    updates.available = true;
    updates.changed();
    await tester.pump();
    expect(find.byKey(const ValueKey('quota-update-dot')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(updates.disposed, isTrue);
  });
}

class _Updates extends UpdateService {
  _Updates() : super(currentVersion: '4.0.0');
  int starts = 0;
  int checks = 0;
  bool disposed = false;
  bool available = false;
  void changed() => notifyListeners();
  @override
  bool get hasUpdate => available;
  @override
  void start() => starts++;
  @override
  Future<UpdateRelease?> check({bool force = false}) async {
    checks++;
    return null;
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
