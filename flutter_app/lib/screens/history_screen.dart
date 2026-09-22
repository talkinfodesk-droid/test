import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/workout_models.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/gpe_zone_chart.dart';

/// History tab: "GPE Per Training" and "Total Power Per Training" cards.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final sessions = repo.sessions;
    if (!repo.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _HistoryHeader(),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'GPE Per Training',
              highlighted: true,
              info:
                  'GPE is the effort score of a session, derived from how much '
                  'bar velocity dropped across each set. Aim for the Optimal band.',
              child: GpeZoneChart(sessions: sessions),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Total Power Per Training',
              info: 'Mean power (W) of every rep in a session, with the band '
                  'showing the min/max range.',
              child: PowerBandChart(sessions: sessions),
            ),
            const SizedBox(height: 16),
            _SessionList(sessions: sessions.reversed.take(5).toList()),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF3B2A5C),
          child: Icon(Icons.person, size: 20, color: AppColors.purple),
        ),
        const SizedBox(width: 10),
        Text(MockData.userName, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Text('3/12',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              SizedBox(width: 6),
              Icon(Icons.phone_android,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    required this.info,
    this.highlighted = false,
  });

  final String title;
  final Widget child;
  final String info;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.purple : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'What is this?',
                icon: const Icon(Icons.info_outline,
                    size: 20, color: AppColors.textSecondary),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: Text(title),
                    content: Text(info),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent sessions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final s in sessions)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                _Chip(
                  label: GpeZone.forValue(s.gpeMean).label,
                  color: _zoneColor(GpeZone.forValue(s.gpeMean)),
                ),
                const SizedBox(width: 10),
                Text('${s.powerMean.round()} W',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }

  static Color _zoneColor(GpeZone z) => switch (z) {
        GpeZone.tooEasy || GpeZone.overdo => AppColors.red,
        GpeZone.light => AppColors.yellow,
        GpeZone.optimal => AppColors.green,
        GpeZone.heavy => AppColors.orange,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
