import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/workout_models.dart';

/// Drives the live tracking screen: session clock, per-set rest clock, and
/// the stream of reps coming from the (simulated) bar sensor.
class LiveWorkoutController extends ChangeNotifier {
  LiveWorkoutController({required this.exercise, int? initialSetIndex})
      : _random = math.Random(),
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
  }

  final Exercise exercise;
  final math.Random _random;

  Timer? _sessionTimer;
  Timer? _repTimer;

  Duration _elapsed = const Duration(minutes: 2, seconds: 45);
  Duration _setElapsed = Duration.zero;
  DateTime? _setStartedAt;
  int _currentSet;
  bool _sensorConnected = true;
  bool _capturing = false;

  Duration get elapsed => _elapsed;
  Duration get setElapsed => _setElapsed;
  int get currentSetIndex => _currentSet;
  WorkoutSet get currentSet => exercise.sets[_currentSet];
  bool get sensorConnected => _sensorConnected;
  bool get isCapturing => _capturing;

  /// Volume across every rep performed so far (completed sets + live set).
  double get totalVolumeKg =>
      exercise.sets.fold<double>(0, (sum, s) => sum + s.volumeKg);

  int get completedSets => exercise.sets.where((s) => s.completed).length;

  bool get allSetsDone => exercise.sets.every((s) => s.completed);

  void selectSet(int index) {
    if (index < 0 || index >= exercise.sets.length) return;
    _stopCapture();
    _currentSet = index;
    notifyListeners();
  }

  void toggleSensor() {
    _sensorConnected = !_sensorConnected;
    if (!_sensorConnected) _stopCapture();
    notifyListeners();
  }

  /// Start "listening" to the sensor. Reps arrive about every 1.5 s with a
  /// velocity that decays as fatigue builds, until the target is reached.
  void startCapture() {
    if (currentSet.completed || !_sensorConnected || _capturing) return;
    _capturing = true;
    _setStartedAt = DateTime.now();
    _setElapsed = Duration.zero;
    _repTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _detectRep();
    });
    notifyListeners();
  }

  /// Manually log one rep (for demo use without a sensor).
  void addRep() {
    if (currentSet.completed) return;
    _setStartedAt ??= DateTime.now();
    _detectRep();
  }

  void _detectRep() {
    final set = currentSet;
    if (set.completed) {
      _stopCapture();
      return;
    }
    if (set.reps >= set.targetReps) {
      completeCurrentSet();
      return;
    }
    final base = set.repVelocities.isEmpty
        ? 0.36 + _random.nextDouble() * 0.10
        : set.repVelocities.last;
    final jitter = (_random.nextDouble() - 0.55) * 0.06;
    final next = (base + jitter).clamp(0.15, 0.95);
    set.repVelocities.add(double.parse(next.toStringAsFixed(2)));
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
    _repTimer?.cancel();
    _repTimer = null;
    _capturing = false;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _repTimer?.cancel();
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
