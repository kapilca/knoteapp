import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knoteapp/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('strike-through button line-throughs a note (no delete)', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    for (final t in ['One', 'Two']) {
      await tester.enterText(find.byType(TextField), t);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    }

    // Strike through the top note ("Two") via the trailing strike button.
    await tester.tap(find.byIcon(Icons.format_strikethrough).first);
    await tester.pumpAndSettle();

    // Both notes still present; the struck one shows a check icon.
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('completed notes remain until explicitly cleared', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Only note');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_strikethrough));
    await tester.pumpAndSettle();

    expect(find.text('Only note'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear completed (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();

    expect(find.text('Only note'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });
}
