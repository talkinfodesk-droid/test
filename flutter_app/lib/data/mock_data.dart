import '../models/workout_models.dart';

/// Demo content that mirrors the numbers visible in the reference recording
/// (Machine pulldown, 3 x 60 kg, sets 1-2 done, set 3 live).
class MockData {
  MockData._();

  static const String userName = 'muscles';

  static Exercise machinePulldown() {
    return Exercise(
      name: 'Machine pulldown',
      muscleGroup: 'Back',
      sets: [
        WorkoutSet(
          index: 1,
          weightKg: 60,
          targetReps: 8,
          repVelocities: const [0.72, 0.70, 0.69, 0.66, 0.63, 0.60, 0.55, 0.50],
          completed: true,
        ),
        WorkoutSet(
          index: 2,
          weightKg: 60,
          targetReps: 8,
          repVelocities: const [0.68, 0.71, 0.69, 0.65, 0.61, 0.64, 0.63, 0.58],
          completed: true,
        ),
        WorkoutSet(index: 3, weightKg: 60, targetReps: 7),
      ],
    );
  }

  static List<Exercise> workoutTemplates() {
    return [
      machinePulldown(),
      Exercise(
        name: 'Bench press',
        muscleGroup: 'Chest',
        sets: [
          WorkoutSet(index: 1, weightKg: 80, targetReps: 5),
          WorkoutSet(index: 2, weightKg: 80, targetReps: 5),
          WorkoutSet(index: 3, weightKg: 80, targetReps: 5),
          WorkoutSet(index: 4, weightKg: 80, targetReps: 5),
        ],
      ),
      Exercise(
        name: 'Back squat',
        muscleGroup: 'Legs',
        sets: [
          WorkoutSet(index: 1, weightKg: 100, targetReps: 5),
          WorkoutSet(index: 2, weightKg: 100, targetReps: 5),
          WorkoutSet(index: 3, weightKg: 100, targetReps: 5),
        ],
      ),
      Exercise(
        name: 'Dumbbell row',
        muscleGroup: 'Back',
        sets: [
          WorkoutSet(index: 1, weightKg: 32, targetReps: 10),
          WorkoutSet(index: 2, weightKg: 32, targetReps: 10),
          WorkoutSet(index: 3, weightKg: 32, targetReps: 10),
        ],
      ),
    ];
  }

  /// Roughly seven months of sessions, Sep -> Mar, like the history charts.
  static List<TrainingSession> sessions() {
    final start = DateTime(2025, 9, 8);
    const gpe = <double>[
      0.55,
      0.9,
      1.1,
      1.5,
      0.95,
      1.05,
      0.6,
      1.2,
      0.85,
      1.0,
      1.25,
      0.95,
      1.1,
      1.02,
      0.98,
      1.15,
      1.3,
      1.08,
      0.92,
      1.0,
      1.12,
      1.35,
      1.05,
      1.18,
      1.5,
      1.22,
    ];
    const power = <double>[
      420,
      560,
      480,
      300,
      510,
      300,
      470,
      450,
      350,
      700,
      380,
      330,
      560,
      450,
      470,
      420,
      380,
      340,
      320,
      600,
      620,
      660,
      580,
      480,
      520,
      300,
    ];
    final out = <TrainingSession>[];
    for (var i = 0; i < gpe.length; i++) {
      final date = start.add(Duration(days: (i * 7.6).round()));
      final spread = 0.15 + (i % 3) * 0.12;
      final pSpread = 60 + (i % 4) * 40;
      out.add(
        TrainingSession(
          date: date,
          gpeMean: gpe[i],
          gpeMin: (gpe[i] - spread).clamp(0, 3),
          gpeMax: (gpe[i] + spread * 1.4).clamp(0, 3),
          powerMean: power[i],
          powerMin: power[i] - pSpread,
          powerMax: power[i] + pSpread,
        ),
      );
    }
    return out;
  }
}
