import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/sensors/gpath_protocol.dart';

/// The GATT contract lives in two places on purpose (Dart + Arduino). This
/// guards against the two drifting apart.
void main() {
  final ino = File('../firmware/gpath_bar_sensor/gpath_bar_sensor.ino');

  test('firmware sketch uses the same UUIDs and command codes', () {
    if (!ino.existsSync()) {
      markTestSkipped('firmware sketch not checked out next to flutter_app');
      return;
    }
    final src = ino.readAsStringSync();

    String define(String name) {
      final m = RegExp('$name = "([0-9a-f-]+)"').firstMatch(src);
      expect(m, isNotNull, reason: '$name missing from sketch');
      return m!.group(1)!;
    }

    expect(define('SERVICE_UUID'), GpathProtocol.serviceUuid);
    expect(define('REP_CHAR_UUID'), GpathProtocol.repCharUuid);
    expect(define('CTRL_CHAR_UUID'), GpathProtocol.controlCharUuid);

    int code(String name) {
      final m = RegExp('$name = 0x([0-9A-Fa-f]+)').firstMatch(src);
      expect(m, isNotNull, reason: '$name missing from sketch');
      return int.parse(m!.group(1)!, radix: 16);
    }

    expect(code('CMD_START'), GpathProtocol.cmdStartSet);
    expect(code('CMD_STOP'), GpathProtocol.cmdStopSet);
    expect(code('CMD_TARE'), GpathProtocol.cmdTare);
    expect(code('PKT_REP'), GpathProtocol.repPacketType);
    expect(
      RegExp(r'uint8_t pkt\[(\d+)\]').firstMatch(src)?.group(1),
      '${GpathProtocol.repPacketLength}',
    );
  });
}
