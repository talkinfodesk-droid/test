import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/data/mock_data.dart';
import 'package:gpath_tracker/data/workout_repository.dart';
import 'package:gpath_tracker/models/workout_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('seeds demo sessions on first load and persists them', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = WorkoutRepository(prefs: prefs);
    await repo.load();
    expect(repo.isLoaded, isTrue);
    expect(repo.sessions.length, MockData.sessions().length);

    final again = WorkoutRepository(prefs: prefs);
    await again.load();
    expect(again.sessions.length, repo.sessions.length);
  });

  test('saveExercise summarises completed sets and keeps date order', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = WorkoutRepository(prefs: prefs);
    await repo.load();
    final before = repo.sessions.length;

    final exercise = MockData.machinePulldown();
    exercise.sets[2].repVelocities.addAll([0.5, 0.45, 0.4]);
    exercise.sets[2].completed = true;

    final session = await repo.saveExercise(exercise);
    expect(session, isNotNull);
    expect(repo.sessions.length, before + 1);
    expect(repo.latest, session);
    // 60 kg * 9.81 * 0.4 m/s = 235 W for the slowest rep.
    expect(session!.powerMin, closeTo(235.4, 0.5));
    expect(session.gpeMin, lessThanOrEqualTo(session.gpeMean));
    expect(session.gpeMax, greaterThanOrEqualTo(session.gpeMean));

    final reloaded = WorkoutRepository(prefs: prefs);
    await reloaded.load();
    expect(reloaded.sessions.length, before + 1);
    expect(reloaded.latest!.powerMean, closeTo(session.powerMean, 1e-6));
  });

  test('saveExercise returns null when nothing was completed', () async {
    SharedPreferences.setMockInitialValues({});
    final repo =
        WorkoutRepository(prefs: await SharedPreferences.getInstance());
    await repo.load();
    final empty = Exercise(
      name: 'x',
      sets: [WorkoutSet(index: 1, weightKg: 10, targetReps: 5)],
    );
    expect(await repo.saveExercise(empty), isNull);
  });

  test('TrainingSession json round-trips', () {
    final s = MockData.sessions().first;
    final back = TrainingSession.fromJson(s.toJson());
    expect(back.date, s.date);
    expect(back.gpeMean, s.gpeMean);
    expect(back.powerMax, s.powerMax);
  });
}
