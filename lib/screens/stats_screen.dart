import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/counter_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _period = 'day';

  static const _labels = {
    'day': 'Day',
    'week': 'Week',
    'month': 'Month',
    'year': 'Year',
  };

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();
    final total = counter.totalFor(_period);
    final history = counter.historyFor(_period);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: _labels.entries
                  .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                  .toList(),
              selected: {_period},
              onSelectionChanged: (sel) => setState(() => _period = sel.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text('This ${_labels[_period]!.toLowerCase()}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('$total',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('No earlier periods yet'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (ctx, i) {
                      final entry = history[i];
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Text('${entry.value}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
