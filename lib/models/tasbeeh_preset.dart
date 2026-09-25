/// A single tasbeeh preset: its dhikr text, target count, and its own
/// independent running count. Stored in Hive as a plain Map<String, dynamic>
/// so no generated TypeAdapter is required.
class TasbeehPreset {
  final String name;
  final int target;
  final int count;
  final bool isCustom;

  const TasbeehPreset({
    required this.name,
    required this.target,
    this.count = 0,
    this.isCustom = false,
  });

  TasbeehPreset copyWith({int? target, int? count}) => TasbeehPreset(
        name: name,
        target: target ?? this.target,
        count: count ?? this.count,
        isCustom: isCustom,
      );

  Map<String, dynamic> toMap() => {
        'target': target,
        'count': count,
        'isCustom': isCustom,
      };

  factory TasbeehPreset.fromMap(String name, Map<dynamic, dynamic> map) =>
      TasbeehPreset(
        name: name,
        target: (map['target'] as num?)?.toInt() ?? 33,
        count: (map['count'] as num?)?.toInt() ?? 0,
        isCustom: map['isCustom'] as bool? ?? false,
      );

  /// The five built-in presets shown on first launch.
  static List<TasbeehPreset> defaults() => const [
        TasbeehPreset(name: 'SubhanAllah', target: 33),
        TasbeehPreset(name: 'Alhamdulillah', target: 33),
        TasbeehPreset(name: 'Allahu Akbar', target: 34),
        TasbeehPreset(name: 'La ilaha illallah', target: 100),
        TasbeehPreset(name: 'Astaghfirullah', target: 100),
      ];
}
