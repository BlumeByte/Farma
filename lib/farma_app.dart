import 'dart:convert';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'farma_accessibility.dart';
import 'farma_portal.dart';

enum Workspace {
  overview('Overview', Icons.grid_view_rounded),
  observations('Observations', Icons.camera_alt_outlined),
  produce('Produce', Icons.storefront_outlined);

  const Workspace(this.label, this.icon);
  final String label;
  final IconData icon;
}

class FarmaApp extends StatefulWidget {
  const FarmaApp({super.key});

  @override
  State<FarmaApp> createState() => _FarmaAppState();
}

class _FarmaAppState extends State<FarmaApp> {
  static const _accessibilityKey = 'farma.accessibility.enabled';
  bool _accessibilityEnabled = false;
  bool _accessibilityChanged = false;
  Future<void> _preferenceWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _restoreAccessibility();
  }

  Future<void> _restoreAccessibility() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final enabled = preferences.getBool(_accessibilityKey) ?? false;
      if (mounted && !_accessibilityChanged) {
        setState(() => _accessibilityEnabled = enabled);
      }
    } catch (_) {
      // The control remains usable if preferences cannot be read.
    }
  }

  void _setAccessibility(bool enabled) {
    _accessibilityChanged = true;
    setState(() => _accessibilityEnabled = enabled);
    _preferenceWrite = _preferenceWrite.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_accessibilityKey, enabled);
      } catch (_) {
        // Keep the active setting usable if device storage is unavailable.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farma',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      builder: (context, child) => FarmaAccessibility(
        enabled: _accessibilityEnabled,
        onChanged: _setAccessibility,
        child: child!,
      ),
      home: const FarmaPortal(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      contrastLevel: _accessibilityEnabled ? 1 : 0,
      seedColor: Colors.black,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    return ThemeData(
      colorScheme: scheme,
      focusColor: _accessibilityEnabled ? scheme.primaryContainer : null,
      textTheme: _accessibilityEnabled
          ? const TextTheme(
              bodyMedium: TextStyle(fontSize: 17),
              bodyLarge: TextStyle(fontSize: 19),
            )
          : null,
      scaffoldBackgroundColor: dark
          ? const Color(0xff101010)
          : const Color(0xfff6f6f6),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xff202020) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class FarmaHome extends StatefulWidget {
  const FarmaHome({
    required this.accountId,
    required this.onSignOut,
    required this.onChangeMode,
    super.key,
  });

  final String accountId;
  final VoidCallback onSignOut;
  final VoidCallback onChangeMode;

  @override
  State<FarmaHome> createState() => _FarmaHomeState();
}

class _FarmaHomeState extends State<FarmaHome> {
  final storage = SharedPreferencesAsync();
  String get storageKey => 'farma.entries.v1.${widget.accountId}';
  Workspace workspace = Workspace.overview;
  List<FieldEntry> entries = [];
  bool loading = true;
  bool saving = false;
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await storage.getString(storageKey);
      final decoded = saved == null ? <dynamic>[] : jsonDecode(saved) as List;
      final restored = decoded
          .map((entry) => FieldEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        entries = restored;
        loading = false;
        loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadFailed = true;
      });
    }
  }

  Future<void> _save(Workspace kind, {FieldEntry? existing}) async {
    if (saving) return;
    final entry = await showDialog<FieldEntry>(
      context: context,
      builder: (_) => EntryEditor(kind: kind, existing: existing),
    );
    if (entry == null || !mounted) return;
    setState(() => saving = true);
    final updated = existing == null
        ? [entry, ...entries]
        : [
            for (final item in entries)
              identical(item, existing) ? entry : item,
          ];
    try {
      await storage.setString(
        storageKey,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
      if (!mounted) return;
      setState(() => entries = updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved on this device')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Check available device storage.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Farma',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.9),
        ),
        actions: [
          const AccessibilityModeButton(),
          IconButton(
            onPressed: widget.onChangeMode,
            tooltip: 'Change mode',
            icon: const Icon(Icons.swap_horiz),
          ),
          TextButton(
            onPressed: widget.onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : Semantics(
              container: true,
              role: SemanticsRole.navigation,
              label: 'Workspace navigation',
              child: NavigationBar(
                selectedIndex: workspace.index,
                onDestinationSelected: _navigate,
                destinations: [
                  for (final item in Workspace.values)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Semantics(
                container: true,
                role: SemanticsRole.navigation,
                label: 'Workspace navigation',
                child: NavigationRail(
                  extended: true,
                  selectedIndex: workspace.index,
                  onDestinationSelected: _navigate,
                  destinations: [
                    for (final item in Workspace.values)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Semantics(
                container: true,
                role: SemanticsRole.main,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: AnimatedSwitcher(
                      duration:
                          FarmaAccessibility.isEnabled(context) ||
                              MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: ListView(
                        key: ValueKey(workspace),
                        padding: EdgeInsets.all(wide ? 32 : 18),
                        children: _content(context, wide),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(int index) =>
      setState(() => workspace = Workspace.values[index]);

  List<Widget> _content(BuildContext context, bool wide) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.displaySmall
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5);
    if (loading) {
      return [
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading records'),
        ),
      ];
    }
    if (loadFailed) {
      return [
        const Text('Farma could not open local records.'),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ),
      ];
    }

    if (workspace == Workspace.overview) {
      return [
        Card(
          color: scheme.onSurface,
          child: Padding(
            padding: EdgeInsets.all(wide ? 40 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, color: scheme.surface, size: 32),
                const SizedBox(height: 22),
                FarmaHeading(
                  'Your farm workspace',
                  announce: true,
                  style: titleStyle?.copyWith(color: scheme.surface),
                ),
                const SizedBox(height: 10),
                Text(
                  'Record field observations and prepare produce listings on this device.',
                  style: TextStyle(color: scheme.surface, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const AccessibilityGuide(
          'Open Observations for field records or Produce for your listing drafts. Open a saved record to hear its photo description.',
        ),
        const SizedBox(height: 18),
        for (final item in Workspace.values.skip(1))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                leading: Icon(item.icon),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${entries.where((entry) => entry.kind == item).length} saved on this device',
                ),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => _navigate(item.index),
              ),
            ),
          ),
      ];
    }

    final visible = entries.where((entry) => entry.kind == workspace).toList();
    final produce = workspace == Workspace.produce;
    return [
      FarmaHeading(
        produce ? 'Produce drafts' : 'Field observations',
        announce: true,
        style: titleStyle,
      ),
      const SizedBox(height: 8),
      Text(
        produce
            ? 'Prepare listings for produce you plan to sell.'
            : 'Keep photo and written records from the field.',
      ),
      const SizedBox(height: 18),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: saving ? null : () => _save(workspace),
          icon: const Icon(Icons.add),
          label: Text(produce ? 'New produce draft' : 'New observation'),
        ),
      ),
      const SizedBox(height: 20),
      if (visible.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              produce ? 'No produce drafts yet.' : 'No observations yet.',
            ),
          ),
        ),
      for (final entry in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: entry.photo == null
                  ? Icon(workspace.icon)
                  : _thumbnail(entry.photo!),
              title: Text(entry.title),
              subtitle: Text(
                '${entry.category} · ${MaterialLocalizations.of(context).formatShortDate(entry.date.toLocal())}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final edit = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(entry.title),
                    scrollable: true,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.photo != null)
                          Image.memory(
                            entry.photo!,
                            fit: BoxFit.contain,
                            semanticLabel:
                                entry.photoDescription ??
                                'Photo attached to ${entry.title}. No description available.',
                          ),
                        Text(entry.category),
                        if (entry.notes.isNotEmpty) Text(entry.notes),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                );
                if (edit == true && mounted) {
                  await _save(entry.kind, existing: entry);
                }
              },
            ),
          ),
        ),
    ];
  }
}

