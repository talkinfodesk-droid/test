import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/workout_models.dart';
import '../theme/app_theme.dart';
import 'live_workout_screen.dart';

/// Workouts tab: pick an exercise template and start tracking it live.
class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late final List<Exercise> templates = MockData.workoutTemplates();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ExerciseTile(exercise: templates[i]),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final first = exercise.sets.first;
    final done = exercise.sets.where((s) => s.completed).length;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => LiveWorkoutScreen(exercise: exercise)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.muscleGroup} · ${exercise.setCount} × ${first.targetReps} @ ${first.weightKg.toInt()} kg'
                      '${done > 0 ? ' · $done done' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill,
                  color: AppColors.green, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
