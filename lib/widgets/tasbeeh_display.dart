import 'package:flutter/material.dart';
import '../models/tasbeeh_preset.dart';

class TasbeehDisplay extends StatelessWidget {
  final TasbeehPreset preset;

  const TasbeehDisplay({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reachedTarget = preset.target > 0 && preset.count >= preset.target;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${preset.name} — Target: ${preset.target}',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${preset.count}',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: reachedTarget ? theme.colorScheme.primary : null,
          ),
        ),
        if (reachedTarget)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Target reached — keep going or reset',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }
}
