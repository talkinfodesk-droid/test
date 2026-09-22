import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'gpath_protocol.dart';
import 'rep_sensor.dart';

/// [RepSensor] backed by the ESP32-S3 bar sensor over BLE.
///
/// Lifecycle: `connect()` -> discover the GPath service -> subscribe to rep
/// notifications. `startSet()` writes a START command so the firmware arms rep
/// detection; every notification becomes a [RepEvent].
///
/// Uses `universal_ble` (BSD-3-Clause, free for commercial use). Everything
/// here sits behind [RepSensor], so swapping the BLE library touches only
/// this file.
class BleRepSensor implements RepSensor {
  BleRepSensor({required this.deviceId, String? name}) : _name = name;

  final String deviceId;
  final String? _name;

  final _reps = StreamController<RepEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();

  StreamSubscription<Uint8List>? _repSub;
  StreamSubscription<bool>? _stateSub;
  bool _connected = false;
  bool _controlWithoutResponse = false;

  /// Whether the next set's concentric phase comes first (pulldown / row).
  bool concentricFirst = false;

  String get name => (_name != null && _name.isNotEmpty) ? _name : deviceId;

  @override
  Stream<RepEvent> get reps => _reps.stream;

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 15));

    _stateSub ??= UniversalBle.connectionStream(deviceId).listen(_onState);

    final services = await UniversalBle.discoverServices(deviceId);
    final service = services
        .where((s) => _sameUuid(s.uuid, GpathProtocol.serviceUuid))
        .firstOrNull;
    if (service == null) {
      await UniversalBle.disconnect(deviceId);
      throw StateError('Device does not expose the GPath service');
    }
    BleCharacteristic? repChar;
    BleCharacteristic? controlChar;
    for (final c in service.characteristics) {
      if (_sameUuid(c.uuid, GpathProtocol.repCharUuid)) repChar = c;
      if (_sameUuid(c.uuid, GpathProtocol.controlCharUuid)) controlChar = c;
    }
    if (repChar == null || controlChar == null) {
      await UniversalBle.disconnect(deviceId);
      throw StateError('GPath service is missing a characteristic');
    }
    _controlWithoutResponse = controlChar.properties
        .contains(CharacteristicProperty.writeWithoutResponse);

    _repSub = UniversalBle.characteristicValueStream(deviceId, repChar.uuid)
        .listen(_onNotification);
    await UniversalBle.subscribeNotifications(
      deviceId,
      service.uuid,
      repChar.uuid,
    );

    _onState(true);
  }

  void _onState(bool connected) {
    if (connected == _connected) return;
    _connected = connected;
    if (!connected) {
      _repSub?.cancel();
      _repSub = null;
    }
    _connection.add(connected);
  }

  void _onNotification(Uint8List bytes) {
    final packet = RepPacket.decode(bytes);
    if (packet == null) {
      debugPrint('BleRepSensor: ignoring ${bytes.length}-byte packet');
      return;
    }
    _reps.add(RepEvent(meanVelocity: packet.meanVelocity, at: DateTime.now()));
  }

  @override
  Future<void> disconnect() async {
    await _write(ControlPacket.stopSet(), quiet: true);
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (e) {
      debugPrint('BleRepSensor: disconnect failed: $e');
    }
    _onState(false);
  }

  @override
  void startSet({required int targetReps, double? weightKg}) {
    _write(
      ControlPacket.startSet(
        targetReps: targetReps,
        weightKg: weightKg ?? 0,
        concentricFirst: concentricFirst,
      ),
    );
  }

  @override
  void stopSet() {
    _write(ControlPacket.stopSet(), quiet: true);
  }

  Future<void> tare() => _write(ControlPacket.tare());

  Future<void> _write(Uint8List bytes, {bool quiet = false}) async {
    if (!_connected) return;
    try {
      await UniversalBle.write(
        deviceId,
        GpathProtocol.serviceUuid,
        GpathProtocol.controlCharUuid,
        bytes,
        withoutResponse: _controlWithoutResponse,
      );
    } catch (e) {
      if (!quiet) debugPrint('BleRepSensor: write failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _repSub?.cancel();
    await _stateSub?.cancel();
    if (_connected) {
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {}
    }
    await _reps.close();
    await _connection.close();
  }

  static bool _sameUuid(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();
}

/// Scans for boards advertising the GPath service.
class BleSensorScanner {
  BleSensorScanner._();

  static Stream<BleDevice> get results => UniversalBle.scanStream;
  static Stream<AvailabilityState> get availability =>
      UniversalBle.availabilityStream;

  static Future<AvailabilityState> currentAvailability() =>
      UniversalBle.getBluetoothAvailabilityState();

  /// Asks for the runtime BLE permissions (Android 12+ scan/connect).
  static Future<void> requestPermissions() => UniversalBle.requestPermissions();

  static Future<void> start() {
    return UniversalBle.startScan(
      scanFilter: ScanFilter(
        withServices: [GpathProtocol.serviceUuid],
        withNamePrefix: [GpathProtocol.deviceNamePrefix],
      ),
    );
  }

  static Future<void> stop() => UniversalBle.stopScan();
}
