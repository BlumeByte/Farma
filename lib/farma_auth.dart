import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_languages.dart';
import 'calling_countries.dart';

const _projectUrl = 'https://zwapaxgaedopenvricww.supabase.co';
const _publishableKey = 'sb_publishable_IveeSm-8OzsC1bu77SD5dA_jUKYLQIB';

class FarmaAuthScreen extends StatefulWidget {
  const FarmaAuthScreen({
    required this.onBack,
    required this.onAuthenticated,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onAuthenticated;

  @override
  State<FarmaAuthScreen> createState() => _FarmaAuthScreenState();
}

class _FarmaAuthScreenState extends State<FarmaAuthScreen> {
  static final _usernamePattern = RegExp(r'^[a-z0-9_]{3,24}$');
  static final _phonePattern = RegExp(r'^\+[1-9][0-9]{6,14}$');
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late final _preferences = SharedPreferencesAsync();

  late String _language;
  late CallingCountry _country;
  final _countryText = TextEditingController();
  bool _registration = false;
  bool _pending = false;
  bool _obscured = true;
  bool _languageChanged = false;
  AuthText? _error;

  @override
  void initState() {
    super.initState();
    final locale = PlatformDispatcher.instance.locale;
    _language = authLanguages.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    _country = callingCountries.firstWhere(
      (item) => item.iso == locale.countryCode,
      orElse: () => callingCountries.firstWhere((item) => item.iso == 'GH'),
    );
    _countryText.text = _country.label;
    unawaited(_restoreLanguage());
  }

  Future<void> _restoreLanguage() async {
    try {
      final saved = await _preferences.getString('farma.auth.language');
      if (mounted && !_languageChanged && authLanguages.containsKey(saved)) {
        setState(() => _language = saved!);
      }
    } catch (_) {
      // The device locale remains available when preferences cannot be read.
    }
  }

  Future<void> _selectLanguage(String code) async {
    _languageChanged = true;
    setState(() => _language = code);
    try {
      await _preferences.setString('farma.auth.language', code);
    } catch (_) {
      // Language selection still applies for this visit.
    }
  }

  String _t(AuthText text) => authLanguages[_language]!.strings[text.index];
  String get _normalizedUsername => _username.text.trim().toLowerCase();

  String get _internationalPhone {
    final number = _phone.text.replaceAll(RegExp(r'[\s().-]'), '');
    return _country.internationalize(number);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _username,
      _email,
      _phone,
      _password,
      _countryText,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleRegistration() {
    _form.currentState?.reset();
    _password.clear();
    setState(() {
      _registration = !_registration;
      _obscured = true;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_pending || !_form.currentState!.validate()) return;
    if (_registration && _countryText.text != _country.label) {
      setState(() => _error = AuthText.country);
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final endpoint = _registration ? 'signup' : 'token?grant_type=password';
      final response = await http
          .post(
            Uri.parse('$_projectUrl/auth/v1/$endpoint'),
            headers: {
              'apikey': _publishableKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': _email.text.trim(),
              'password': _password.text,
              if (_registration)
                'data': {
                  'farma_registration': '1',
                  'username': _normalizedUsername,
                  'full_name': _name.text.trim(),
                  'country_code': _country.iso,
                  'phone_e164': _internationalPhone,
                },
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(
          () => _error = switch (response.statusCode) {
            429 => AuthText.rateLimit,
            _ when _registration => AuthText.registrationError,
            400 || 401 || 403 => AuthText.credentialsError,
            _ => AuthText.networkError,
          },
        );
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final user = payload['user'] as Map<String, dynamic>?;
      final id = user?['id'];
      if (id is String && id.isNotEmpty && payload['access_token'] is String) {
        widget.onAuthenticated(id);
        return;
      }
      if (!_registration) throw const FormatException('Invalid session');
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  _t(AuthText.checkEmail),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(_t(AuthText.confirmEmail), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_t(AuthText.signIn)),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) _toggleRegistration();
    } catch (_) {
      if (mounted) setState(() => _error = AuthText.networkError);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  InputDecoration _decoration(
    BuildContext context, {
    String? hint,
    Widget? suffix,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    );
  }

  Widget _label(AuthText text, Widget input) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
          child: Text(_t(text)),
        ),
        input,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = _language == 'ar' || _language == 'ur';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const BackButtonIcon(),
            onPressed: _pending ? null : widget.onBack,
          ),
          title: const Text('Farma'),
          actions: [
            PopupMenuButton<String>(
              tooltip: _t(AuthText.language),
              icon: const Icon(Icons.language),
              initialValue: _language,
              onSelected: _selectLanguage,
              itemBuilder: (_) => [
                for (final language in authLanguages.entries)
                  PopupMenuItem(
                    value: language.key,
                    child: Text(language.value.name),
                  ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _t(
                            _registration
                                ? AuthText.createAccount
                                : AuthText.welcome,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _t(
                            _registration
                                ? AuthText.registerHint
                                : AuthText.signInHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        if (_registration) ...[
                          _label(
                            AuthText.fullName,
                            TextFormField(
                              controller: _name,
                              enabled: !_pending,
                              maxLength: 120,
                              autofillHints: const [AutofillHints.name],
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoration(context)
                                  .copyWith(counterText: ''),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? _t(AuthText.requiredField)
                                  : null,
                            ),
                          ),
                          _label(
                            AuthText.username,
                            TextFormField(
                              controller: _username,
                              enabled: !_pending,
                              maxLength: 24,
                              textDirection: TextDirection.ltr,
                              autocorrect: false,
                              decoration: _decoration(
                                context,
                                hint: 'farma_user',
                              ).copyWith(counterText: ''),
                              validator: (_) =>
                                  _usernamePattern.hasMatch(_normalizedUsername)
                                  ? null
                                  : _t(AuthText.usernameRule),
                            ),
                          ),
                        ],
                        _label(
                          AuthText.email,
                          TextFormField(
                            controller: _email,
                            enabled: !_pending,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: _decoration(context),
                            validator: (value) =>
                                (value ?? '').trim().contains('@')
                                ? null
                                : _t(AuthText.invalidEmail),
                          ),
                        ),
                        if (_registration) ...[
                          _label(
                            AuthText.country,
                            LayoutBuilder(
                              builder: (context, constraints) =>
                                  DropdownMenu<CallingCountry>(
                                    width: constraints.maxWidth,
                                    menuHeight: 300,
                                    enabled: !_pending,
                                    enableFilter: true,
                                    controller: _countryText,
                                    requestFocusOnTap: true,
                                    initialSelection: _country,
                                    onSelected: (item) {
                                      if (item != null) {
                                        setState(() => _country = item);
                                      }
                                    },
                                    dropdownMenuEntries: [
                                      for (final item in callingCountries)
                                        DropdownMenuEntry(
                                          value: item,
                                          label: item.label,
                                        ),
                                    ],
                                  ),
                            ),
                          ),
                          _label(
                            AuthText.phone,
                            TextFormField(
                              controller: _phone,
                              enabled: !_pending,
                              textDirection: TextDirection.ltr,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumberNational,
                              ],
                              decoration: _decoration(
                                context,
                                hint: _country.dial,
                              ),
                              validator: (_) =>
                                  _phonePattern.hasMatch(_internationalPhone) &&
                                      _internationalPhone.startsWith(
                                        _country.dial,
                                      )
                                  ? null
                                  : _t(AuthText.invalidPhone),
                            ),
                          ),
                        ],
                        _label(
                          AuthText.password,
                          TextFormField(
                            controller: _password,
                            enabled: !_pending,
                            obscureText: _obscured,
                            autofillHints: [
                              _registration
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: _decoration(
                              context,
                              suffix: IconButton(
                                tooltip: _t(AuthText.passwordVisibility),
                                icon: Icon(
                                  _obscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscured = !_obscured),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) =>
                                (value ?? '').length < (_registration ? 8 : 1)
                                ? _t(
                                    _registration
                                        ? AuthText.passwordRule
                                        : AuthText.requiredField,
                                  )
                                : null,
                          ),
                        ),
                        if (_error case final message?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(_t(message)),
                            ),
                          ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            foregroundColor: theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: _pending ? null : _submit,
                          child: Text(
                            _t(
                              _pending
                                  ? AuthText.working
                                  : _registration
                                  ? AuthText.signUp
                                  : AuthText.signIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _pending ? null : _toggleRegistration,
                          child: Text(
                            _t(
                              _registration
                                  ? AuthText.haveAccount
                                  : AuthText.noAccount,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
