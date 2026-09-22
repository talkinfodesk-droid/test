import 'dart:typed_data';

/// BLE GATT contract shared with `firmware/gpath_bar_sensor`.
///
/// One primary service with two characteristics:
///  * [repCharUuid]     NOTIFY  - one packet per detected rep ([RepPacket])
///  * [controlCharUuid] WRITE   - start / stop a set ([ControlPacket])
///
/// All multi-byte integers are little-endian.
class GpathProtocol {
  GpathProtocol._();

  static const String serviceUuid = '7a0c0001-5d8e-4b1f-9c3a-2f1b8e6d4a01';
  static const String repCharUuid = '7a0c0002-5d8e-4b1f-9c3a-2f1b8e6d4a01';
  static const String controlCharUuid = '7a0c0003-5d8e-4b1f-9c3a-2f1b8e6d4a01';

  /// Advertised local name prefix; the picker filters on this too.
  static const String deviceNamePrefix = 'GPATH';

  static const int repPacketType = 0x01;
  static const int repPacketLength = 12;

  static const int cmdStartSet = 0x01;
  static const int cmdStopSet = 0x02;
  static const int cmdTare = 0x03;
}

/// Rep notification, 12 bytes:
/// ```
/// 0      type (0x01)
/// 1      rep index in the set, 1-based
/// 2..3   mean concentric velocity, mm/s
/// 4..5   peak concentric velocity, mm/s
/// 6..7   range of motion, mm
/// 8..11  ms since the set was started
/// ```
class RepPacket {
  const RepPacket({
    required this.repIndex,
    required this.meanVelocity,
    required this.peakVelocity,
    required this.rangeOfMotionM,
    required this.sinceSetStart,
  });

  final int repIndex;

  /// m/s
  final double meanVelocity;

  /// m/s
  final double peakVelocity;

  /// metres
  final double rangeOfMotionM;
  final Duration sinceSetStart;

  static RepPacket? decode(List<int> bytes) {
    if (bytes.length < GpathProtocol.repPacketLength) return null;
    if (bytes[0] != GpathProtocol.repPacketType) return null;
    final b = ByteData.sublistView(Uint8List.fromList(bytes));
    return RepPacket(
      repIndex: b.getUint8(1),
      meanVelocity: b.getUint16(2, Endian.little) / 1000,
      peakVelocity: b.getUint16(4, Endian.little) / 1000,
      rangeOfMotionM: b.getUint16(6, Endian.little) / 1000,
      sinceSetStart: Duration(milliseconds: b.getUint32(8, Endian.little)),
    );
  }

  Uint8List encode() {
    final b = ByteData(GpathProtocol.repPacketLength)
      ..setUint8(0, GpathProtocol.repPacketType)
      ..setUint8(1, repIndex.clamp(0, 255))
      ..setUint16(
          2, (meanVelocity * 1000).round().clamp(0, 65535), Endian.little)
      ..setUint16(
          4, (peakVelocity * 1000).round().clamp(0, 65535), Endian.little)
      ..setUint16(
          6, (rangeOfMotionM * 1000).round().clamp(0, 65535), Endian.little)
      ..setUint32(
          8, sinceSetStart.inMilliseconds.clamp(0, 0xFFFFFFFF), Endian.little);
    return b.buffer.asUint8List();
  }
}

/// Commands written to the control characteristic.
class ControlPacket {
  ControlPacket._();

  /// ```
  /// 0     0x01
  /// 1     target reps (0 = unlimited)
  /// 2..3  load, kg x 10
  /// 4     1 if the concentric phase comes first (pulldown, row), else 0
  /// ```
  static Uint8List startSet({
    required int targetReps,
    required double weightKg,
    required bool concentricFirst,
  }) {
    final b = ByteData(5)
      ..setUint8(0, GpathProtocol.cmdStartSet)
      ..setUint8(1, targetReps.clamp(0, 255))
      ..setUint16(2, (weightKg * 10).round().clamp(0, 65535), Endian.little)
      ..setUint8(4, concentricFirst ? 1 : 0);
    return b.buffer.asUint8List();
  }

  static Uint8List stopSet() => Uint8List.fromList([GpathProtocol.cmdStopSet]);

  /// Re-zero the IMU while the bar is at rest.
  static Uint8List tare() => Uint8List.fromList([GpathProtocol.cmdTare]);
}
