import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knoteapp/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders a reorderable list with a drag handle per note',
      (tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    for (final t in ['One', 'Two', 'Three']) {
      await tester.enterText(find.byType(TextField), t);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    }

    expect(find.byType(ReorderableListView), findsOneWidget);
    // One drag handle (grip) per note.
    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));
    for (final t in ['One', 'Two', 'Three']) {
      expect(find.text(t), findsOneWidget);
    }
  });
}
