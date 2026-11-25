import 'dart:convert';
import 'dart:typed_data';

import 'package:farma/auth_languages.dart';
import 'package:farma/calling_countries.dart';
import 'package:farma/farma_accessibility.dart';
import 'package:farma/farma_app.dart';
import 'package:farma/farma_onboarding.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('First-use onboarding lets a buyer choose and change language', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FarmaOnboarding(accountId: 'test', onSignOut: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Farmer Mode'), findsOneWidget);
    await tester.tap(find.text('Buyer Mode'));
    await tester.pumpAndSettle();
    expect(find.text('Marketplace'), findsOneWidget);
    await tester.tap(find.text('Change mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language · English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hausa'));
    await tester.pumpAndSettle();
    expect(find.text('Yanayin mai saye'), findsOneWidget);
  });

  testWidgets('Accessibility mode is reachable before and during sign-in', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FarmaApp());
    final toggle = find.byTooltip('Accessibility mode');
    final icon = find.descendant(
      of: find.byType(AccessibilityModeButton),
      matching: find.byType(IconButton),
    );
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(icon).isSelected, isTrue);
    expect(
      find.textContaining('Turn on your device’s screen reader'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Illustration of a Ghanaian farmer examining a cocoa pod',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Sign in'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(icon).isSelected, isTrue);
    final heading = tester.widget<FarmaHeading>(find.byType(FarmaHeading));
    expect(heading.text, 'Welcome back');
    expect(
      FarmaAccessibility.isEnabled(tester.element(find.byType(FarmaHeading))),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const FarmaApp());
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(icon).isSelected, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(icon).isSelected, isFalse);
    expect(tester.takeException(), isNull);
  });

  test('Auth translations and international calling codes are complete', () {
    for (final language in authLanguages.values) {
      expect(language.strings, hasLength(AuthText.values.length));
      expect(language.strings, everyElement(isNotEmpty));
    }
    expect(
      callingCountries.map((country) => country.iso).toSet(),
      hasLength(callingCountries.length),
    );
    expect(
      callingCountries.firstWhere((country) => country.iso == 'GH').dial,
      '+233',
    );
    expect(
      callingCountries
          .firstWhere((country) => country.iso == 'GH')
          .internationalize('0241234567'),
      '+233241234567',
    );
    expect(
      callingCountries.firstWhere((country) => country.iso == 'JP').dial,
      '+81',
    );
  });

  testWidgets('Phone-width signup localizes and shows international fields', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FarmaApp());
    await tester.tap(find.byTooltip('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Te damos la bienvenida de nuevo'), findsOneWidget);

    await tester.tap(find.text('¿Eres nuevo en Farma? Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsOneWidget);
    final callingCountry = tester.widget<DropdownMenu<CallingCountry>>(
      find.byType(DropdownMenu<CallingCountry>),
    );
    expect((callingCountry.label! as Text).data, 'País o territorio');
    expect(find.text('Número de teléfono'), findsOneWidget);
    expect(find.byType(FarmaHome), findsNothing);
  });

  testWidgets('Public pages precede the signed-in workspace', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FarmaApp());
    expect(
      find.text('Keep track of what happens in the field.'),
      findsOneWidget,
    );
    expect(find.byType(FarmaHome), findsNothing);

    for (final page in ['About us', 'Profile', 'Projects', 'Services']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.widgetWithText(TextButton, page),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(page)),
        findsOneWidget,
      );
      expect(find.text(page).hitTestable(), findsAtLeastNWidgets(2));
      expect(find.byType(FarmaHome), findsNothing);
    }

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(FarmaHome), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.text('Keep track of what happens in the field.'),
      findsOneWidget,
    );
  });

  test('Field records preserve photo bytes and metadata through JSON', () {
    final entry = FieldEntry(
      kind: Workspace.observations,
      title: 'Tomato bed',
      category: 'Crop',
      notes: 'Checked after watering',
      date: DateTime.utc(2026, 11, 24),
      photo: Uint8List.fromList([1, 2, 3]),
      photoDescription: 'A row of tomato plants with yellow lower leaves',
    );
    final restored = FieldEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), entry.toJson());
    final legacy = entry.toJson()..remove('photoDescription');
    expect(FieldEntry.fromJson(legacy).photoDescription, isNull);
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
