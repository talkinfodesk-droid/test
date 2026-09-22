import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/device_ring.dart';
import 'live_workout_screen.dart';

/// Home tab: greeting, sensor status, a "continue workout" card that opens
/// the live tracking screen, and a few quick stats.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = MockData.sessions();
    final last = sessions.last;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF3B2A5C),
                  child: Icon(Icons.person, color: AppColors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey, ${MockData.userName}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Sensor connected · ready to lift',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const DeviceRing(connected: true),
              ],
            ),
            const SizedBox(height: 24),
            _ContinueCard(
              onStart: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LiveWorkoutScreen(exercise: MockData.machinePulldown()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Last GPE',
                    value: last.gpeMean.toStringAsFixed(1),
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Last power',
                    value: '${last.powerMean.round()} W',
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Sessions',
                    value: '${sessions.length}',
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF14311D), AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In progress', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text('Machine pulldown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('2 of 3 sets done · 60 kg',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continue workout'),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
