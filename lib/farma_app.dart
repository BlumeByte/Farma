import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Workspace {
  overview('Overview', Icons.grid_view_rounded),
  observations('Observations', Icons.camera_alt_outlined),
  produce('Produce', Icons.storefront_outlined);

  const Workspace(this.label, this.icon);
  final String label;
  final IconData icon;
}

class FarmaApp extends StatelessWidget {
  const FarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farma',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const FarmaHome(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    return ThemeData(
      colorScheme: scheme,
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
  const FarmaHome({super.key});

  @override
  State<FarmaHome> createState() => _FarmaHomeState();
}

class _FarmaHomeState extends State<FarmaHome> {
  final storage = SharedPreferencesAsync();
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
      final saved = await storage.getString('farma.entries.v1');
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

  Future<void> _add(Workspace kind) async {
    final entry = await showDialog<FieldEntry>(
      context: context,
      builder: (_) => EntryEditor(kind: kind),
    );
    if (entry == null || !mounted) return;
    setState(() => saving = true);
    final updated = [entry, ...entries];
    try {
      await storage.setString(
        'farma.entries.v1',
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
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: Text('Local workspace')),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
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
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
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
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
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
    if (loading) return [const Center(child: CircularProgressIndicator())];
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
                Text(
                  'Your farm workspace',
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
      Text(
        produce ? 'Produce drafts' : 'Field observations',
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
          onPressed: saving ? null : () => _add(workspace),
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
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(entry.title),
                  scrollable: true,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.photo != null)
                        Image.memory(entry.photo!, fit: BoxFit.contain),
                      Text(entry.category),
                      if (entry.notes.isNotEmpty) Text(entry.notes),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

Widget _thumbnail(Uint8List photo) => ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Image.memory(photo, width: 52, height: 52, fit: BoxFit.cover),
);

class FieldEntry {
  const FieldEntry({
    required this.kind,
    required this.title,
    required this.category,
    required this.notes,
    required this.date,
    this.photo,
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
    );
  }

  final Workspace kind;
  final String title;
  final String category;
  final String notes;
  final DateTime date;
  final Uint8List? photo;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'category': category,
    'notes': notes,
    'date': date.toIso8601String(),
    'photo': photo == null ? null : base64Encode(photo!),
  };
}

class EntryEditor extends StatefulWidget {
  const EntryEditor({super.key, required this.kind});
  final Workspace kind;

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final notes = TextEditingController();
  late String category = categories.first;
  Uint8List? photo;
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
      if (mounted) setState(() => photo = bytes);
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
      title: Text(produce ? 'New produce draft' : 'New observation'),
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
                          : () => setState(() => photo = null),
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
              if (photoError != null) Text(photoError!),
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
                  Navigator.pop(
                    context,
                    FieldEntry(
                      kind: widget.kind,
                      title: title.text.trim(),
                      category: category,
                      notes: notes.text.trim(),
                      date: DateTime.now().toUtc(),
                      photo: photo,
                    ),
                  );
                },
          child: const Text('Save on device'),
        ),
      ],
    );
  }
}
