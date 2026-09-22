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

  /// Append a new set, copying the weight/reps of the last one by default.
  WorkoutSet addSet({double? weightKg, int? targetReps}) {
    final last = sets.isEmpty ? null : sets.last;
    final set = WorkoutSet(
      index: sets.length + 1,
      weightKg: weightKg ?? last?.weightKg ?? 20,
      targetReps: targetReps ?? last?.targetReps ?? 8,
    );
    sets.add(set);
    return set;
  }

  /// Remove a set and renumber the ones after it.
  void removeSetAt(int index) {
    sets.removeAt(index);
    for (var i = 0; i < sets.length; i++) {
      sets[i] = sets[i].copyWith(index: i + 1);
    }
  }

  /// Change weight / target reps of a set. Logged reps are kept.
  void updateSet(int index, {double? weightKg, int? targetReps}) {
    sets[index] = sets[index].copyWith(
      weightKg: weightKg,
      targetReps: targetReps,
    );
  }
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

  /// Standard gravity, used to turn kg x m/s into watts.
  static const double _g = 9.81;

  /// Summarise a finished exercise into one history point.
  /// Power per rep = weight x g x mean velocity; GPE comes from each set.
  static TrainingSession? fromExercise(Exercise exercise, {DateTime? date}) {
    final done = exercise.sets.where((s) => s.completed && s.reps > 0).toList();
    if (done.isEmpty) return null;

    final gpes = done.map((s) => s.gpe ?? 0).toList();
    final powers = <double>[
      for (final s in done)
        for (final v in s.repVelocities) s.weightKg * _g * v,
    ];

    double mean(List<double> xs) =>
        xs.fold<double>(0, (a, b) => a + b) / xs.length;

    return TrainingSession(
      date: date ?? DateTime.now(),
      gpeMean: mean(gpes),
      gpeMin: gpes.reduce(math.min),
      gpeMax: gpes.reduce(math.max),
      powerMean: mean(powers),
      powerMin: powers.reduce(math.min),
      powerMax: powers.reduce(math.max),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'gpeMean': gpeMean,
        'gpeMin': gpeMin,
        'gpeMax': gpeMax,
        'powerMean': powerMean,
        'powerMin': powerMin,
        'powerMax': powerMax,
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num).toDouble();
    return TrainingSession(
      date: DateTime.parse(json['date'] as String),
      gpeMean: d('gpeMean'),
      gpeMin: d('gpeMin'),
      gpeMax: d('gpeMax'),
      powerMean: d('powerMean'),
      powerMin: d('powerMin'),
      powerMax: d('powerMax'),
    );
  }
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
