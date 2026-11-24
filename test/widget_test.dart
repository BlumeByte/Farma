import 'dart:convert';
import 'dart:typed_data';

import 'package:farma/farma_app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Field records preserve photo bytes and metadata through JSON', () {
    final entry = FieldEntry(
      kind: Workspace.observations,
      title: 'Tomato bed',
      category: 'Crop',
      notes: 'Checked after watering',
      date: DateTime.utc(2026, 11, 24),
      photo: Uint8List.fromList([1, 2, 3]),
    );
    final restored = FieldEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), entry.toJson());
  });

  testWidgets('Produce draft requires a name and returns trimmed input', (
    tester,
  ) async {
    FieldEntry? entry;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                entry = await showDialog<FieldEntry>(
                  context: context,
                  builder: (_) => const EntryEditor(kind: Workspace.produce),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save on device'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '  Tomatoes  ');
    await tester.tap(find.text('Save on device'));
    await tester.pumpAndSettle();
    expect(entry?.title, 'Tomatoes');
    expect(entry?.kind, Workspace.produce);
  });
}
