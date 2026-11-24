import 'package:material_ui/material_ui.dart';

import 'farma_app.dart';
import 'farma_auth.dart';

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

    if (page == _PublicPage.signIn) {
      return FarmaAuthScreen(
        onBack: () => open(_PublicPage.home),
        onAuthenticated: (id) => setState(() => accountId = id),
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
              child: Column(
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
