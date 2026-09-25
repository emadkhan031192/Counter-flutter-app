import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/counter_provider.dart';
import '../widgets/tasbeeh_display.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final counter = context.read<CounterProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset count?'),
        content: const Text("Reset current count to 0? This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await counter.resetActive();
    }
  }

  void _showPresetPicker(BuildContext context) {
    final counter = context.read<CounterProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in counter.presets)
              ListTile(
                title: Text(p.name),
                subtitle: Text('Count: ${p.count} / Target: ${p.target}'),
                trailing: p.name == counter.active.name
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  counter.switchPreset(p.name);
                  Navigator.pop(ctx);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add custom dhikr'),
              onTap: () async {
                Navigator.pop(ctx);
                await _showAddCustomDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCustomDialog(BuildContext context) async {
    final counter = context.read<CounterProvider>();
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom dhikr'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Dhikr text'),
              autofocus: true,
            ),
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(labelText: 'Target count'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final target = int.tryParse(targetCtrl.text.trim()) ?? 100;
      await counter.addCustomPreset(nameCtrl.text.trim(), target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zikr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Switch dhikr'),
                onPressed: () => _showPresetPicker(context),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: counter.onScreenTap,
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  child: TasbeehDisplay(preset: counter.active),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmReset(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Reset'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
