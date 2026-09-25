import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'core/models.dart';
import 'l10n/app_localizations.dart';
import 'platform/desktop_effects.dart';
import 'platform/window_placement.dart';
import 'presentation/quota_window.dart';
import 'presentation/state/quota_controller.dart';
import 'presentation/update_dialog.dart';
import 'services/update_service.dart';

const appVersion = '4.0.0';

typedef WindowLevelSetter = Future<void> Function(bool pinned);

WindowOptions quotaWindowOptions({required double height, bool? isMacOS}) {
  final useNativeMacOSLevel = isMacOS ?? Platform.isMacOS;
  return WindowOptions(
    size: Size(330, height),
    minimumSize: const Size(330, 234),
    maximumSize: const Size(330, 1000),
    title: 'Quota Bubble',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: useNativeMacOSLevel ? null : TitleBarStyle.hidden,
    windowButtonVisibility: false,
    alwaysOnTop: useNativeMacOSLevel ? null : true,
  );
}

Future<void> setPinnedWindowLevel(
  bool pinned, {
  bool? isMacOS,
  WindowLevelSetter? macOSSetter,
  WindowLevelSetter? windowManagerSetter,
}) {
  if (isMacOS ?? Platform.isMacOS) {
    return (macOSSetter ?? DesktopEffects.setPinned)(pinned);
  }
  return (windowManagerSetter ?? windowManager.setAlwaysOnTop)(pinned);
}

