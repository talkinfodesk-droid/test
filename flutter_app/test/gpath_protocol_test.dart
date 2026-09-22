import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/sensors/gpath_protocol.dart';

void main() {
  test('rep packet encodes to 12 little-endian bytes and decodes back', () {
    const p = RepPacket(
      repIndex: 3,
      meanVelocity: 0.412,
      peakVelocity: 0.63,
      rangeOfMotionM: 0.295,
      sinceSetStart: Duration(milliseconds: 0x01020304),
    );
    final bytes = p.encode();
    expect(bytes.length, GpathProtocol.repPacketLength);
    expect(bytes[0], GpathProtocol.repPacketType);
    expect(bytes[1], 3);
    expect(bytes.sublist(2, 4), [0x9C, 0x01]); // 412 mm/s
    expect(bytes.sublist(8, 12), [0x04, 0x03, 0x02, 0x01]);

    final back = RepPacket.decode(bytes)!;
    expect(back.repIndex, 3);
    expect(back.meanVelocity, closeTo(0.412, 1e-9));
    expect(back.peakVelocity, closeTo(0.63, 1e-9));
    expect(back.rangeOfMotionM, closeTo(0.295, 1e-9));
    expect(back.sinceSetStart.inMilliseconds, 0x01020304);
  });

  test('decode matches the byte layout the firmware writes', () {
    // Hand-built packet: rep 1, 377 mm/s mean, 588 peak, 296 mm rom, 1234 ms.
    final bytes = [
      0x01,
      1,
      0x79,
      0x01,
      0x4C,
      0x02,
      0x28,
      0x01,
      0xD2,
      0x04,
      0,
      0
    ];
    final p = RepPacket.decode(bytes)!;
    expect(p.repIndex, 1);
    expect(p.meanVelocity, closeTo(0.377, 1e-9));
    expect(p.peakVelocity, closeTo(0.588, 1e-9));
    expect(p.rangeOfMotionM, closeTo(0.296, 1e-9));
    expect(p.sinceSetStart.inMilliseconds, 1234);
  });

  test('decode rejects short or foreign packets', () {
    expect(RepPacket.decode(const []), isNull);
    expect(RepPacket.decode(List.filled(11, 0)), isNull);
    expect(RepPacket.decode([0x02, ...List.filled(11, 0)]), isNull);
  });

  test('start command carries target, load x10 and concentric flag', () {
    final b = ControlPacket.startSet(
      targetReps: 8,
      weightKg: 62.5,
      concentricFirst: true,
    );
    expect(b, [GpathProtocol.cmdStartSet, 8, 0x71, 0x02, 1]); // 625 = 0x0271
    expect(ControlPacket.stopSet(), [GpathProtocol.cmdStopSet]);
    expect(ControlPacket.tare(), [GpathProtocol.cmdTare]);
  });
}
