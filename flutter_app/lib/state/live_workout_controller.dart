import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_models.dart';
import '../sensors/rep_sensor.dart';

/// Drives the live tracking screen: session clock, per-set clock, the rep
/// stream from the bar sensor, and set editing.
class LiveWorkoutController extends ChangeNotifier {
  LiveWorkoutController({
    required this.exercise,
    RepSensor? sensor,
    int? initialSetIndex,
    Duration initialElapsed = const Duration(minutes: 2, seconds: 45),
  })  : _ownsSensor = sensor == null,
        sensor = sensor ?? SimulatedRepSensor(),
        _elapsed = initialElapsed,
        _currentSet = initialSetIndex ??
            exercise.sets
                .indexWhere((s) => !s.completed)
                .clamp(0, exercise.sets.length - 1) {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      if (_setStartedAt != null) {
        _setElapsed = DateTime.now().difference(_setStartedAt!);
      }
      notifyListeners();
    });
    _repSub = this.sensor.reps.listen(_onRep);
    _connSub = this.sensor.connectionState.listen((_) {
      if (!this.sensor.isConnected) _stopCapture();
      notifyListeners();
    });
  }

  final Exercise exercise;
  final RepSensor sensor;
  final bool _ownsSensor;

  Timer? _sessionTimer;
  StreamSubscription<RepEvent>? _repSub;
  StreamSubscription<bool>? _connSub;

  Duration _elapsed;
  Duration _setElapsed = Duration.zero;
  DateTime? _setStartedAt;
  int _currentSet;
  bool _capturing = false;

  Duration get elapsed => _elapsed;
  Duration get setElapsed => _setElapsed;
  int get currentSetIndex => _currentSet;
  WorkoutSet get currentSet => exercise.sets[_currentSet];
  bool get sensorConnected => sensor.isConnected;
  bool get isCapturing => _capturing;

  /// Volume across every rep performed so far (completed sets + live set).
  double get totalVolumeKg =>
      exercise.sets.fold<double>(0, (sum, s) => sum + s.volumeKg);

  int get completedSets => exercise.sets.where((s) => s.completed).length;

  bool get allSetsDone => exercise.sets.every((s) => s.completed);

  // ---------------------------------------------------------------- sets

  void selectSet(int index) {
    if (index < 0 || index >= exercise.sets.length) return;
    _stopCapture();
    _currentSet = index;
    notifyListeners();
  }

  void addSet({double? weightKg, int? targetReps}) {
    exercise.addSet(weightKg: weightKg, targetReps: targetReps);
    if (allSetsDoneExceptLast) _currentSet = exercise.sets.length - 1;
    notifyListeners();
  }

  bool get allSetsDoneExceptLast =>
      exercise.sets.take(exercise.sets.length - 1).every((s) => s.completed);

  void updateSet(int index, {double? weightKg, int? targetReps}) {
    if (index < 0 || index >= exercise.sets.length) return;
    exercise.updateSet(index, weightKg: weightKg, targetReps: targetReps);
    notifyListeners();
  }

  /// Sets can be removed while there is more than one and it isn't live.
  bool canRemoveSet(int index) =>
      exercise.sets.length > 1 && !(index == _currentSet && _capturing);

  void removeSet(int index) {
    if (!canRemoveSet(index)) return;
    exercise.removeSetAt(index);
    if (_currentSet >= exercise.sets.length) {
      _currentSet = exercise.sets.length - 1;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- sensor

  Future<void> toggleSensor() async {
    if (sensor.isConnected) {
      await sensor.disconnect();
    } else {
      await sensor.connect();
    }
    notifyListeners();
  }

  /// Arm the sensor for the current set.
  void startCapture() {
    if (currentSet.completed || !sensor.isConnected || _capturing) return;
    _capturing = true;
    _setStartedAt = DateTime.now();
    _setElapsed = Duration.zero;
    sensor.startSet(
      targetReps: currentSet.targetReps - currentSet.reps,
      weightKg: currentSet.weightKg,
    );
    notifyListeners();
  }

  /// Manually log one rep (demo without a sensor).
  void addRep() {
    if (currentSet.completed) return;
    _setStartedAt ??= DateTime.now();
    final s = sensor;
    final v = s is SimulatedRepSensor ? s.sampleVelocity() : 0.4;
    _onRep(RepEvent(meanVelocity: v, at: DateTime.now()));
  }

  void _onRep(RepEvent event) {
    final set = currentSet;
    if (set.completed) return;
    set.repVelocities.add(event.meanVelocity);
    if (set.reps >= set.targetReps) completeCurrentSet();
    notifyListeners();
  }

  void undoRep() {
    final set = currentSet;
    if (set.completed || set.repVelocities.isEmpty) return;
    set.repVelocities.removeLast();
    notifyListeners();
  }

  void completeCurrentSet() {
    final set = currentSet;
    if (set.repVelocities.isEmpty) return;
    set.completed = true;
    _stopCapture();
    final next = exercise.sets.indexWhere((s) => !s.completed);
    if (next != -1) _currentSet = next;
    notifyListeners();
  }

  void _stopCapture() {
    sensor.stopSet();
    _capturing = false;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _repSub?.cancel();
    _connSub?.cancel();
    if (_ownsSensor) sensor.dispose();
    super.dispose();
  }
}

String formatClock(Duration d, {bool hours = true}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (hours) return '${two(h)}:${two(m)}:${two(s)}';
  return '$m:${two(s)}';
}
