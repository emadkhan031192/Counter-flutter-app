import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/counter_provider.dart';
import '../services/native_bridge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Volume button counting'),
          SwitchListTile(
            title: const Text('Count with volume button'),
            subtitle: const Text(
                'Counts even with the screen off, in your pocket. The other volume button still adjusts media volume normally.'),
            value: counter.volumeButtonEnabled,
            onChanged: (v) async {
              await counter.setVolumeCounting(v, counter.volumeButtonKey);
              if (v) {
                final granted =
                    await NativeBridge.instance.isAccessibilityServiceEnabled();
                if (!granted && context.mounted) {
                  await _promptAccessibility(context);
                }
              }
              setState(() {});
            },
          ),
          if (counter.volumeButtonEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'up', label: Text('Volume Up')),
                  ButtonSegment(value: 'down', label: Text('Volume Down')),
                ],
                selected: {counter.volumeButtonKey},
                onSelectionChanged: (sel) =>
                    counter.setVolumeCounting(true, sel.first),
              ),
            ),
          const Divider(),
          const _SectionHeader('Daily reminder'),
          SwitchListTile(
            title: const Text('Remind me to do dhikr'),
            value: counter.reminderEnabled,
            onChanged: (v) => counter.setReminder(
                v, TimeOfDay(hour: counter.reminderHour, minute: counter.reminderMinute)),
          ),
          if (counter.reminderEnabled)
            ListTile(
              title: const Text('Reminder time'),
              subtitle: Text(TimeOfDay(
                      hour: counter.reminderHour, minute: counter.reminderMinute)
                  .format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                      hour: counter.reminderHour, minute: counter.reminderMinute),
                );
                if (picked != null) {
                  await counter.setReminder(true, picked);
                }
              },
            ),
          const Divider(),
          const _SectionHeader('Presets'),
          for (final p in counter.presets)
            ListTile(
              title: Text(p.name),
              subtitle: Text('Target: ${p.target}'),
              trailing: p.isCustom
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => counter.deletePreset(p.name),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Future<void> _promptAccessibility(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('One more step'),
        content: const Text(
            'To count while the screen is off, Zikr needs the Accessibility permission enabled once. Open settings and turn on "Zikr" under Installed apps / Downloaded apps.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              NativeBridge.instance.openAccessibilitySettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
