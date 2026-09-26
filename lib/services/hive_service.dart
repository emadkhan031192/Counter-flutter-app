import 'package:hive_flutter/hive_flutter.dart';
import '../models/tasbeeh_preset.dart';

/// Central Hive access point. All persistence in the app goes through here.
///
/// Boxes:
///  - `presets`    : key = preset name -> Map{target, count, isCustom}
///  - `settings`   : key = setting name -> value
///  - `aggregates` : key = "daily_YYYY-MM-DD" / "weekly_YYYY-Www" /
///                   "monthly_YYYY-MM" / "yearly_YYYY" -> int running total
class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  late Box _presets;
  late Box _settings;
  late Box _aggregates;

  Future<void> init() async {
    await Hive.initFlutter();

    _presets = await Hive.openBox('presets');
    _settings = await Hive.openBox('settings');
    _aggregates = await Hive.openBox('aggregates');

    if (_presets.isEmpty) {
      for (final p in TasbeehPreset.defaults()) {
        await _presets.put(p.name, p.toMap());
      }

      await _settings.put(
        'activePreset',
        TasbeehPreset.defaults().first.name,
      );
    }

    // Initialize default settings only if they don't already exist.
    if (!_settings.containsKey('volumeButtonEnabled')) {
      await _settings.put('volumeButtonEnabled', false);
    }

    if (!_settings.containsKey('volumeButtonKey')) {
      await _settings.put('volumeButtonKey', 'down');
    }

    if (!_settings.containsKey('reminderEnabled')) {
      await _settings.put('reminderEnabled', false);
    }

    if (!_settings.containsKey('reminderHour')) {
      await _settings.put('reminderHour', 20);
    }

    if (!_settings.containsKey('reminderMinute')) {
      await _settings.put('reminderMinute', 0);
    }
  }

  // ---------------- Presets ----------------

  List<TasbeehPreset> allPresets() => _presets.keys
      .map(
        (k) => TasbeehPreset.fromMap(
          k as String,
          _presets.get(k) as Map,
        ),
      )
      .toList();

  TasbeehPreset getPreset(String name) =>
      TasbeehPreset.fromMap(name, _presets.get(name) as Map);

  String get activePresetName =>
      _settings.get('activePreset') as String;

  TasbeehPreset get activePreset =>
      getPreset(activePresetName);

  Future<void> setActivePreset(String name) =>
      _settings.put('activePreset', name);

  Future<void> savePreset(TasbeehPreset preset) =>
      _presets.put(preset.name, preset.toMap());

  Future<void> deletePreset(String name) =>
      _presets.delete(name);

  /// Adds one tick to the active preset's count and rolls it into every
  /// aggregate bucket. Returns the updated preset.
  Future<TasbeehPreset> incrementActive() async {
    final current = activePreset;

    final updated = current.copyWith(
      count: current.count + 1,
    );

    await savePreset(updated);
    await _bumpAggregates(1);

    return updated;
  }

  /// Applies a batch of counts that were recorded natively while the app
  /// was backgrounded/screen-off (see VolumeButtonService).
  Future<TasbeehPreset> applyPendingCounts(int pending) async {
    if (pending <= 0) {
      return activePreset;
    }

    final current = activePreset;

    final updated = current.copyWith(
      count: current.count + pending,
    );

    await savePreset(updated);
    await _bumpAggregates(pending);

    return updated;
  }

  /// Resets only the active preset's current count.
  /// Aggregates are untouched.
  Future<TasbeehPreset> resetActive() async {
    final current = activePreset;

    final updated = current.copyWith(
      count: 0,
    );

    await savePreset(updated);

    return updated;
  }

  // ---------------- Settings ----------------

  bool get volumeButtonEnabled =>
      _settings.get('volumeButtonEnabled') as bool;

  Future<void> setVolumeButtonEnabled(bool v) =>
      _settings.put('volumeButtonEnabled', v);

  /// 'up' or 'down'
  String get volumeButtonKey =>
      _settings.get('volumeButtonKey') as String;

  Future<void> setVolumeButtonKey(String key) =>
      _settings.put('volumeButtonKey', key);

  bool get reminderEnabled =>
      _settings.get('reminderEnabled') as bool;

  Future<void> setReminderEnabled(bool v) =>
      _settings.put('reminderEnabled', v);

  int get reminderHour =>
      _settings.get('reminderHour') as int;

  int get reminderMinute =>
      _settings.get('reminderMinute') as int;

  Future<void> setReminderTime(
    int hour,
    int minute,
  ) async {
    await _settings.put('reminderHour', hour);
    await _settings.put('reminderMinute', minute);
  }

  // ---------------- Aggregates ----------------

  Future<void> _bumpAggregates(int amount) async {
    final now = DateTime.now();

    for (final key in _bucketKeysFor(now)) {
      final existing =
          (_aggregates.get(key) as num?)?.toInt() ?? 0;

      await _aggregates.put(
        key,
        existing + amount,
      );
    }
  }

  List<String> _bucketKeysFor(DateTime d) => [
        'daily_${_dateStr(d)}',
        'weekly_${_isoWeekStr(d)}',
        'monthly_${_monthStr(d)}',
        'yearly_${d.year}',
      ];

  int totalFor(String period) {
    final now = DateTime.now();

    final key = switch (period) {
      'day' => 'daily_${_dateStr(now)}',
      'week' => 'weekly_${_isoWeekStr(now)}',
      'month' => 'monthly_${_monthStr(now)}',
      'year' => 'yearly_${now.year}',
      _ => throw ArgumentError(
          'Unknown period $period',
        ),
    };

    return (_aggregates.get(key) as num?)?.toInt() ?? 0;
  }

  /// Past buckets of a given period type, newest first,
  /// excluding the current (still-live) bucket.
  List<MapEntry<String, int>> historyFor(String prefix) {
    final currentKey = _bucketKeysFor(DateTime.now())
        .firstWhere(
          (k) => k.startsWith('${prefix}_'),
        );

    final entries = _aggregates.keys
        .cast<String>()
        .where(
          (k) =>
              k.startsWith('${prefix}_') &&
              k != currentKey,
        )
        .map(
          (k) => MapEntry(
            k.substring(prefix.length + 1),
            (_aggregates.get(k) as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    entries.sort(
      (a, b) => b.key.compareTo(a.key),
    );

    return entries;
  }

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _monthStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';

  /// ISO-8601 week number with Monday as the first day of the week.
  static String _isoWeekStr(DateTime d) {
    final thursday = d.add(
      Duration(
        days: 3 - ((d.weekday + 6) % 7),
      ),
    );

    final firstThursday = DateTime(
      thursday.year,
      1,
      4,
    ).add(
      Duration(
        days: 3 -
            ((DateTime(
                      thursday.year,
                      1,
                      4,
                    ).weekday +
                    6) %
                7),
      ),
    );

    final week = 1 +
        ((thursday.difference(firstThursday).inDays) / 7)
            .floor();

    return '${thursday.year.toString().padLeft(4, '0')}-'
        'W${week.toString().padLeft(2, '0')}';
  }
}
