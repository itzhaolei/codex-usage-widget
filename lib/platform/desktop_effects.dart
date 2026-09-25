import 'dart:io';

import 'package:flutter/services.dart';

/// The platform bridge only provides OS glass and window visibility. Quota,
/// layout, animation and interaction are shared Flutter code.
class DesktopEffects {
  static const _channel = MethodChannel('quota_bubble/desktop');

  static void observeVisibility(void Function(bool) onChanged) {
    if (!Platform.isMacOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'visibilityChanged') {
        onChanged(call.arguments == true);
      }
    });
  }

  static Future<void> setAppearance({required bool light}) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod<void>('setAppearance', {'light': light});
  }

  static Future<void> setPinned(bool pinned) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod<void>('setPinned', {'pinned': pinned});
  }
}
