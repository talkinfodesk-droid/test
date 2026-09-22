import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'gpath_protocol.dart';
import 'rep_sensor.dart';

/// [RepSensor] backed by the ESP32-S3 bar sensor over BLE.
///
/// Lifecycle: `connect()` -> discover the GPath service -> subscribe to rep
/// notifications. `startSet()` writes a START command so the firmware arms rep
/// detection; every notification becomes a [RepEvent].
///
/// flutter_blue_plus 2.x is free for personal / nonprofit use and needs a
/// commercial license otherwise (see its LICENSE). Everything here sits behind
/// [RepSensor], so swapping the BLE library touches only this file.
class BleRepSensor implements RepSensor {
  BleRepSensor(this.device, {this.license = License.nonprofit});

  final BluetoothDevice device;
  final License license;

  final _reps = StreamController<RepEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();

  BluetoothCharacteristic? _repChar;
  BluetoothCharacteristic? _controlChar;
  StreamSubscription<List<int>>? _repSub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  bool _connected = false;

  /// Whether the next set's concentric phase comes first (pulldown / row).
  bool concentricFirst = false;

  String get name => device.platformName.isNotEmpty
      ? device.platformName
      : device.advName.isNotEmpty
          ? device.advName
          : device.remoteId.str;

  @override
  Stream<RepEvent> get reps => _reps.stream;

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    await device.connect(
        license: license, timeout: const Duration(seconds: 15));

    _stateSub ??= device.connectionState.listen((state) {
      final now = state == BluetoothConnectionState.connected;
      if (now != _connected) {
        _connected = now;
        if (!now) {
          _repSub?.cancel();
          _repSub = null;
          _repChar = null;
          _controlChar = null;
        }
        _connection.add(now);
      }
    });

    final services = await device.discoverServices();
    final service = services.cast<BluetoothService?>().firstWhere(
          (s) => s!.uuid == Guid(GpathProtocol.serviceUuid),
          orElse: () => null,
        );
    if (service == null) {
      await device.disconnect();
      throw StateError('Device does not expose the GPath service');
    }
    for (final c in service.characteristics) {
      if (c.uuid == Guid(GpathProtocol.repCharUuid)) _repChar = c;
      if (c.uuid == Guid(GpathProtocol.controlCharUuid)) _controlChar = c;
    }
    if (_repChar == null || _controlChar == null) {
      await device.disconnect();
      throw StateError('GPath service is missing a characteristic');
    }

    await _repChar!.setNotifyValue(true);
    _repSub = _repChar!.onValueReceived.listen(_onNotification);

    if (!_connected) {
      _connected = true;
      _connection.add(true);
    }
  }

  void _onNotification(List<int> bytes) {
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
    await device.disconnect();
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

  Future<void> _write(List<int> bytes, {bool quiet = false}) async {
    final c = _controlChar;
    if (c == null || !_connected) return;
    try {
      await c.write(bytes, withoutResponse: c.properties.writeWithoutResponse);
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
        await device.disconnect();
      } catch (_) {}
    }
    await _reps.close();
    await _connection.close();
  }
}

/// Scans for boards advertising the GPath service.
class BleSensorScanner {
  BleSensorScanner._();

  static Stream<List<ScanResult>> get results => FlutterBluePlus.scanResults;
  static Stream<bool> get isScanning => FlutterBluePlus.isScanning;
  static Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  static Future<void> start({Duration timeout = const Duration(seconds: 8)}) {
    return FlutterBluePlus.startScan(
      withServices: [Guid(GpathProtocol.serviceUuid)],
      timeout: timeout,
      androidUsesFineLocation: false,
    );
  }

  static Future<void> stop() => FlutterBluePlus.stopScan();
}
