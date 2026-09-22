import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/data/mock_data.dart';
import 'package:gpath_tracker/models/workout_models.dart';
import 'package:gpath_tracker/state/live_workout_controller.dart';

void main() {
  group('WorkoutSet', () {
    test('volume and mean velocity follow the logged reps', () {
      final set = WorkoutSet(
        index: 1,
        weightKg: 60,
        targetReps: 8,
        repVelocities: [0.39, 0.37, 0.43, 0.41],
      );
      expect(set.reps, 4);
      expect(set.volumeKg, 240);
      expect(set.meanVelocity, closeTo(0.40, 0.001));
    });

    test('GPE is only reported for completed sets', () {
      final pending = WorkoutSet(
          index: 1, weightKg: 60, targetReps: 8, repVelocities: [0.7, 0.5]);
      expect(pending.gpe, isNull);
      pending.completed = true;
      expect(pending.gpe, isNotNull);
      expect(pending.gpe, greaterThan(0));
    });
  });

  group('LiveWorkoutController', () {
    test('starts on the first incomplete set with the recorded volume', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      expect(c.currentSetIndex, 2);
      expect(c.totalVolumeKg, 960);
    });

    test('logging reps grows volume and completing advances the set', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      c.addRep();
      c.addRep();
      c.addRep();
      c.addRep();
      expect(c.currentSet.reps, 4);
      expect(c.totalVolumeKg, 1200);
      c.completeCurrentSet();
      expect(c.exercise.sets[2].completed, isTrue);
      expect(c.allSetsDone, isTrue);
    });

    test('undo removes the last rep and never goes negative', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      c.undoRep();
      expect(c.currentSet.reps, 0);
      c.addRep();
      c.undoRep();
      expect(c.currentSet.reps, 0);
    });
  });

  test('formatClock renders hh:mm:ss and m:ss', () {
    const d = Duration(minutes: 2, seconds: 45);
    expect(formatClock(d), '00:02:45');
    expect(formatClock(const Duration(seconds: 7), hours: false), '0:07');
  });
}
