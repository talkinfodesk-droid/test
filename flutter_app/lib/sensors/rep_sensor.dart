import 'dart:async';
import 'dart:math' as math;

/// One repetition detected by the bar sensor.
class RepEvent {
  const RepEvent({required this.meanVelocity, required this.at});

  /// Mean concentric velocity in m/s.
  final double meanVelocity;
  final DateTime at;
}

/// Contract for anything that can feed reps into the live workout screen.
///
/// The production app talks to a Bluetooth bar sensor; a BLE implementation
/// only has to connect, parse the device's notifications into [RepEvent]s and
/// push them on [reps]. The UI never knows the difference.
abstract class RepSensor {
  Stream<RepEvent> get reps;
  Stream<bool> get connectionState;
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();

  /// Called when the athlete starts a set (arms rep detection).
  void startSet({required int targetReps, double? weightKg});

  /// Called when the set is completed or abandoned.
  void stopSet();

  Future<void> dispose();
}

/// Demo sensor: emits a rep every [interval] with a velocity that decays as
/// fatigue builds, until the target rep count is reached.
class SimulatedRepSensor implements RepSensor {
  SimulatedRepSensor({
    this.interval = const Duration(milliseconds: 1500),
    math.Random? random,
    bool connected = true,
  })  : _random = random ?? math.Random(),
        _connected = connected;

  final Duration interval;
  final math.Random _random;

  final _reps = StreamController<RepEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();

  bool _connected;
  Timer? _timer;
  int _emitted = 0;
  int _target = 0;
  double? _last;

  @override
  Stream<RepEvent> get reps => _reps.stream;

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  bool get isConnected => _connected;

  bool get isArmed => _timer != null;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    _connection.add(true);
  }

  @override
  Future<void> disconnect() async {
    stopSet();
    if (!_connected) return;
    _connected = false;
    _connection.add(false);
  }

  @override
  void startSet({required int targetReps, double? weightKg}) {
    if (!_connected || _timer != null) return;
    _target = targetReps;
    _emitted = 0;
    _last = null;
    _timer = Timer.periodic(interval, (_) => emitRep());
  }

  /// Next plausible velocity: starts around 0.4 m/s and drifts down.
  /// Pure sampling, nothing is emitted (used by the manual "+" button).
  double sampleVelocity() {
    final base = _last ?? (0.36 + _random.nextDouble() * 0.10);
    final jitter = (_random.nextDouble() - 0.55) * 0.06;
    final v =
        double.parse((base + jitter).clamp(0.15, 0.95).toStringAsFixed(2));
    _last = v;
    return v;
  }

  /// Emit one rep on the stream right now.
  void emitRep() {
    if (!_connected) return;
    _emitted++;
    _reps.add(RepEvent(meanVelocity: sampleVelocity(), at: DateTime.now()));
    if (_target > 0 && _emitted >= _target) stopSet();
  }

  @override
  void stopSet() {
    _timer?.cancel();
    _timer = null;
    _target = 0;
  }

  @override
  Future<void> dispose() async {
    stopSet();
    await _reps.close();
    await _connection.close();
  }
}
