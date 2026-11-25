import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_languages.dart';
import 'farma_accessibility.dart';
import 'farma_motion.dart';

import 'farma_app.dart';

enum _Mode { farmer, buyer }

class FarmaOnboarding extends StatefulWidget {
  const FarmaOnboarding({
    required this.accountId,
    required this.onSignOut,
    super.key,
  });

  final String accountId;
  final VoidCallback onSignOut;

  @override
  State<FarmaOnboarding> createState() => _FarmaOnboardingState();
}

class _FarmaOnboardingState extends State<FarmaOnboarding> {
  static const _fieldLanguages = {
    'en': 'English',
    'tw': 'Twi',
    'gaa': 'Ga',
    'ee': 'Ewe',
    'dag': 'Dagbani',
    'ha': 'Hausa',
  };

  late final _preferences = SharedPreferencesAsync();
  String get _key => 'farma.workspace.language.${widget.accountId}';
  String? _language;

  Map<String, String> get _languages => {
    for (final entry in authLanguages.entries) entry.key: entry.value.name,
    ..._fieldLanguages,
    if (_language case final value? when value.startsWith('custom:'))
      value: value.substring(7),
  };

  String get _languageName => _languages[_language] ?? 'English';

  Future<void> _openLanguageSettings() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _LanguageDialog(
        languages: _languages,
        selected: _language,
      ),
    );
    if (selected != null && mounted) await _choose(selected);
  }

  Widget _languageSettingsButton() => kIsWeb
      ? FilledButton.tonalIcon(
          onPressed: _openLanguageSettings,
          icon: const Icon(Icons.language),
          label: const Text('Language'),
        )
      : IconButton(
          tooltip: 'Language settings',
          onPressed: _openLanguageSettings,
          icon: const Icon(Icons.language),
        );
  _Mode? _mode;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? selected;
    try {
      selected = await _preferences.getString(_key);
    } catch (_) {
      // A user can continue with a language for this visit.
    }
    if (!mounted) return;
    setState(() {
      _language = selected != null &&
                (_languages.containsKey(selected) || selected.startsWith('custom:'))
            ? selected
            : null;
      _loading = false;
    });
  }

  Future<void> _choose(String code) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _preferences.setString(_key, code);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language selected for this visit.')),
      );
    }
    if (!mounted) return;
    setState(() {
      _language = code;
      _editing = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(actions: const [AccessibilityModeButton()]),
        body: const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading workspace'),
        ),
      );
    }
    if (_mode == _Mode.farmer) {
      return FarmaEntrance(
        screen: _Mode.farmer,
        child: FarmaHome(
          accountId: widget.accountId,
          languageSettings: _languageSettingsButton(),
          onSignOut: widget.onSignOut,
          onChangeMode: () => setState(() => _mode = null),
        ),
      );
    }

    final choosing = _language == null || _editing;
    final buyer = _mode == _Mode.buyer;
    final hausa = _language == 'ha';
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farma'),
        leading: buyer || _editing
            ? BackButton(
                onPressed: () => setState(() {
                  _mode = null;
                  _editing = false;
                }),
              )
            : null,
        actions: [
          const AccessibilityModeButton(),
          if (!kIsWeb) _languageSettingsButton(),
          TextButton(
            onPressed: widget.onSignOut,
            child: Text(hausa ? 'Fita' : 'Sign out'),
          ),
        ],
      ),
      floatingActionButton: kIsWeb ? _languageSettingsButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: FarmaEntrance(
          screen: (choosing, buyer),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, kIsWeb ? 76 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FarmaHeading(
                      choosing
                          ? 'Choose your language'
                          : buyer
                          ? (hausa ? 'Kasuwa' : 'Marketplace')
                          : (hausa ? 'Zaɓi yanayin aiki' : 'Choose your mode'),
                      style: theme.textTheme.headlineMedium,
                      announce: true,
                    ),
                    AccessibilityGuide(
                      choosing
                          ? 'Select a language to continue to the workspace choices.'
                          : buyer
                          ? 'Use Change mode to return to the workspace choices.'
                          : 'Choose Farmer Mode for field records or Buyer Mode for the marketplace.',
                    ),
                    const SizedBox(height: 12),
                    if (choosing) ...[
                      const Text(
                        'Choose a preference for field guidance. English is available across the workspace.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final language in _languages.entries)
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _choose(language.key),
                              child: Text(language.value),
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: _openLanguageSettings,
                        child: const Text('Choose another language'),
                      ),
                    ] else if (buyer) ...[
                      const Text('Published produce listings will appear here.'),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => setState(() => _mode = null),
                        child: const Text('Change mode'),
                      ),
                    ] else ...[
                      _modeCard(
                        icon: Icons.grass_outlined,
                        title: hausa ? 'Yanayin manomi' : 'Farmer Mode',
                        description: 'Record field observations and prepare produce drafts.',
                        mode: _Mode.farmer,
                      ),
                      const SizedBox(height: 12),
                      _modeCard(
                        icon: Icons.storefront_outlined,
                        title: hausa ? 'Yanayin mai saye' : 'Buyer Mode',
                        description: 'Explore the marketplace.',
                        mode: _Mode.buyer,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.language),
                        label: Text('Language · $_languageName'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String description,
    required _Mode mode,
  }) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(20),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() => _mode = mode),
    ),
  );
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({required this.languages, required this.selected});

  final Map<String, String> languages;
  final String? selected;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _saveCustom() {
    final name = _custom.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, 'custom:$name');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Language settings'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your preferred language. Some screens are currently available in English.',
            ),
            for (final entry in widget.languages.entries)
              ListTile(
                title: Text(entry.value),
                selected: entry.key == widget.selected,
                onTap: () => Navigator.pop(context, entry.key),
              ),
            TextField(
              controller: _custom,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Other language or dialect',
              ),
              onSubmitted: (_) => _saveCustom(),
            ),
            OutlinedButton(
              onPressed: _saveCustom,
              child: const Text('Save other language'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
