// Renders each main screen to a PNG so the layout can be eyeballed without a
// device. Run with: flutter test test/screenshot_test.dart
// Skipped by default; run with:
//   flutter test --run-skipped test/screenshot_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/data/mock_data.dart';
import 'package:gpath_tracker/screens/history_screen.dart';
import 'package:gpath_tracker/screens/live_workout_screen.dart';
import 'package:gpath_tracker/screens/root_shell.dart';
import 'package:gpath_tracker/theme/app_theme.dart';

/// Roboto + Material Icons ship with the Flutter SDK; FLUTTER_ROOT is set by
/// `flutter test`.
final _fontDir =
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  for (final entry in {
    'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
    'MaterialIcons': ['MaterialIcons-Regular.otf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final f in entry.value) {
      final file = File('$_fontDir/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}

Future<void> _snap(WidgetTester tester, Widget home, String name) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
          theme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('docs/screenshots/$name.png')
      .writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  setUpAll(_loadFonts);

  // Skipped: writes PNGs. Run with `flutter test --run-skipped`.
  testWidgets('capture screens', skip: true, (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await _snap(tester, const RootShell(), 'home');
      await _snap(tester, const HistoryScreen(), 'history');
      final ex = MockData.machinePulldown();
      ex.sets[2].repVelocities.addAll([0.39, 0.37, 0.43, 0.41]);
      await _snap(tester, LiveWorkoutScreen(exercise: ex), 'live_workout');
    });
  });
}
