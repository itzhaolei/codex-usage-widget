import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';
import 'codex_paths.dart';

typedef LegacySettingsReader = Future<Map<String, Object?>?> Function();

/// The settings persisted by the desktop widget.
///
/// Keeping the value object next to the repository gives callers one stable
/// shape to pass around while the storage details remain confined to this
/// file. The defaults preserve the earlier macOS and Windows settings.
class AppSettings {
  const AppSettings({
    this.light = false,
    this.pinned = true,
    this.language,
    this.left,
    this.top,
    this.progressColorIndex = 0,
  });

  final bool light;
  final bool pinned;
  final String? language;
  final double? left;
  final double? top;
  final int progressColorIndex;

  AppSettings copyWith({
    bool? light,
    bool? pinned,
    String? language,
    double? left,
    double? top,
    int? progressColorIndex,
  }) {
    return AppSettings(
      light: light ?? this.light,
      pinned: pinned ?? this.pinned,
      language: language ?? this.language,
      left: left ?? this.left,
      top: top ?? this.top,
      progressColorIndex: progressColorIndex ?? this.progressColorIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.light == light &&
        other.pinned == pinned &&
        other.language == language &&
        other.left == left &&
        other.top == top &&
        other.progressColorIndex == progressColorIndex;
  }

  @override
  int get hashCode =>
      Object.hash(light, pinned, language, left, top, progressColorIndex);
}

/// Reads and writes widget preferences using the platform's shared
/// preferences implementation.
///
/// A [SharedPreferences] instance can be injected in tests or by an app that
/// already loaded it.  When omitted, the repository lazily obtains the
/// process-wide instance on the first operation.
class SettingsRepository {
  SettingsRepository({
    SharedPreferences? preferences,
    LegacySettingsReader? legacyReader,
    String? codexHome,
  }) : // Keep injectable parameter names public for tests and embedders.
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // ignore: prefer_initializing_formals
       _legacyReader = legacyReader,
       _codexHome = codexHome ?? resolveCodexHome();

  static const lightKey = 'light';
  static const pinnedKey = 'pinned';
  static const languageKey = 'language';
  static const leftKey = 'left';
  static const topKey = 'top';
  static const progressColorIndexKey = 'progressColorIndex';
  static const _migrationKey = 'legacySettingsMigratedV4';
  static const _desktopChannel = MethodChannel('quota_bubble/desktop');

  SharedPreferences? _preferences;
  final LegacySettingsReader? _legacyReader;
  final String _codexHome;

  Future<SharedPreferences> get _store async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<AppSettings> load() async {
    try {
      final preferences = await _store;
      await _migrateLegacySettings(preferences);
      return AppSettings(
        light: preferences.getBool(lightKey) ?? false,
        pinned: preferences.getBool(pinnedKey) ?? true,
        language: _readLanguage(preferences),
        left: _readDouble(preferences, leftKey),
        top: _readDouble(preferences, topKey),
        progressColorIndex: _readColorIndex(preferences),
      );
    } catch (_) {
      // A preferences backend may be unavailable while the app is starting
      // (or after a storage failure).  The widget can still run with defaults.
      return const AppSettings();
    }
  }

  /// Saves a complete [AppSettings] value, or merges the supplied named
  /// values into the currently persisted settings.  The named form keeps
  /// small UI actions (for example changing only the pin state) inexpensive
  /// for callers while retaining the complete-value API for startup code.
  Future<void> save({
    AppSettings? settings,
    bool? light,
    bool? pinned,
    String? language,
    double? left,
    double? top,
    int? progressColorIndex,
  }) async {
    try {
      final preferences = await _store;
      final current = settings ?? await load();
      await preferences.setBool(lightKey, light ?? current.light);
      await preferences.setBool(pinnedKey, pinned ?? current.pinned);
      await _writeNullableString(
        preferences,
        languageKey,
        language ?? current.language,
      );
      await _writeNullableDouble(preferences, leftKey, left ?? current.left);
      await _writeNullableDouble(preferences, topKey, top ?? current.top);
      await preferences.setInt(
        progressColorIndexKey,
        (progressColorIndex ?? current.progressColorIndex).clamp(0, 4).toInt(),
      );
    } catch (_) {
      // Saving preferences is best effort.  A transient storage error should
      // not take down the quota refresh loop or the widget window.
    }
  }

