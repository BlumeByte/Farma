import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'farma_accessibility.dart';

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
      _language = _fieldLanguages.containsKey(selected) ? selected : null;
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
      return FarmaHome(
        accountId: widget.accountId,
        onSignOut: widget.onSignOut,
        onChangeMode: () => setState(() => _mode = null),
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
          TextButton(
            onPressed: widget.onSignOut,
            child: Text(hausa ? 'Fita' : 'Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                        for (final language in _fieldLanguages.entries)
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _choose(language.key),
                            child: Text(language.value),
                          ),
                      ],
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
                      label: Text('Language · ${_fieldLanguages[_language]}'),
                    ),
                  ],
                ],
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
