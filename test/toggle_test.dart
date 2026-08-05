import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knoteapp/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('strike-through button line-throughs a note (no delete)',
      (tester) async {
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

  testWidgets('striking out the last note auto-clears the whole list',
      (tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Only note');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_strikethrough));
    // Advance past the auto-clear delay, then settle the rebuild.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // List cleared itself → back to the empty state.
    expect(find.text('Only note'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });
}
