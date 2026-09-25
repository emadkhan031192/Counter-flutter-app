import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../models/tasbeeh_preset.dart';
import 'hive_service.dart';
import 'native_bridge.dart';

class CounterProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _hive = HiveService.instance;
  final _native = NativeBridge.instance;

  Timer? _lastTapGuard;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _debounce = Duration(milliseconds: 150);

  late TasbeehPreset active;
  List<TasbeehPreset> presets = [];

  CounterProvider() {
    _refresh();
    WidgetsBinding.instance.addObserver(this);
    _native.setForegroundTickListener(() => _registerTick(fromNative: true));
  }

  void _refresh() {
    active = _hive.activePreset;
    presets = _hive.allPresets();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncPendingNativeCounts();
    }
  }

  /// Pulls in any counts the native side queued while the screen was off
  /// or the app was backgrounded, and folds them into the active preset.
  Future<void> syncPendingNativeCounts() async {
    final pending = await _native.takePendingCount();
    if (pending > 0) {
      active = await _hive.applyPendingCounts(pending);
      notifyListeners();
    }
  }

  /// Screen-tap increment, with a 150ms debounce against phantom
  /// double-touches.
  void onScreenTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime) < _debounce) return;
    _lastTapTime = now;
    HapticFeedback.lightImpact();
    _registerTick(fromNative: false);
  }

  Future<void> _registerTick({required bool fromNative}) async {
    active = await _hive.incrementActive();
    notifyListeners();
  }

  Future<void> resetActive() async {
    active = await _hive.resetActive();
    notifyListeners();
  }

  Future<void> switchPreset(String name) async {
    await _hive.setActivePreset(name);
    _refresh();
    notifyListeners();
  }

  Future<void> addCustomPreset(String name, int target) async {
    await _hive.savePreset(TasbeehPreset(name: name, target: target, isCustom: true));
    await switchPreset(name);
  }

  Future<void> deletePreset(String name) async {
    await _hive.deletePreset(name);
    if (active.name == name) {
      await switchPreset(_hive.allPresets().first.name);
    } else {
      _refresh();
      notifyListeners();
    }
  }

  // ---- Volume-button counting ----

  bool get volumeButtonEnabled => _hive.volumeButtonEnabled;
  String get volumeButtonKey => _hive.volumeButtonKey;

  Future<void> setVolumeCounting(bool enabled, String key) async {
    await _hive.setVolumeButtonEnabled(enabled);
    await _hive.setVolumeButtonKey(key);
    if (enabled) {
      await _native.startVolumeCounting(useVolumeUp: key == 'up');
    } else {
      await _native.stopVolumeCounting();
    }
    notifyListeners();
  }

  // ---- Reminder ----

  bool get reminderEnabled => _hive.reminderEnabled;
  int get reminderHour => _hive.reminderHour;
  int get reminderMinute => _hive.reminderMinute;

  Future<void> setReminder(bool enabled, TimeOfDay time) async {
    await _hive.setReminderEnabled(enabled);
    await _hive.setReminderTime(time.hour, time.minute);
    if (enabled) {
      await _native.scheduleReminder(hour: time.hour, minute: time.minute);
    } else {
      await _native.cancelReminder();
    }
    notifyListeners();
  }

  // ---- Stats ----
  int totalFor(String period) => _hive.totalFor(period);
  List<MapEntry<String, int>> historyFor(String period) {
    final prefix = switch (period) {
      'day' => 'daily',
      'week' => 'weekly',
      'month' => 'monthly',
      'year' => 'yearly',
      _ => throw ArgumentError(period),
    };
    return _hive.historyFor(prefix);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastTapGuard?.cancel();
    super.dispose();
  }
}
