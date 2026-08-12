import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knoteapp/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the empty state, then adds a note from the composer', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
  });

  testWidgets('tapping a note opens the editor', (tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Read a book');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Open the editor.
    await tester.tap(find.text('Read a book'));
    await tester.pumpAndSettle();

    // The editor shows the note text in its own TextField.
    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    final edited = tester.widget<TextField>(fields.last);
    expect(edited.controller!.text, 'Read a book');
  });
}
