import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/data/workout_repository.dart';
import 'package:gpath_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tall phone viewport so the whole live sheet is built (the default
/// 800x600 surface leaves the capture controls below the fold).
void _phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<WorkoutRepository> _repo() async {
  SharedPreferences.setMockInitialValues({});
  final repo = WorkoutRepository(prefs: await SharedPreferences.getInstance());
  await repo.load();
  return repo;
}

void main() {
  testWidgets('home tab opens the live workout screen', (tester) async {
    await tester.pumpWidget(GPathApp(repository: await _repo()));
    await tester.pump();
    expect(find.text('Continue workout'), findsOneWidget);

    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    expect(find.text('Total Volume'), findsOneWidget);
    expect(find.text('Mean V'), findsOneWidget);
    expect(find.text('Set 3'), findsWidgets);
  });

  testWidgets('history tab shows both charts', (tester) async {
    await tester.pumpWidget(GPathApp(repository: await _repo()));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.show_chart));
    await tester.pumpAndSettle();

    expect(find.text('GPE Per Training'), findsOneWidget);
    expect(find.text('Total Power Per Training'), findsOneWidget);
  });

  testWidgets('finishing a workout saves a session to history', (tester) async {
    _phoneView(tester);
    final repo = await _repo();
    final before = repo.sessions.length;
    await tester.pumpWidget(GPathApp(repository: repo));
    await tester.pump();

    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    // Log the live set manually, then finish via the menu.
    await tester.tap(find.byTooltip('Log rep'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check).last);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(repo.sessions.length, before + 1);
    expect(find.textContaining('Saved: 3 sets'), findsOneWidget);
    expect(find.text('Continue workout'), findsOneWidget);
  });

  testWidgets('the tune button opens the set editor and saves changes',
      (tester) async {
    _phoneView(tester);
    await tester.pumpWidget(GPathApp(repository: await _repo()));
    await tester.pump();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit current set'));
    await tester.pumpAndSettle();
    expect(find.text('Edit set 3'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Weight'), '65');
    await tester.enterText(find.widgetWithText(TextField, 'Target reps'), '6');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('65'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });
}
