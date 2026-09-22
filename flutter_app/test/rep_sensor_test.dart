import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/data/mock_data.dart';
import 'package:gpath_tracker/models/workout_models.dart';
import 'package:gpath_tracker/sensors/rep_sensor.dart';
import 'package:gpath_tracker/state/live_workout_controller.dart';

void main() {
  test('simulated sensor streams reps until the target and then disarms', () {
    fakeAsync((async) {
      final sensor = SimulatedRepSensor(interval: const Duration(seconds: 1));
      final seen = <RepEvent>[];
      sensor.reps.listen(seen.add);

      sensor.startSet(targetReps: 3);
      expect(sensor.isArmed, isTrue);
      async.elapse(const Duration(seconds: 5));

      expect(seen.length, 3);
      expect(sensor.isArmed, isFalse);
      for (final r in seen) {
        expect(r.meanVelocity, inInclusiveRange(0.15, 0.95));
      }
      sensor.dispose();
    });
  });

  test('controller completes the set from sensor reps and advances', () {
    fakeAsync((async) {
      final sensor = SimulatedRepSensor(interval: const Duration(seconds: 1));
      final c = LiveWorkoutController(
        exercise: MockData.machinePulldown(),
        sensor: sensor,
      );
      c.startCapture();
      expect(c.isCapturing, isTrue);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      expect(c.exercise.sets[2].completed, isTrue);
      expect(c.exercise.sets[2].reps, 7);
      expect(c.isCapturing, isFalse);
      expect(c.allSetsDone, isTrue);
      c.dispose();
      sensor.dispose();
    });
  });

  test('disconnecting the sensor stops capture', () {
    fakeAsync((async) {
      final sensor = SimulatedRepSensor(interval: const Duration(seconds: 1));
      final c = LiveWorkoutController(
        exercise: MockData.machinePulldown(),
        sensor: sensor,
      );
      c.startCapture();
      async.elapse(const Duration(seconds: 2));
      c.toggleSensor();
      async.flushMicrotasks();
      expect(c.sensorConnected, isFalse);
      expect(c.isCapturing, isFalse);
      final repsAfterDisconnect = c.currentSet.reps;
      async.elapse(const Duration(seconds: 5));
      expect(c.currentSet.reps, repsAfterDisconnect);
      c.dispose();
      sensor.dispose();
    });
  });

  group('set editing', () {
    test('add, update and remove keep numbering consistent', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);

      c.addSet();
      expect(c.exercise.sets.length, 4);
      expect(c.exercise.sets.last.index, 4);
      expect(c.exercise.sets.last.weightKg, 60);

      c.updateSet(3, weightKg: 65, targetReps: 5);
      expect(c.exercise.sets[3].weightKg, 65);
      expect(c.exercise.sets[3].targetReps, 5);

      c.removeSet(2);
      expect(c.exercise.sets.length, 3);
      expect(c.exercise.sets.map((s) => s.index), [1, 2, 3]);
      expect(c.exercise.sets[2].weightKg, 65);
      expect(c.currentSetIndex, 2);
    });

    test('removing a set before the live one keeps the live set selected', () {
      final c = LiveWorkoutController(
        exercise: MockData.machinePulldown(),
        initialSetIndex: 1,
      );
      addTearDown(c.dispose);
      final live = c.currentSet;
      c.removeSet(0);
      expect(c.currentSetIndex, 0);
      expect(c.currentSet.repVelocities, live.repVelocities);
    });

    test('removing the live set moves to the next incomplete set', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      c.addSet();
      expect(c.currentSetIndex, 2);
      c.removeSet(2);
      expect(c.currentSetIndex, 2);
      expect(c.currentSet.completed, isFalse);
      expect(c.currentSet.index, 3);
    });

    test('lowering the target below logged reps completes on start', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      c.addRep();
      c.addRep();
      c.updateSet(2, targetReps: 2);
      c.startCapture();
      expect(c.isCapturing, isFalse);
      expect(c.exercise.sets[2].completed, isTrue);
    });

    test('an exercise with no sets gets one instead of crashing', () {
      final c = LiveWorkoutController(
        exercise: Exercise(name: 'empty', sets: []),
      );
      addTearDown(c.dispose);
      expect(c.exercise.sets.length, 1);
      expect(c.currentSetIndex, 0);
    });

    test('the last remaining set cannot be removed', () {
      final c = LiveWorkoutController(exercise: MockData.machinePulldown());
      addTearDown(c.dispose);
      c.removeSet(0);
      c.removeSet(0);
      expect(c.exercise.sets.length, 1);
      expect(c.canRemoveSet(0), isFalse);
      c.removeSet(0);
      expect(c.exercise.sets.length, 1);
    });
  });
}