Widget _thumbnail(Uint8List photo) => ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Image.memory(
    photo,
    width: 52,
    height: 52,
    fit: BoxFit.cover,
    excludeFromSemantics: true,
  ),
);

class FieldEntry {
  const FieldEntry({
    required this.kind,
    required this.title,
    required this.category,
    required this.notes,
    required this.date,
    this.photo,
    this.photoDescription,
  });

  factory FieldEntry.fromJson(Map<String, dynamic> json) {
    final encoded = json['photo'] as String?;
    return FieldEntry(
      kind: Workspace.values.byName(json['kind'] as String),
      title: json['title'] as String,
      category: json['category'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String),
      photo: encoded == null ? null : base64Decode(encoded),
      photoDescription: json['photoDescription'] as String?,
    );
  }

  final Workspace kind;
  final String title;
  final String category;
  final String notes;
  final DateTime date;
  final Uint8List? photo;
  final String? photoDescription;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'category': category,
    'notes': notes,
    'date': date.toIso8601String(),
    'photo': photo == null ? null : base64Encode(photo!),
    if (photo != null && photoDescription != null)
      'photoDescription': photoDescription,
  };
}

class EntryEditor extends StatefulWidget {
  const EntryEditor({super.key, required this.kind, this.existing});
  final FieldEntry? existing;
  final Workspace kind;

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.existing?.title);
  late final notes = TextEditingController(text: widget.existing?.notes);
  late final photoDescription = TextEditingController(
    text: widget.existing?.photoDescription,
  );
  late String category = widget.existing?.category ?? categories.first;
  late Uint8List? photo = widget.existing?.photo;
  String? photoError;
  bool picking = false;

  bool get produce => widget.kind == Workspace.produce;
  List<String> get categories => produce
      ? const ['Fruit', 'Vegetables', 'Grains', 'Other']
      : const ['Crop', 'Livestock', 'Consumer produce'];

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    photoDescription.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      picking = true;
      photoError = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 75,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 1024 * 1024) {
        if (mounted) setState(() => photoError = 'Choose a photo under 1 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      photoDescription.clear();
      setState(() => photo = bytes);
    } catch (_) {
      if (mounted) {
        setState(() => photoError = 'Photo unavailable. Try choosing a file.');
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? (produce ? 'New produce draft' : 'New observation')
            : (produce ? 'Edit produce draft' : 'Edit observation'),
      ),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: title,
                decoration: InputDecoration(
                  labelText: produce ? 'Produce name' : 'Observation title',
                ),
                maxLength: 100,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final item in categories)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
              ),
              if (photo != null) _thumbnail(photo!),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: picking
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    child: Text(
                      photo == null ? 'Choose photo' : 'Replace photo',
                    ),
                  ),
                  if (!kIsWeb &&
                      (platform == TargetPlatform.android ||
                          platform == TargetPlatform.iOS))
                    TextButton(
                      onPressed: picking
                          ? null
                          : () => _pickPhoto(ImageSource.camera),
                      child: const Text('Take photo'),
                    ),
                  if (photo != null)
                    TextButton(
                      onPressed: picking
                          ? null
                          : () {
                              photoDescription.clear();
                              setState(() => photo = null);
                            },
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
              if (photo != null)
                TextFormField(
                  controller: photoDescription,
                  enabled: !picking,
                  decoration: const InputDecoration(
                    labelText: 'Photo description (optional)',
                    helperText: 'Describe what the photo shows for screen reader users.',
                    helperMaxLines: 3,
                  ),
                  maxLines: 3,
                  maxLength: 300,
                ),
              if (photoError case final message?)
                Semantics(liveRegion: true, child: Text(message)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: picking
              ? null
              : () {
                  if (!form.currentState!.validate()) return;
                  final description = photoDescription.text.trim();
                  Navigator.pop(
                    context,
                    FieldEntry(
                      kind: widget.kind,
                      title: title.text.trim(),
                      category: category,
                      notes: notes.text.trim(),
                      date: widget.existing?.date ?? DateTime.now().toUtc(),
                      photo: photo,
                      photoDescription: photo != null && description.isNotEmpty
                          ? description
                          : null,
                    ),
                  );
                },
          child: const Text('Save on device'),
        ),
      ],
    );
  }
}
