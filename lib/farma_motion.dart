import 'package:material_ui/material_ui.dart';

import 'farma_accessibility.dart';

class FarmaEntrance extends StatelessWidget {
  const FarmaEntrance({
    required this.screen,
    required this.child,
    super.key,
  });

  final Object screen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context) ||
        FarmaAccessibility.isEnabled(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(screen),
      tween: Tween(begin: reducedMotion ? 1.0 : 0.0, end: 1.0),
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: 0.7 + 0.3 * progress,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - progress)),
          child: child,
        ),
      ),
    );
  }
}
