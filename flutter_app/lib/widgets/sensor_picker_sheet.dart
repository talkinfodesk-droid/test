import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../sensors/ble_rep_sensor.dart';
import '../sensors/rep_sensor.dart';
import '../state/live_workout_controller.dart';
import '../state/sensor_prefs.dart';
import '../theme/app_theme.dart';

/// Pick the rep source for the live screen: the built-in simulator or a
/// nearby ESP32-S3 bar sensor found over BLE.
Future<void> showSensorPickerSheet(
  BuildContext context,
  LiveWorkoutController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SensorPickerSheet(controller: controller),
  );
}

class _SensorPickerSheet extends StatefulWidget {
  const _SensorPickerSheet({required this.controller});

  final LiveWorkoutController controller;

  @override
  State<_SensorPickerSheet> createState() => _SensorPickerSheetState();
}

class _SensorPickerSheetState extends State<_SensorPickerSheet> {
  StreamSubscription<BleDevice>? _scanSub;
  StreamSubscription<AvailabilityState>? _availSub;
  Timer? _scanTimer;

  /// Keyed by device id so repeated advertisements update in place.
  final Map<String, BleDevice> _found = {};
  bool _scanning = false;
  bool _busy = false;
  String? _error;
  AvailabilityState _adapter = AvailabilityState.unknown;
  String? _lastDeviceId;

  static const _scanDuration = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    SensorPrefs.lastDevice().then((d) {
      if (mounted) setState(() => _lastDeviceId = d?.id);
    });
    _scanSub = BleSensorScanner.results.listen((d) {
      if (mounted) setState(() => _found[d.deviceId] = d);
    });
    _availSub = BleSensorScanner.availability.listen((s) {
      if (!mounted) return;
      setState(() => _adapter = s);
      if (s == AvailabilityState.poweredOn && !_scanning) _startScan();
    });
    BleSensorScanner.currentAvailability().then((s) {
      if (!mounted) return;
      setState(() => _adapter = s);
      if (s == AvailabilityState.poweredOn) _startScan();
    }).catchError((Object e) {
      if (mounted) setState(() => _error = 'Bluetooth unavailable: $e');
    });
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() {
      _error = null;
      _scanning = true;
      _found.clear();
    });
    try {
      await BleSensorScanner.requestPermissions();
      await BleSensorScanner.start();
      _scanTimer?.cancel();
      _scanTimer = Timer(_scanDuration, _stopScan);
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = 'Scan failed: $e';
        });
      }
    }
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      await BleSensorScanner.stop();
    } catch (_) {}
    if (mounted) setState(() => _scanning = false);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _availSub?.cancel();
    _scanTimer?.cancel();
    BleSensorScanner.stop().catchError((_) {});
    super.dispose();
  }

  Future<void> _useSimulator() async {
    setState(() => _busy = true);
    await widget.controller.setSensor(SimulatedRepSensor());
    await SensorPrefs.forget();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pair(BleDevice d) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await _stopScan();
    final sensor = BleRepSensor(deviceId: d.deviceId, name: d.name);
    try {
      await sensor.connect();
      await widget.controller.setSensor(sensor);
      await SensorPrefs.remember(d.deviceId, sensor.name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      await sensor.dispose();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not connect: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.sensor;
    final usingSim = current is SimulatedRepSensor;
    final bleName = current is BleRepSensor ? current.name : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Bar sensor',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (_scanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Scan again',
                  onPressed: _busy ? null : _startScan,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bleName != null
                ? 'Connected to $bleName'
                : 'Using the built-in simulator',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Option(
            icon: Icons.memory,
            title: 'Simulator (demo)',
            subtitle: 'Fake reps every 1.5 s',
            selected: usingSim,
            onTap: _busy || usingSim ? null : _useSimulator,
          ),
          const SizedBox(height: 8),
          if (_adapter == AvailabilityState.poweredOff)
            const _Note('Bluetooth is off. Turn it on to find the sensor.')
          else if (_adapter == AvailabilityState.unsupported)
            const _Note('This device has no Bluetooth LE.')
          else if (_found.isEmpty)
            _Note(_scanning
                ? 'Looking for GPATH boards…'
                : 'No sensor found. Power the ESP32-S3 board and scan again.')
          else
            for (final d in _found.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Option(
                  icon: Icons.bluetooth,
                  title: (d.name?.isNotEmpty ?? false) ? d.name! : d.deviceId,
                  subtitle:
                      '${d.rssi ?? '?'} dBm${d.deviceId == _lastDeviceId ? ' · last used' : ''}',
                  selected:
                      current is BleRepSensor && current.deviceId == d.deviceId,
                  onTap: _busy ? null : () => _pair(d),
                ),
              ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.greenDim : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.green : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? AppColors.green : AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.green),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
