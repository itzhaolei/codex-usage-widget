import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_bubble/presentation/update_dialog.dart';
import 'package:quota_bubble/presentation/widgets/quota_symbol.dart';
import 'package:quota_bubble/services/update_service.dart';

void main() {
  testWidgets(
    'an available update requires the update button before installation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(330, 400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final service = _DialogService();
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: QuotaUpdateDialog(
            service: service,
            language: 'zh',
            onExit: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('发现新版本'), findsOneWidget);
      expect(service.installs, 0);
      expect(
        tester.widget<QuotaSymbol>(find.byType(QuotaSymbol)).name,
        'info.circle.fill',
      );
      await tester.tap(find.text('更新并重启'));
      await tester.pump();
      expect(service.installs, 1);
    },
  );

  testWidgets('failure dialog displays the native error symbol and retries', (
    tester,
  ) async {
    final service = _DialogService()..fail = true;
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: QuotaUpdateDialog(
          service: service,
          language: 'en',
          onExit: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update failed'), findsOneWidget);
    expect(
      tester.widget<QuotaSymbol>(find.byType(QuotaSymbol)).name,
      'xmark.octagon.fill',
    );
    service.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(service.installs, 0);
  });

  testWidgets('canceling uninstall leaves the app untouched', (tester) async {
    final service = _DialogService();
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showQuotaUninstallDialog(
              context,
              service: service,
              language: 'zh',
              onExit: () async {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<QuotaSymbol>(find.byType(QuotaSymbol)).name,
      'exclamationmark.triangle.fill',
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(service.uninstalls, 0);
    expect(find.text('卸载 Quota Bubble？'), findsNothing);
  });
}

class _DialogService extends UpdateService {
  _DialogService() : super(currentVersion: '4.0.0');
  bool fail = false;
  int installs = 0;
  int uninstalls = 0;

  @override
  Future<UpdateRelease?> check({bool force = false}) async {
    state = fail ? UpdateState.failed : UpdateState.available;
    error = fail ? 'Unable to connect.' : null;
    notifyListeners();
    return null;
  }

  @override
  Future<bool> downloadAndInstall({
    required Future<void> Function() onExit,
  }) async {
    installs++;
    return true;
  }

  @override
  Future<void> uninstall({required Future<void> Function() onExit}) async {
    uninstalls++;
  }
}