Future<void> runQuotaBubble({
  QuotaController? preview,
  VoidCallback? replay,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  await windowManager.waitUntilReadyToShow(
    quotaWindowOptions(
      height: preview == null ? 287 : QuotaWindow.heightFor(preview),
    ),
    () async {
      await windowManager.setResizable(false);
    },
  );
  runApp(QuotaBubbleApp(preview: preview, replay: replay));
}

class QuotaBubbleApp extends StatefulWidget {
  const QuotaBubbleApp({
    super.key,
    this.preview,
    this.replay,
    this.updateService,
  });
  final QuotaController? preview;
  final VoidCallback? replay;
  final UpdateService? updateService;

  @override
  State<QuotaBubbleApp> createState() => _QuotaBubbleAppState();
}

class _QuotaBubbleAppState extends State<QuotaBubbleApp>
    with WindowListener, TrayListener {
  late final QuotaController controller;
  late final UpdateService updates;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _dialogOpen = false;
  bool _hasUpdate = false;
  bool _updateBusy = false;
  bool _closing = false;
  bool _initialized = false;
  bool _visible = true;
  bool _trayReady = false;
  String _trayLanguage = '';
  bool? _light;
  bool? _pinned;
  double? _height;
  int? _percentage;
  bool _statusInitialized = false;

  @override
  void initState() {
    super.initState();
    controller =
        widget.preview ?? QuotaController(onStatusUpdate: _updateTrayStatus);
    controller.addListener(_onControllerChanged);
    updates = widget.updateService ?? UpdateService(currentVersion: appVersion);
    updates.addListener(_onUpdatesChanged);
    _hasUpdate = updates.hasUpdate;
    _updateBusy = updates.busy;
    windowManager.addListener(this);
    trayManager.addListener(this);
    DesktopEffects.observeVisibility(_setVisible);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/tray.ico' : 'assets/status.png',
        isTemplate: Platform.isMacOS,
      );
      if (!mounted) return;
      _trayReady = true;
      await _rebuildTrayMenu();
    } on Object {
      _trayReady = false;
    }
    if (!mounted) return;
    if (widget.preview == null) {
      updates.start();
      await controller.start();
    }
    if (!mounted) return;
    await DesktopEffects.setAppearance(light: controller.light);
    await setPinnedWindowLevel(controller.pinned);
    final height = QuotaWindow.heightFor(controller).clamp(234.0, 1000.0);
    _height = height;
    await windowManager.setSize(Size(330, height));
    if (controller.left != null || controller.top != null) {
      final position = await validatedSavedWindowPosition(
        left: controller.left,
        top: controller.top,
        windowSize: Size(330, height),
      );
      if (position == null) {
        await windowManager.center();
      } else {
        await windowManager.setPosition(position);
      }
    }
    _initialized = true;
    _onControllerChanged();
    _updateTrayStatus(
      controller.fiveHourRemaining ?? controller.weeklyRemaining,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _closing) return;
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _rebuildTrayMenu() async {
    if (!_trayReady) {
      return;
    }
    _trayLanguage = controller.language;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: controller.copy.show),
          if (widget.replay != null) MenuItem(key: 'replay', label: '重播额度恢复动效'),
          MenuItem.submenu(
            label: controller.copy.language,
            submenu: Menu(
              items: [
                MenuItem.checkbox(
                  key: 'lang:system',
                  label: controller.copy.followSystem,
                  checked: controller.languageOverride == null,
                ),
                MenuItem.separator(),
                ...supportedLanguages.map(
                  (code) => MenuItem.checkbox(
                    key: 'lang:$code',
                    label: localizedLanguageName(code),
                    checked: controller.languageOverride == code,
                  ),
                ),
              ],
            ),
          ),
          if (widget.preview == null) ...[
            MenuItem.separator(),
            MenuItem(key: 'update', label: controller.copy.update),
            MenuItem(key: 'website', label: controller.copy.website),
            MenuItem(key: 'share', label: _shareLabel(controller.language)),
            MenuItem(
              key: 'uninstall',
              label: controller.copy.uninstall,
              disabled: updates.busy,
            ),
          ],
          MenuItem.separator(),
          MenuItem(key: 'exit', label: controller.copy.exit),
        ],
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_light != controller.light) {
      _light = controller.light;
      unawaited(DesktopEffects.setAppearance(light: controller.light));
    }
    if (_pinned != controller.pinned) {
      _pinned = controller.pinned;
      unawaited(setPinnedWindowLevel(controller.pinned));
    }
    if (_trayLanguage != controller.language) unawaited(_rebuildTrayMenu());
    _resizeToContent();
  }

  void _onUpdatesChanged() {
    if (!mounted || _closing) return;
    final changed = _hasUpdate != updates.hasUpdate;
    _hasUpdate = updates.hasUpdate;
    if (_updateBusy != updates.busy) {
      _updateBusy = updates.busy;
      unawaited(_rebuildTrayMenu());
    }
    if (changed && _visible) setState(() {});
  }

  Future<void> _showActionDialog(String action) async {
    if (widget.preview != null || _dialogOpen || _closing) return;
    if (action == 'uninstall' && updates.busy) return;
    _dialogOpen = true;
    try {
      await _showWindow();
      if (!mounted) return;
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      switch (action) {
        case 'update':
          await showQuotaUpdateDialog(
            context,
            service: updates,
            language: controller.language,
            onExit: _exit,
          );
        case 'share':
          await showQuotaShareDialog(
            context,
            service: updates,
            language: controller.language,
          );
        case 'uninstall':
          await showQuotaUninstallDialog(
            context,
            service: updates,
            language: controller.language,
            onExit: _exit,
          );
      }
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _openWebsite() async {
    try {
      await updates.openWebsite();
    } on Object {
      // The share dialog also exposes the address when the browser cannot open.
      await _showActionDialog('share');
    }
  }

  void _updateTrayStatus(int? remaining) {
    if (!_trayReady || (_statusInitialized && _percentage == remaining)) return;
    _statusInitialized = true;
    _percentage = remaining;
    if (Platform.isMacOS) {
      unawaited(trayManager.setTitle(remaining == null ? '—' : '$remaining%'));
    }
    unawaited(
      trayManager.setToolTip(
        remaining == null ? 'Quota Bubble' : 'Quota Bubble $remaining%',
      ),
    );
  }

  void _resizeToContent() {
    if (!_visible) return;
    final height = QuotaWindow.heightFor(controller);
    if (_height == height) return;
    _height = height;
    unawaited(windowManager.setSize(Size(330, height.clamp(234, 1000))));
  }

  void _setVisible(bool value) {
    if (!mounted || _closing || _visible == value) return;
    _visible = value;
    controller.setWindowVisible(value);
    setState(() {});
    if (value) _resizeToContent();
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    _setVisible(true);
  }

  Future<void> _hideWindow() async {
    _setVisible(false);
    await windowManager.hide();
  }

  Future<void> _exit() async {
    _closing = true;
    await trayManager.destroy();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    debugShowCheckedModeBanner: false,
    home: Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _visible
            ? GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                child: QuotaWindow(
                  controller: controller,
                  onClose: _hideWindow,
                  version: appVersion,
                  hasUpdate: _hasUpdate,
                  onUpdate: widget.preview == null
                      ? () => unawaited(_showActionDialog('update'))
                      : null,
                ),
              )
            : const SizedBox.expand(),
      ),
    ),
  );

  @override
  void onWindowClose() {
    if (!_closing) unawaited(_hideWindow());
  }

  @override
  void onWindowFocus() => _setVisible(true);
  @override
  void onWindowMinimize() => _setVisible(false);
  @override
  void onWindowRestore() => _setVisible(true);
  @override
  void onWindowMoved() async {
    if (widget.preview != null || !_initialized) return;
    final position = await windowManager.getPosition();
    await controller.setPosition(position.dx, position.dy);
  }

  @override
  void onTrayIconMouseDown() => unawaited(_showWindow());
  @override
  void onTrayIconRightMouseDown() => unawaited(trayManager.popUpContextMenu());
  @override
  void onTrayMenuItemClick(MenuItem item) {
    if (item.key == 'show') unawaited(_showWindow());
    if (item.key == 'replay') widget.replay?.call();
    if (widget.preview == null) {
      if (item.key == 'update' ||
          item.key == 'share' ||
          item.key == 'uninstall') {
        unawaited(_showActionDialog(item.key!));
      }
      if (item.key == 'website') unawaited(_openWebsite());
    }
    if (item.key?.startsWith('lang:') == true) {
      final code = item.key!.substring(5);
      unawaited(
        controller
            .setLanguage(code == 'system' ? null : code)
            .then((_) => _rebuildTrayMenu()),
      );
    }
    if (item.key == 'exit') unawaited(_exit());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    updates.removeListener(_onUpdatesChanged);
    updates.dispose();
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }
}

String _shareLabel(String language) =>
    const {
      'zh': '分享',
      'ja': '共有',
      'ko': '공유',
      'de': 'Teilen',
      'fr': 'Partager',
      'es': 'Compartir',
      'pt': 'Compartilhar',
      'it': 'Condividi',
      'nl': 'Delen',
    }[language] ??
    'Share';
