import 'package:flutter/services.dart';

/// Bridges to native Android code for the two things Dart can't do
/// reliably on its own:
///  1. Counting on the volume key while the screen is off/locked
///     (needs a foreground service + an Accessibility-service key
///     listener - see android/.../VolumeKeyAccessibilityService.kt).
///  2. Exact-alarm daily reminders that survive a reboot without
///     needing the Flutter engine to be running (see
///     android/.../ReminderReceiver.kt + BootReceiver.kt).
///
/// Native increments recorded while the app was backgrounded are stashed
/// in Android SharedPreferences and pulled with [takePendingCount] the
/// next time the app resumes.
class NativeBridge {
  NativeBridge._();
  static final NativeBridge instance = NativeBridge._();

  static const _channel = MethodChannel('com.afzal.zikr/native');

  /// Called by native code the moment a volume-key tick happens while the
  /// app is alive in the foreground (screen on). Screen-off ticks are
  /// queued natively instead and read back via [takePendingCount].
  void setForegroundTickListener(void Function() onTick) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVolumeTick') {
        onTick();
      }
    });
  }

  /// Starts the foreground service + accessibility key listener so the
  /// chosen volume button counts even with the screen off/locked.
  /// [useVolumeUp] = true counts on Volume Up, false counts on Volume Down;
  /// the other button is left free to control media volume as normal.
  Future<void> startVolumeCounting({required bool useVolumeUp}) async {
    await _channel.invokeMethod('startVolumeCounting', {'useVolumeUp': useVolumeUp});
  }

  Future<void> stopVolumeCounting() async {
    await _channel.invokeMethod('stopVolumeCounting');
  }

  /// Returns whether the Accessibility Service the volume-key listener
  /// depends on has been granted, and opens the system Accessibility
  /// settings screen if [openSettingsIfDisabled] is true and it isn't.
  Future<bool> isAccessibilityServiceEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
    return enabled ?? false;
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Counts queued natively (screen-off ticks, or ticks while the app was
  /// killed) since the last time this was called. Call this on every
  /// resume and apply the result via HiveService.applyPendingCounts.
  Future<int> takePendingCount() async {
    final n = await _channel.invokeMethod<int>('takePendingCount');
    return n ?? 0;
  }

  Future<void> scheduleReminder({required int hour, required int minute}) async {
    await _channel.invokeMethod('scheduleReminder', {'hour': hour, 'minute': minute});
  }

  Future<void> cancelReminder() async {
    await _channel.invokeMethod('cancelReminder');
  }
}
