import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import 'farma_accessibility.dart';
import 'farma_motion.dart';

import 'farma_onboarding.dart';
import 'farma_auth.dart';
import 'farma_public_page.dart';

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
      return FarmaEntrance(
        screen: userId,
        child: FarmaOnboarding(
          accountId: userId,
          onSignOut: () => setState(() {
            accountId = null;
            page = _PublicPage.home;
          }),
        ),
      );
    }

    if (page == _PublicPage.signIn) {
      return FarmaEntrance(
        screen: page,
        child: FarmaAuthScreen(
          onBack: () => open(_PublicPage.home),
          onAuthenticated: (id) => setState(() => accountId = id),
        ),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          if (!wide) ...[
            PopupMenuButton<_PublicPage>(
              tooltip: 'Website navigation',
              onSelected: open,
              itemBuilder: (_) => [
                for (final item in _PublicPage.values.take(5))
                  PopupMenuItem(value: item, child: Text(item.label)),
              ],
            ),
            IconButton(
              tooltip: 'Sign in',
              onPressed: () => open(_PublicPage.signIn),
              icon: const Icon(Icons.login),
            ),
          ],
          const AccessibilityModeButton(),
        ],
        titleSpacing: 16,
        title: Semantics(
          container: true,
          role: SemanticsRole.navigation,
          label: 'Website navigation',
          child: Row(
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () => open(_PublicPage.home),
                  child: const Text(
                    'Farma',
                    style: TextStyle(fontSize: 22),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (wide) ...[
                const Spacer(),
                for (final item in _PublicPage.values.take(5))
                  Flexible(
                    flex: 2,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => open(item),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: () => open(_PublicPage.signIn),
                  child: const Text('Sign in'),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Semantics(
        container: true,
        role: SemanticsRole.main,
        child: FarmaEntrance(
          screen: page,
          child: FarmaPublicPage(
            content: farmaPages[page.name]!,
            isHome: page == _PublicPage.home,
            onSignIn: () => open(_PublicPage.signIn),
            onExplore: () => open(_PublicPage.services),
            onNavigate: (name) => open(_PublicPage.values.byName(name)),
          ),
        ),
      ),
    );
  }
}