  Future<void> saveSettings(AppSettings settings) => save(settings: settings);

  Future<void> setLight(bool value) => save(light: value);

  Future<void> setPinned(bool value) => save(pinned: value);

  Future<void> setLanguage(String? value) async {
    try {
      final preferences = await _store;
      await _writeNullableString(preferences, languageKey, value);
      await _writeLanguageFile(value);
    } catch (_) {
      // Best effort, matching [save].
    }
  }

  Future<void> setProgressColorIndex(int value) =>
      save(progressColorIndex: value);

  static String? _readLanguage(SharedPreferences preferences) {
    final value = preferences.getString(languageKey)?.trim().toLowerCase();
    return supportedLanguages.contains(value) ? value : null;
  }

  static double? _readDouble(SharedPreferences preferences, String key) {
    final value = preferences.get(key);
    return value is num ? value.toDouble() : null;
  }

  static int _readColorIndex(SharedPreferences preferences) {
    final value = preferences.get(progressColorIndexKey);
    if (value is! num) return 0;
    return value.toInt().clamp(0, 4);
  }

  Future<void> _migrateLegacySettings(SharedPreferences preferences) async {
    if (preferences.getBool(_migrationKey) == true) return;
    try {
      final legacy = await (_legacyReader ?? _readDesktopLegacySettings).call();
      if (legacy != null) {
        if (!preferences.containsKey(lightKey) && legacy['light'] is bool) {
          await preferences.setBool(lightKey, legacy['light']! as bool);
        }
        if (!preferences.containsKey(pinnedKey) && legacy['pinned'] is bool) {
          await preferences.setBool(pinnedKey, legacy['pinned']! as bool);
        }
        if (!preferences.containsKey(leftKey) && legacy['left'] is num) {
          await preferences.setDouble(
            leftKey,
            (legacy['left']! as num).toDouble(),
          );
        }
        if (!preferences.containsKey(topKey) && legacy['top'] is num) {
          await preferences.setDouble(
            topKey,
            (legacy['top']! as num).toDouble(),
          );
        }
        if (!preferences.containsKey(progressColorIndexKey) &&
            legacy['progressColorIndex'] is num) {
          await preferences.setInt(
            progressColorIndexKey,
            (legacy['progressColorIndex']! as num).toInt().clamp(0, 4),
          );
        }
      }
      if (!preferences.containsKey(languageKey)) {
        final language = await _readLanguageFile();
        if (language != null) {
          await preferences.setString(languageKey, language);
        }
      }
      await preferences.setBool(_migrationKey, true);
    } on Object {
      // Migration is best effort. A transient failure is retried next launch.
    }
  }

  Future<Map<String, Object?>?> _readDesktopLegacySettings() async {
    if (Platform.isMacOS) {
      final values = await _desktopChannel.invokeMapMethod<String, Object?>(
        'legacySettings',
      );
      return values == null ? null : Map<String, Object?>.from(values);
    }
    if (!Platform.isWindows) return null;
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) return null;
    final file = File(
      '$localAppData${Platform.pathSeparator}QuotaBubble'
      '${Platform.pathSeparator}settings.json',
    );
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value as Object?),
    );
  }

  Future<String?> _readLanguageFile() async {
    final file = File(
      '$_codexHome${Platform.pathSeparator}usage-widget'
      '${Platform.pathSeparator}language.txt',
    );
    if (!await file.exists()) return null;
    final value = (await file.readAsString()).trim().toLowerCase();
    return supportedLanguages.contains(value) ? value : null;
  }

  Future<void> _writeLanguageFile(String? value) async {
    final file = File(
      '$_codexHome${Platform.pathSeparator}usage-widget'
      '${Platform.pathSeparator}language.txt',
    );
    if (value == null || value.trim().isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString('${value.trim().toLowerCase()}\n', flush: true);
  }

  static Future<void> _writeNullableString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, normalized);
    }
  }

  static Future<void> _writeNullableDouble(
    SharedPreferences preferences,
    String key,
    double? value,
  ) async {
    if (value == null || !value.isFinite) {
      await preferences.remove(key);
    } else {
      await preferences.setDouble(key, value);
    }
  }
}
