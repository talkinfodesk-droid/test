import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpath_tracker/main.dart';

void main() {
  testWidgets('home tab opens the live workout screen', (tester) async {
    await tester.pumpWidget(const GPathApp());
    expect(find.text('Continue workout'), findsOneWidget);

    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    expect(find.text('Total Volume'), findsOneWidget);
    expect(find.text('Mean V'), findsOneWidget);
    expect(find.text('Set 3'), findsWidgets);
  });

  testWidgets('history tab shows both charts', (tester) async {
    await tester.pumpWidget(const GPathApp());
    await tester.tap(find.byIcon(Icons.show_chart));
    await tester.pumpAndSettle();

    expect(find.text('GPE Per Training'), findsOneWidget);
    expect(find.text('Total Power Per Training'), findsOneWidget);
  });
}
