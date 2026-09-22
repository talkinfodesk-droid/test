import 'dart:math' as math;

/// One planned/performed set of an exercise.
class WorkoutSet {
  WorkoutSet({
    required this.index,
    required this.weightKg,
    required this.targetReps,
    List<double>? repVelocities,
    this.completed = false,
  }) : repVelocities = repVelocities ?? <double>[];

  /// 1-based set number as shown in the UI.
  final int index;
  final double weightKg;
  final int targetReps;

  /// Mean concentric velocity (m/s) of every detected rep, in order.
  final List<double> repVelocities;
  bool completed;

  int get reps => repVelocities.length;

  double get volumeKg => weightKg * reps;

  double get meanVelocity {
    if (repVelocities.isEmpty) return 0;
    final sum = repVelocities.fold<double>(0, (a, b) => a + b);
    return sum / repVelocities.length;
  }

  /// "GPE" is the app's effort score for a set. We derive it from the
  /// velocity loss between the fastest and the last rep: a bigger drop means
  /// the set was closer to failure. Only available once the set is completed.
  double? get gpe {
    if (!completed || repVelocities.length < 2) return null;
    final fastest = repVelocities.reduce(math.max);
    final last = repVelocities.last;
    if (fastest <= 0) return null;
    final loss = (fastest - last) / fastest; // 0..1
    return (loss * 4).clamp(0, 3.0);
  }

  WorkoutSet copyWith({
    int? index,
    double? weightKg,
    int? targetReps,
    List<double>? repVelocities,
    bool? completed,
  }) {
    return WorkoutSet(
      index: index ?? this.index,
      weightKg: weightKg ?? this.weightKg,
      targetReps: targetReps ?? this.targetReps,
      repVelocities: repVelocities ?? List<double>.from(this.repVelocities),
      completed: completed ?? this.completed,
    );
  }
}

class Exercise {
  Exercise({
    required this.name,
    required this.sets,
    this.muscleGroup = '',
  });

  final String name;
  final String muscleGroup;
  final List<WorkoutSet> sets;

  int get setCount => sets.length;
}

/// A single training session used in the history charts.
class TrainingSession {
  const TrainingSession({
    required this.date,
    required this.gpeMean,
    required this.gpeMin,
    required this.gpeMax,
    required this.powerMean,
    required this.powerMin,
    required this.powerMax,
  });

  final DateTime date;
  final double gpeMean;
  final double gpeMin;
  final double gpeMax;
  final double powerMean;
  final double powerMin;
  final double powerMax;
}

/// Effort zones drawn as horizontal bands on the GPE chart.
enum GpeZone {
  tooEasy('Too easy', 0.0, 0.4),
  light('Light', 0.4, 0.8),
  optimal('Optimal', 0.8, 1.4),
  heavy('Heavy', 1.4, 2.0),
  overdo('Overdo', 2.0, 3.0);

  const GpeZone(this.label, this.from, this.to);

  final String label;
  final double from;
  final double to;

  static GpeZone forValue(double gpe) {
    for (final zone in GpeZone.values) {
      if (gpe < zone.to) return zone;
    }
    return GpeZone.overdo;
  }
}
