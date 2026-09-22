import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which bar sensor the athlete paired last.
class SensorPrefs {
  SensorPrefs._();

  static const _deviceKey = 'sensor.lastDeviceId';
  static const _nameKey = 'sensor.lastDeviceName';

  static Future<({String id, String name})?> lastDevice() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_deviceKey);
    if (id == null) return null;
    return (id: id, name: p.getString(_nameKey) ?? id);
  }

  static Future<void> remember(String id, String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_deviceKey, id);
    await p.setString(_nameKey, name);
  }

  static Future<void> forget() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_deviceKey);
    await p.remove(_nameKey);
  }
}
