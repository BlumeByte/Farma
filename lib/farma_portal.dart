import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'farma_app.dart';

const _projectUrl = 'https://zwapaxgaedopenvricww.supabase.co';
const _publishableKey = 'sb_publishable_IveeSm-8OzsC1bu77SD5dA_jUKYLQIB';

enum _PublicPage {
  home('Home'),
  about('About us'),
  profile('Profile'),
  projects('Projects'),
  services('Services'),
  signIn('Sign in');

  const _PublicPage(this.label);
  final String label;
}

class FarmaPortal extends StatefulWidget {
  const FarmaPortal({super.key});

  @override
  State<FarmaPortal> createState() => _FarmaPortalState();
}

class _FarmaPortalState extends State<FarmaPortal> {
  _PublicPage page = _PublicPage.home;
  String? accountId;

  void open(_PublicPage next) => setState(() => page = next);

  @override
  Widget build(BuildContext context) {
    final userId = accountId;
    if (userId != null) {
      return FarmaHome(
        accountId: userId,
        onSignOut: () => setState(() {
          accountId = null;
          page = _PublicPage.home;
        }),
      );
    }

    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            TextButton(
              onPressed: () => open(_PublicPage.home),
              child: const Text('Farma', style: TextStyle(fontSize: 22)),
            ),
            const Spacer(),
            if (wide)
              for (final item in _PublicPage.values.take(5))
                TextButton(onPressed: () => open(item), child: Text(item.label))
            else
              PopupMenuButton<_PublicPage>(
                tooltip: 'Website navigation',
                onSelected: open,
                itemBuilder: (_) => [
                  for (final item in _PublicPage.values.take(5))
                    PopupMenuItem(value: item, child: Text(item.label)),
                ],
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => open(_PublicPage.signIn),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          key: ValueKey(page),
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 48 : 24,
            vertical: 64,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: page == _PublicPage.signIn
                  ? _SignIn(
                      onAuthenticated: (id) => setState(() => accountId = id),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          page == _PublicPage.home
                              ? 'Keep track of what happens in the field.'
                              : page.label,
                          style:
                              (wide
                                      ? theme.textTheme.displayLarge
                                      : theme.textTheme.displaySmall)
                                  ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 20),
                        Text(_intro[page]!, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 28),
                        if (page == _PublicPage.home)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton(
                                onPressed: () => open(_PublicPage.signIn),
                                child: const Text('Sign in to your workspace'),
                              ),
                              OutlinedButton(
                                onPressed: () => open(_PublicPage.services),
                                child: const Text('Explore services'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 40),
                        for (final section in _sections[page]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(24),
                                title: Text(
                                  section.$1,
                                  style: theme.textTheme.titleLarge,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(section.$2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

const _intro = {
  _PublicPage.home: 'Farma gives farmers a place to capture field observations and prepare produce listings.',
  _PublicPage.about: 'Farma helps farmers document what they see and keep a usable record of their work.',
  _PublicPage.profile: 'Farma is an agricultural software project by BlumeByte for mobile and web.',
  _PublicPage.projects:
      'Explore the work behind the Farma field and produce tools.',
  _PublicPage.services:
      'Use your Farma workspace to capture, organize and revisit your records.',
};

const _sections = {
  _PublicPage.home: [
    (
      'Field observations',
      'Capture photos and notes when you spot a change in the field.',
    ),
    (
      'Produce drafts',
      'Prepare a produce record with a name, photo and notes.',
    ),
  ],
  _PublicPage.about: [
    (
      'Built for fieldwork',
      'Organize observations and produce records in one workspace on your phone or computer.',
    ),
  ],
  _PublicPage.profile: [
    (
      'Who Farma serves',
      'Farmers and field teams who need a clear history of their observations and produce.',
    ),
  ],
  _PublicPage.projects: [
    (
      'Field workspace',
      'Keep a history of observations and photos for review.',
    ),
    (
      'Produce showcase',
      'Create and organize listing drafts before publication.',
    ),
  ],
  _PublicPage.services: [
    (
      'Observation history',
      'Record a category, photo and notes, then revisit observations on the same device.',
    ),
    (
      'Produce preparation',
      'Save drafts on this device while preparing produce details.',
    ),
  ],
};

class _SignIn extends StatefulWidget {
  const _SignIn({required this.onAuthenticated});

  final ValueChanged<String> onAuthenticated;

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pending || !_form.currentState!.validate()) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_projectUrl/auth/v1/token?grant_type=password'),
            headers: {
              'apikey': _publishableKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': _email.text.trim(),
              'password': _password.text,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _error = switch (response.statusCode) {
            400 || 401 || 403 =>
              'Check your email and password and confirm your email address.',
            429 => 'Too many attempts. Wait a moment and try again.',
            _ => 'Sign-in is temporarily unavailable. Please try again.',
          };
        });
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final user = payload['user'] as Map<String, dynamic>?;
      final id = user?['id'];
      if (id is! String || id.isEmpty || payload['access_token'] is! String) {
        throw const FormatException('Invalid session response');
      }
      widget.onAuthenticated(id);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not sign in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in to Farma',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  enabled: !_pending,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value ?? '').trim().contains('@')
                      ? null
                      : 'Enter your email address.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_pending,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Enter your password.' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(liveRegion: true, child: Text(message)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _pending ? null : _submit,
                  child: Text(_pending ? 'Signing in…' : 'Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
